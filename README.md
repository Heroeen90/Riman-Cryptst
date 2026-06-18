# Riman Cryptst - Sovereign Cryptographic Suite

An advanced, security-focused hybrid cryptographic suite utilizing triple-layer encryption pipelines, sovereign passphrases, and interactive mathematical spectrum projections mapped to Riemann non-trivial zeros.

This repository features both a production-ready **React Web Console** (hosted as a client SPA) and a **Flutter Mobile App** complete with solid automated build pipelines.

---

## 🚀 DevOps - GitHub Actions Pipeline (`android-build.yml`)

We have integrated a standard production-grade Continuous Integration (CI) pipeline inside `.github/workflows/android-build.yml` to automatically test, analyze, and build the native Android applications when you upload changes.

### Complete Flow & Stages inside the Workflows:
1. **Repository Checkout**: Obtains the code.
2. **Setup JDK**: Installs Java Zulu Development Kit 17.
3. **Setup Flutter SDK**: Installs the latest stable Flutter 3.x with automated compiler caching.
4. **Caching Engines**: Automatically caches Flutter's pub packages (`~/.pub-cache` and `.dart_tool`) and Gradle build wrappers to speed up subsequent integration stages.
5. **Quality Gate Checks**:
   - `flutter pub get` pulls dependencies.
   - `flutter pub outdated` flags deprecated libraries.
   - `flutter analyze` runs static analyzer (Lint analysis).
   - `flutter test` fires the widget and cryptographic unit test suite.
6. **Binaries Compile**: Compiles both a **Debug APK** (`app-debug.apk`) and a **Release APK** (`app-release.apk`).
7. **Artifact Upload**: Securely uploads compiled binaries so you can download them directly from your GitHub Actions run workspace summary.

---

## 📦 How to Use & Download the Resulting APK

To run your build processes on GitHub and fetch the output APK:

1. **Commit and Push**: Ensure all codebase files including `.github/workflows/android-build.yml` are pushed to your GitHub repository.
2. **Open GitHub Actions**: Navigating to your repository on GitHub, click the **Actions** tab.
3. **Select Workflow**: Under the list of workflows on the left panel, select **Riman Cryptst - Production DevOps CI**.
4. **View Build Outputs**: When a build completes (indicated by a green checkmark):
   - Scroll down to the **Artifacts** section at the bottom of the page.
   - You will see a file named `riman-cryptst-apks-<RUN_NUMBER>`.
   - Click to download the package. Unzipping it contains both `app-debug.apk` and `app-release.apk`.

---

## 🛠️ Testing Locally

You can run quality gates manually on your terminal before pushing commits:

```bash
# Clear caches
flutter clean

# Retrieve dependencies
flutter pub get

# Static checks and compilation test
flutter analyze
flutter test

# Compile release builds 
flutter build apk --release
```

---

## 🌐 React Web Application Development

The accompanying React Web console serves as the interactive analytical and cryptographic platform:
- Core scripts are maintained in `/src`.
- Web assets reside in `/assets`.
- Powered by modern **Vite** and **Tailwind CSS**.
