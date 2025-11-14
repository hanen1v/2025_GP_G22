# Mujeer
## Introduction
Mujeer is an Arabic Android application for legal consultations in Saudi Arabia.  
The app simplifies access to lawyers licensed by the Saudi Ministry of Justice and features a smart recommendation system to suggest the most suitable lawyer.  
It also provides **AI-powered legal contract drafting** with the option for final review by a licensed attorney.  
Mujeer supports Saudi Arabia’s digital-justice goals by implementing a **manual verification process** for lawyer licenses and displaying an official **“Verified” badge** for every approved lawyer, enhancing user trust and security.

## Technology
- **Programming Languages:** Dart (for the mobile interface) and Python (to develop the recommendation system). 
- **Frameworks:** Flutter for Android application development.
- **Database:** MySQL to manage user, lawyer, and contract data.  
- **Version Control:** GitHub for code management and team collaboration.
- **Project Management:** Jira for sprint planning, backlog tracking, and issue management.  
- **APIs & Services:**
  - **OpenAI GPT-4o API** – Generates customized legal contract drafts using artificial intelligence.  
  - **Agora API** – Enables real-time chat and communication between clients and lawyers.  
  - **Twilio API** – Handles OTP (One-Time Password) verification for secure account login.

## Launching Instructions
Follow the steps below to run the Mujeer application in a local development environment.

### 1. Prerequisites
Before launching the project, make sure the following tools are installed:
- Flutter SDK (version 3.0 or above)
- Android Studio (for Android emulator + SDK tools)
- VS Code or Android Studio for development
- MySQL Server (MAMP/XAMPP/WAMP)
- PHP 8+ (for backend APIs)
- Git
- OneSignal Account (for notifications)
- Firebase Project (for mobile services)

### 2. Backend Setup

#### 2.1 Import the Database
1. Open phpMyAdmin
2. Create a new database (example: mujeer)
3. Import the SQL file in the database/ folder of the project.

#### 2.2 Configure API files
1. Move the folder mujeer_api/ to your local server path:
C:/MAMP/htdocs/mujeer_api/

2. Open config.php and set:
$servername = "localhost";
$username = "root";
$password = "root";   // Or your password
$dbname = "mujeer";

#### 2.3 Check the upload directory
Inside mujeer_api, ensure this folder exists:
uploads/
If not, create it manually.

### 3. Flutter Setup

#### 3.1 Install Dependencies
Inside your Flutter project folder run:
flutter pub get

#### 3.2 Connect to Backend
If using Android Emulator, the backend base URL should be:
static const String base = "http://10.0.2.2:8888/mujeer_api";

For a real Android device:
Replace with your laptop IP:
static const String base = "http://YOUR_LOCAL_IP:8888/mujeer_api";

### 4. Firebase Setup
The project uses Firebase for:
-OTP (optional depending on your build)
-Notifications
-Authentication services

Make sure:
android/app/google-services.json
is added.

Build again after adding:
flutter clean
flutter pub get

### 5. OneSignal Setup
Add your OneSignal app ID in:
OneSignal.initialize("YOUR-ONESIGNAL-ID");

Enable push permission:
OneSignal.Notifications.requestPermission(true);

### 6. Running the App
To launch the app on Android:
flutter run

Or specify a device:
flutter run -d emulator-5554

### 7. Admin Workflow
- Once the backend is running, the admin can sign in through the internal admin panel.
- The admin is responsible for:
- Reviewing lawyer registration requests.
- Verifying uploaded license files.
- Approving or rejecting lawyers in order to activate their accounts.

### Done!
Your Mujeer application is now fully set up and ready for testing and development.
   
