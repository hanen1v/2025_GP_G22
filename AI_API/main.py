from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pandas as pd
import joblib
import mysql.connector
import os
from contextlib import contextmanager

app = FastAPI()

# موديل التصنيف الخاص بتحليل نص الاستشارة
classification_model = joblib.load("mujeer_svm_model.pkl")

# موديل التوصية الخاص باقتراح المحامي
recommendation_model = joblib.load("recommendation_model_svm.pkl")

# DB_CONFIG = {
#     "host": "localhost",
#     "user": "root",
#     "password": "root",
#     "port": 8889,
#     "database": "mujeer"
# }
# DB_CONFIG = {
#     "host": os.environ.get("MYSQLHOST", "localhost"),
#     "user": os.environ.get("MYSQLUSER", "root"),
#     "password": os.environ.get("MYSQLPASSWORD", "root"),
#     "port": int(os.environ.get("MYSQLPORT", 8889)),
#     "database": os.environ.get("MYSQLDATABASE", "mujeer")
# }
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "user": os.environ.get("DB_USER", "root"),
    "password": os.environ.get("DB_PASS", ""),
    "port": int(os.environ.get("DB_PORT", 3306)),
    "database": os.environ.get("DB_NAME", "mujeer")
}
# ===== Request Models =====
class Consultation(BaseModel):
    text: str

class RecommendationRequest(BaseModel):
    category: str
    preferred_gender: str
    preferred_degree: str
    preferred_major: str
    min_experience: int

class ConsultationRequest(BaseModel):
    text: str
    preferred_gender: str
    preferred_degree: str
    preferred_major: str
    min_experience: int


# ===== DB Context Manager (يضمن إغلاق الاتصال دائماً) =====
@contextmanager
def get_db_connection():
    conn = mysql.connector.connect(**DB_CONFIG)
    try:
        yield conn
    finally:
        conn.close()


# ===== Normalization Helpers =====
def normalize_degree(value: str) -> str:
    value = (value or "").strip().lower()
    mapping = {
        "diploma": "Diploma",
        "bachelor": "Bachelor",
        "bachelors": "Bachelor",
        "master": "Master",
        "masters": "Master",
        "phd": "PhD",
        "doctorate": "PhD",
        "دبلوم": "Diploma",
        "بكالوريوس": "Bachelor",
        "ماجستير": "Master",
        "دكتوراه": "PhD",
    }
    return mapping.get(value, value.title())

def normalize_major(value: str) -> str:
    value = (value or "").strip().lower()
    mapping = {
        "law": "Law",
        "sharia": "Sharia",
        "قانون": "Law",
        "شريعة": "Sharia",
    }
    return mapping.get(value, value.title())

def normalize_gender(value: str) -> str:
    value = (value or "").strip().lower()
    mapping = {
        "male": "Male",
        "female": "Female",
        "ذكر": "Male",
        "أنثى": "Female",
        "any": "Any",
        "لا يهم": "Any",
    }
    return mapping.get(value, value.title())


# ===== Endpoint 1: Predict Case Category =====
@app.post("/predict")
def predict_category(data: Consultation):
    prediction = classification_model.predict([data.text])
    return {"category": str(prediction[0])}


