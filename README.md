# Setting up APLanes:

<img src="https://i.imgur.com/xlj2qNs.png?raw=true" />

## Important notes
- The project as provided will make REST requests to the previous Firebase Functions Node.js server. This is exclusively only for enabling Stripe payments. Since Stripe will not be used in the final product, APU will be expected to be change this in the future.

## Steps:

1. Setup Firebase
2. Setup Google Maps API
3. Setup Jawg Maps
4. Build

### Setup Firebase
---
1. Go to: [Firebase](https://firebase.google.com/)
2. Create an account
3. Once registered, go to console: [Firebase Console](https://console.firebase.google.com/)
4. Select "+ Add project"
5. Project name is "APLanes"
6. Keep clicking next until project creation begins
7. Press the Flutter icon

    <img src="https://i.imgur.com/aNLXC0y.png?raw=true" />

8. Follow instructions 1 to install Firebase CLI and the Flutter SDK, and instruction 2 to create the `firebase_options.dart` file. Instruction 3 is already completed.
9. Once done, go back to project console and open "Authentication" using the left-hand pane, under "Build"
10. Press "Get started", select "Email/Password", and enable ***only*** first option
11. In Firebase Authentication, go to "Users" and select "Add user"
12. Enter an email/password combination for admin usage
13. Make sure to save the User UID for later
13. Open "Firestore Database" using the left-hand, under "Build"
14. Press "Create database" and choose "Start in production mode"
15. Press next and choose appropriate server (asia-southeast1 recommended) and press enable
16. Once the database is created, select "Rules"

    <img src="https://i.imgur.com/kXWvrdJ.png?raw=true" />
    
16. Paste provided rules in `firebase_rules.txt` found in the project root and modify line 5 to include the admin User UID from earlier
17. Press "Publish" once completed
18. Congrats! Firebase has been setup!

**Helpful guide:**

- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup?platform=ios)

### Setup Google Maps API
---
**It is highly recommended to follow the guide below. The provided steps will roughly cover the steps necessary.**

1. Go to: [Google Cloud Console](https://console.cloud.google.com/)
2. Accept and continue
3. Select "CREATE PROJECT"
4. Project name is "aplanes"
5. Open project once created
6. Setup billing account by going to "BILLING" in left-hand pane
7. Once billing account is linked, go to: [API Console](https://console.cloud.google.com/project/_/google/maps-apis/api-list?utm_source=Docs_EnableAPIs&utm_content=Docs_Central&_gl=1*1hz8tby*_ga*OTgwMzk3ODE5LjE2NzQxODg5MzU.*_ga_NRWSTWS78N*MTY4ODY5NzU1NC4zMC4xLjE2ODg2OTc5MzMuMC4wLjA.)
8. Select the project, and scroll down to enable:
    - Directions API
    - Places API
9. Go to: [Credentials](https://console.cloud.google.com/project/_/google/maps-apis/credentials?utm_source=Docs_CreateAPIKey&utm_content=Docs_Central&_gl=1*138fzt5*_ga*OTgwMzk3ODE5LjE2NzQxODg5MzU.*_ga_NRWSTWS78N*MTY4ODY5NzU1NC4zMC4xLjE2ODg2OTc5ODguMC4wLjA.)
10. Select the project, and press "+ CREATE CREDENTIALS" on top, and select "API key"
11. Copy API key and store for later
12. Close the API key popup and select the newly created API key under "API Keys"
13. Name the API key as desired, and select "Restrict key" under "API restrictions"
14. Choose "Directions API" & "Places API" in the dropdown for API restrictions
15. Save and continue
16. Open project directory and open `./assets/.env`
17. Paste newly created API key for `MAPS_API_KEY`
18. Good job! Google Maps has been setup!

**Helpful guide:**

- [Google Maps API Setup Guide](https://developers.google.com/maps/get-started)

### Setup JAWG
---
1. Go to: [Jawg Lab](https://www.jawg.io/lab/)
2. Create an account
3. Once logged in, select "Access Tokens" from the left-hand pane
4. Select "+ ADD NEW ACCESS TOKEN"
5. Provide a name and press "Create access token"
6. Copy newly created token
7. Open project directory and open `./assets/.env`
8. Paste newly created API key for `JAWG_TOKEN`
9. You're all done! Jawg is now setup!

**Helpful guide:**

- [Jawg Setup Guide](https://www.jawg.io/docs/apidocs/maps/)

### Build
---
1. Make sure the Flutter SDK has been installed, if not follow provided guide below
2. Open Terminal and go to project directory 
3. Execute command `flutter build apk --release`
4. Newly created APK located in `./build/app/outputs/flutter-apk/app-release.apk`
5. For a thorough guide on building for release on Play Store refer to the provided guide

**Helpful guides:**

- [Install Flutter for Windows](https://docs.flutter.dev/get-started/install/windows)
- [Build and release an Android app](https://docs.flutter.dev/deployment/android)
