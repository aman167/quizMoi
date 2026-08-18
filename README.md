# quizMoi

quizMoi is an Android-first French active-recall application built with Flutter. It is designed to turn study material—such as pasted text, PDFs, and web articles—into interactive quizzes with personalized explanations and review recommendations.

The application is currently in private development. It is not published on the Google Play Store.

## Current status

The repository currently contains a persistent local learning core with:

- a learner dashboard;
- pasted-text and Android PDF preview/AI-generation screens;
- a timed multiple-choice quiz flow;
- scoring with source-grounded explanations and concept feedback;
- SQLite-backed sources, knowledge bases, quizzes, sessions, attempts, and settings;
- a Python FastAPI generation backend with a versioned structured contract;
- Android, iOS, web, and Windows platform scaffolding.

The remaining offline demo quiz is explicitly separate from generated and saved learning data. Phase 4's direct-PDF checkpoint has passed a real OpenAI emulator test through generation, local save, quiz completion, and app-restart persistence. Camera-captured study images are now explicitly planned as a later Phase 4 source journey but are not implemented yet. Web-article and typed-answer breadth also remains scheduled; interrupted-response recovery is tracked in [DEFECT_LOG.md](DEFECT_LOG.md). See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md).

The intended learner experience and current demo boundaries are defined in [PRODUCT_SPEC.md](PRODUCT_SPEC.md).
Issues found during emulator and self-use testing are tracked in [DEFECT_LOG.md](DEFECT_LOG.md).

## Development environment

The verified Windows development environment uses:

- Windows 11 (64-bit)
- Flutter 3.44.9, stable channel
- Dart 3.12.2
- Android Studio Quail 3
- Android SDK 36.0.0
- Java from Android Studio's bundled JDK
- An Android emulator or physical Android device

## One-time setup on Windows

### 1. Install Flutter

Install Flutter at `C:\flutter`, then add this folder to your user `Path` environment variable:

```text
C:\flutter\bin
```

Close and reopen Command Prompt, then verify the installation:

```cmd
flutter --version
```

### 2. Install Android Studio and the Android SDK

Install the latest stable Android Studio. In Android Studio, open **More Actions → SDK Manager** and install:

- Android SDK Platform (API 36 or a later compatible stable version)
- Android SDK Build-Tools
- Android SDK Command-line Tools (latest)
- Android SDK Platform-Tools
- Android Emulator
- CMake
- NDK (Side by side)

The default SDK location on this development computer is:

```text
C:\Users\ASUS\AppData\Local\Android\Sdk
```

Tell Flutter where the SDK is installed:

```cmd
flutter config --android-sdk "C:\Users\ASUS\AppData\Local\Android\Sdk"
```

Accept the Android licences and validate the toolchain:

```cmd
flutter doctor --android-licenses
flutter doctor -v
```

The Android toolchain should have a green check mark. A missing Visual Studio installation can be ignored while developing only for Android; Visual Studio is required for Windows desktop builds.

### 3. Create an Android emulator

In Android Studio:

1. Open **More Actions → Virtual Device Manager**.
2. Select **Create Virtual Device**.
3. Choose a recent Pixel phone profile.
4. Download and select a compatible x86-64 Android system image.
5. Finish creating the device and press the Run button.

Confirm that Flutter detects the running emulator:

```cmd
flutter devices
```

At least one device with the `android` platform should appear.

## Get the project

Clone the private repository and enter the project directory:

```cmd
git clone https://github.com/aman167/quizMoi.git
cd quizMoi
```

Install the Flutter dependencies:

```cmd
flutter pub get
```

## Run quizMoi

Start an Android emulator first, then list its identifier:

```cmd
flutter devices
```

Run quizMoi on the detected Android device. Replace `emulator-5554` if a different identifier is shown:

```cmd
flutter run -d emulator-5554
```

Flutter compiles the Dart source, asks Gradle to build the Android application, installs the debug APK, and opens quizMoi on the selected device. The first build can take several minutes because Android dependencies and build caches are prepared.

While `flutter run` is active:

- press `r` for hot reload after a code change;
- press `R` for a full hot restart;
- press `q` to stop the running application.

## Run the local quiz-generation backend

The Android app never contains the OpenAI key. It calls a FastAPI service running on this computer, and the backend keeps the key in an environment variable. Pasted text uses `/v1/quizzes/generate`; confirmed PDFs use multipart upload to `/v1/quizzes/generate-pdf`, where the backend includes the PDF directly in an OpenAI Responses API request.

Install Python 3.11 or 3.12, then create the ignored local environment:

```cmd
cd backend
python -m venv .venv
.venv\Scripts\activate
python -m pip install -r requirements.txt
```

Set your key for the current Command Prompt session. Never add the real value to `.env.example`, source files, screenshots, or Git:

```cmd
set OPENAI_API_KEY=your-own-key
set OPENAI_MODEL=gpt-5.6-luna
```

Start the backend and leave this terminal open:

```cmd
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Then run Flutter in a second terminal. The Android emulator uses `http://10.0.2.2:8000` to reach port 8000 on the Windows host. Only debug Android builds allow this local HTTP connection.

Run backend tests without making a real AI request:

```cmd
cd backend
.venv\Scripts\python.exe -m pytest -q
```

## Quality checks

Resolve dependencies:

```cmd
flutter pub get
```

Format the Dart source:

```cmd
dart format lib test
```

Run static analysis:

```cmd
flutter analyze
```

Run automated tests:

```cmd
flutter test
```

Run backend tests:

```cmd
backend\.venv\Scripts\python.exe -m pytest -q backend\tests
```

Static-analysis cleanup and expanded test coverage are tracked in Phase 1 of the development roadmap.

## Build a private debug APK

Create an installable development APK:

```cmd
flutter build apk --debug
```

After a successful build, the file is located at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

This APK is intended only for private development and testing. A production release will eventually require a final application ID, release signing, secure key storage, versioning, and additional quality checks.

## Project structure

```text
lib/
  main.dart              Application entry point and bottom navigation
  models/                Quiz and learner data models
  screens/               Dashboard, content input, quiz, and results screens
  state/                 Provider-based quiz state
  theme/                 Crimson Velocity colors and Material theme
  widgets/               Reusable interface components
test/                    Flutter automated tests
backend/                 Local FastAPI quiz-generation service
android/                 Native Android configuration
ios/                     Native iOS configuration
web/                     Flutter web configuration
windows/                 Flutter Windows configuration
```

## Git workflow

The `main` branch is the stable project baseline. New development should be completed in small feature or fix branches, checked locally, and then merged into `main`. Never commit API keys, Android SDK paths, generated build output, or signing keys.

Useful commands:

```cmd
git status
git switch -c feature/short-description
git add <files>
git commit -m "Describe the change"
git push -u origin feature/short-description
```

## Troubleshooting

### `flutter` is not recognized

Add `C:\flutter\bin` to the Windows user `Path`, close all Command Prompt windows, and open a new one.

### Android `sdkmanager` is not found

Open Android Studio's SDK Manager and install **Android SDK Command-line Tools (latest)**.

### No Android device is detected

Start the emulator in Android Studio's Virtual Device Manager, wait for Android to finish booting, and run:

```cmd
flutter devices
```

### The first Gradle build is slow

The first Android build downloads dependencies and creates local caches. Keep the terminal and emulator open unless Gradle reports an explicit failure.

## Roadmap

The audited plan from the current prototype through private beta is maintained in [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md).
