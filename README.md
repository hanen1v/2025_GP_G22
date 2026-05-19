# Mujeer — مُجير
 
## Introduction
Mujeer is an Arabic Android application for legal consultations in Saudi Arabia.  
The app simplifies access to lawyers licensed by the Saudi Ministry of Justice and features a smart recommendation system to suggest the most suitable lawyer.  
It also provides **AI-powered legal contract drafting** with the option for final review by a licensed attorney.  
Mujeer supports Saudi Arabia's digital-justice goals by implementing a **manual verification process** for lawyer licenses and displaying an official **"Verified" badge** for every approved lawyer, enhancing user trust and security.
 
---
 
## Technology
- **Programming Languages:** Dart (mobile interface), PHP (backend APIs), Python (AI recommendation system)
- **Frameworks:** Flutter for Android application development
- **Database:** MySQL — hosted on **Railway**
- **File & Image Storage:** **Cloudinary** 
- **Version Control:** GitHub for code management and team collaboration
- **Project Management:** Jira for sprint planning, backlog tracking, and issue management
### APIs & Services
 
| Service | Purpose |
|---------|---------|
| **OpenAI GPT-4o API** | Generates customized legal contract drafts using AI |
| **Agora API** | Enables voice calling between clients and lawyers |
| **Firebase Authentication Services** | Handles OTP verification for secure account login |
| **OneSignal API** | Push notifications for lawyers and admins |
 
---
 
## Deployment
The application is fully hosted on the cloud:
 
| Component | Platform | URL |
|-----------|----------|-----|
| PHP Backend | Railway | `https://2025gpg22-production.up.railway.app` |
| Python AI API | Railway | `https://ai-production-b7fa.up.railway.app` |
| MySQL Database | Railway | Managed MySQL instance |
| Files & Images | Cloudinary | Cloud name: `dmhrba99m` |
 
---
 
## Launching Instructions (Local Development)
 
Follow the steps below to run Mujeer in a local development environment.
 
### 1. Prerequisites
Make sure the following tools are installed:
- Flutter SDK (version 3.0 or above)
- Android Studio (for Android emulator + SDK tools)
- VS Code or Android Studio for development
- PHP 8+ with `mysqli` extension
- Git
- OneSignal Account (for notifications)
- Firebase Project (for OTP services)
- Cloudinary Account (for file storage)
---
 
### 2. Backend Setup
 
#### 2.1 Database
The production database is hosted on Railway. For local development:
1. Open phpMyAdmin
2. Create a new database named `mujeer`
3. Import the SQL file from the `database/` folder
#### 2.2 Configure `config.php`
Open `mujeer_api/config.php` and set your environment:
 
**Local:**
```php
$DB_HOST = 'localhost';
$DB_PORT = '3306';
$DB_NAME = 'mujeer';
$DB_USER = 'root';
$DB_PASS = 'root';
```
 
**Production (Railway):** values are loaded automatically from Railway environment variables.
 
#### 2.3 Environment Variables
The following variables must be set in Railway (or your `.env` for local):
 
```
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASS
ONESIGNAL_APP_ID
ONESIGNAL_REST_API_KEY
OPENAI_API_KEY
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
```
 
#### 2.4 File Uploads
All file uploads  go to **Cloudinary** automatically via `upload_files.php`, `upload_lawyer_photo.php`, and `upload_license_update.php`.  
No local `uploads/` folder is needed for production.
 
---
 
### 3. AI API Setup
 
The AI service is a FastAPI Python app located in `AI_API/`.
 
#### Local:
```bash
cd AI_API
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
 
#### Endpoints:
 
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/predict` | POST | Predicts legal case category from text |
| `/recommend` | POST | Recommends suitable lawyers |
| `/consult` | POST | Combined predict + recommend |
 
---
 
### 4. Flutter Setup
 
#### 4.1 Install Dependencies
```bash
flutter pub get
```
 
#### 4.2 Backend URL
In `lib/services/api_client.dart`:
 
**Production (default):**
```dart
static const String base = 'https://2025gpg22-production.up.railway.app';
```
 
**Local development:**
```dart
// Android Emulator
static const String base = 'http://10.0.2.2:8888/mujeer_api';
 
// Real device — replace with your laptop IP
static const String base = 'http://YOUR_LOCAL_IP:8888/mujeer_api';
```
 
---
 
### 5. Firebase Setup
The project uses Firebase Authentication Services for OTP verification.
 
Make sure this file exists:
```
android/app/google-services.json
```
 
After adding it:
```bash
flutter clean
flutter pub get
```
 
---
 
### 6. OneSignal Setup
In `lib/main.dart`:
```dart
OneSignal.initialize("YOUR-ONESIGNAL-APP-ID");
OneSignal.Notifications.requestPermission(true);
```
 
---
 
### 7. Third-Party API Keys & Tokens
 
The following APIs require credentials that must be configured before running the app.
 
#### 7.1 OpenAI (GPT-4o) — Contract Drafting
Used to generate AI-powered legal contract drafts.
 
1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create a new secret key
3. Add it to Railway environment variables:
```
OPENAI_API_KEY=sk-...
```
4. It is also referenced in `mujeer_api/config.php`:
```php
define('OPENAI_API_KEY', getenv('OPENAI_API_KEY') ?: '');
```
 
---
 
#### 7.2 Agora
Used for voice calling between clients and lawyers.
 
1. Go to [https://console.agora.io](https://console.agora.io)
2. Create a new project and copy the **App ID** and **Temp Token** ( Note: This feature requires a token that expires every 24 hours. After expiration, the feature will not work.)
3. In `lib/` find the Agora configuration file and set:
```dart
const String agoraAppId = 'YOUR_AGORA_APP_ID';
final String tempToken = 'temp token'
```
 
---
 
#### 7.3 Firebase — OTP Verification
Used for phone number verification during registration.
 
1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project and enable **Phone Authentication**
3. Download `google-services.json` and place it in:
```
android/app/google-services.json
```
 
---
 
#### 7.4 OneSignal — Push Notifications
Used to send notifications to lawyers and admins.
 
1. Go to [https://app.onesignal.com](https://app.onesignal.com)
2. Create a new app and copy the **App ID** and **REST API Key**
3. Add to Railway environment variables:
```
ONESIGNAL_APP_ID=your-app-id
ONESIGNAL_REST_API_KEY=your-rest-api-key
```
4. Add the App ID in `lib/main.dart`:
```dart
OneSignal.initialize("YOUR-ONESIGNAL-APP-ID");
```
 
---
 
#### 7.5 Cloudinary — File & Image Storage
Used to store lawyer photos, license files, and contract documents.
 
1. Go to [https://cloudinary.com](https://cloudinary.com) and create a free account
2. From the dashboard, copy your **Cloud Name**, **API Key**, and **API Secret**
3. Add to Railway environment variables:
```
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```
 
---
 
### 8. Running the App
```bash
flutter run
```
 
Or specify a device:
```bash
flutter run -d emulator-5554
```
 
---
 
### 9. Admin Workflow
The admin signs in through the app using admin credentials.
 
Admin responsibilities:
- Review lawyer registration requests
- View uploaded license files
- Approve or reject lawyer accounts to activate them
---
 
## Done!
Mujeer is fully set up and ready for testing and development.  
For production, all services are live on Railway and Cloudinary — no local server needed.
   