# ===== Endpoint 2: Recommend Lawyers =====
@app.post("/recommend")
def recommend_lawyers(request: RecommendationRequest):
    # --- جلب المحامين من DB بأمان ---
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            query = """
                SELECT
                    l.LawyerID,
                    l.FullName,
                    l.Gender,
                    l.YearsOfExp,
                    l.MainSpecialization,
                    l.FSubSpecialization,
                    l.SSubSpecialization,
                    l.EducationQualification,
                    l.AcademicMajor,
                    l.price,
                    l.LawyerPhoto,
                    COALESCE(AVG(f.Rate), 0) AS Rating
                FROM lawyer l
                LEFT JOIN feedback f ON l.LawyerID = f.LawyerID
                WHERE l.Status = 'Approved'
                GROUP BY
                    l.LawyerID,
                    l.FullName,
                    l.Gender,
                    l.YearsOfExp,
                    l.MainSpecialization,
                    l.FSubSpecialization,
                    l.SSubSpecialization,
                    l.EducationQualification,
                    l.AcademicMajor,
                    l.price,
                    l.LawyerPhoto
            """
            cursor.execute(query)
            lawyers = cursor.fetchall()
            cursor.close()
    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    if not lawyers:
        return {"recommendations": []}

    preferred_gender = normalize_gender(request.preferred_gender)
    preferred_degree = normalize_degree(request.preferred_degree)
    preferred_major = normalize_major(request.preferred_major)
    request_category = request.category.strip().lower() if request.category else ""

    # --- FIX: جمع كل المحامين المناسبين بدون حد (الموديل هو اللي يختار أفضل 5) ---
    main_matches = []
    first_sub_matches = []
    second_sub_matches = []

    for lawyer in lawyers:
        main_spec = (lawyer["MainSpecialization"] or "").strip().lower()
        first_sub_spec = (lawyer["FSubSpecialization"] or "").strip().lower()
        second_sub_spec = (lawyer["SSubSpecialization"] or "").strip().lower()

        if request_category and main_spec == request_category:
            main_matches.append(lawyer)
        elif request_category and first_sub_spec == request_category:
            first_sub_matches.append(lawyer)
        elif request_category and second_sub_spec == request_category:
            second_sub_matches.append(lawyer)

    # دمج القوائم بالأولوية (بدون حد هنا)
    filtered_lawyers = main_matches + first_sub_matches + second_sub_matches

    if not filtered_lawyers:
        return {"recommendations": []}

    # --- بناء DataFrame للموديل ---
    rows_for_model = []
    lawyer_payload = []

    for lawyer in filtered_lawyers:
        lawyer_gender = normalize_gender(lawyer["Gender"])
        lawyer_degree = normalize_degree(lawyer["EducationQualification"])
        lawyer_major = normalize_major(lawyer["AcademicMajor"])
        lawyer_experience = int(lawyer["YearsOfExp"] or 0)
        lawyer_rating = float(lawyer["Rating"] or 0)

        user_gender_for_model = preferred_gender
        lawyer_gender_for_model = lawyer_gender
        if preferred_gender == "Any":
            user_gender_for_model = lawyer_gender

        row = {
            "User_Pref_Major": preferred_major,
            "User_Pref_Degree": preferred_degree,
            "User_Pref_Gender": user_gender_for_model,
            "User_Pref_Min_Experience": int(request.min_experience),
            "Lawyer_Major": lawyer_major,
            "Lawyer_Degree": lawyer_degree,
            "Lawyer_Gender": lawyer_gender_for_model,
            "Lawyer_Experience": lawyer_experience,
            "Lawyer_Rating": lawyer_rating,
            "Experience_Diff": lawyer_experience - int(request.min_experience),
        }

        rows_for_model.append(row)
        lawyer_payload.append(lawyer)

    df = pd.DataFrame(rows_for_model)

    # --- FIX: التعامل مع موديلات ما تدعم predict_proba ---
    try:
        probabilities = recommendation_model.predict_proba(df)[:, 1]
    except AttributeError:
        # fallback: استخدم decision_function أو أعطِ كل محامي نفس الاحتمالية
        try:
            scores_raw = recommendation_model.decision_function(df)
            # normalize بين 0 و 1
            min_s, max_s = scores_raw.min(), scores_raw.max()
            probabilities = (scores_raw - min_s) / (max_s - min_s + 1e-9)
        except AttributeError:
            probabilities = [0.5] * len(lawyer_payload)

    # --- بناء قائمة التوصيات مع الـ final_score ---
    recommendations = []
    for lawyer, score in zip(lawyer_payload, probabilities):
        years_exp = int(lawyer["YearsOfExp"] or 0)
        rating = float(lawyer["Rating"] or 0)

        final_score = (
            (float(score) * 0.7) +
            ((rating / 5) * 0.2) +
            ((years_exp / 40) * 0.1)
        )

        recommendations.append({
            "LawyerID": lawyer["LawyerID"],
            "FullName": lawyer["FullName"],
            "Gender": lawyer["Gender"],
            "YearsOfExp": years_exp,
            "MainSpecialization": lawyer["MainSpecialization"],
            "FSubSpecialization": lawyer["FSubSpecialization"] or "",  
    "SSubSpecialization": lawyer["SSubSpecialization"] or "",
            "EducationQualification": lawyer["EducationQualification"],
            "AcademicMajor": lawyer["AcademicMajor"],
            "price": float(lawyer["price"] or 0),
            "Rating": round(rating, 2),
            "final_score": round(final_score, 4),
            "LawyerPhoto": lawyer["LawyerPhoto"] or "",
        })

    recommendations.sort(key=lambda x: x["final_score"], reverse=True)

    return {"recommendations": recommendations[:5]}


# ===== Endpoint 3: Consult (Predict + Recommend) =====
@app.post("/consult")
def consult(request: ConsultationRequest):
    prediction = classification_model.predict([request.text])
    category = str(prediction[0])

    recommendation_request = RecommendationRequest(
        category=category,
        preferred_gender=request.preferred_gender,
        preferred_degree=request.preferred_degree,
        preferred_major=request.preferred_major,
        min_experience=request.min_experience,
    )
    result = recommend_lawyers(recommendation_request)

    return {
        "detected_category": category,
        "recommendations": result["recommendations"]
    }