Demo APK wrapper

Instructions to build the demo APK locally or in CI:

1. Ensure Android SDK + NDK + Java are installed.
2. From the repository root, copy the web build into the wrapper assets:

   cp -r frontend/build/web demo-apk-wrapper/app/src/main/assets/www

3. Build the release APK:

   cd demo-apk-wrapper
   ./gradlew assembleRelease

The wrapper loads the local index.html via a WebView, using demo data baked into
the frontend web build. The built APK is at app/build/outputs/apk/release/app-release.apk
