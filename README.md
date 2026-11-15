# LINGORA 1.0.0

**Your Language. Your Adventure. Your World.**

An Android Flutter project for Magic Academy, a bilingual beginner English learning app. The repository includes the Dart application, original environment illustrations drawn on a Flutter canvas, the supplied Lumi icon, synthetic practice audio, an optional Node.js tutor server, tests, and an Android build workflow.

## Get the debug APK through GitHub

1. Extract this archive. Open the extracted `lingora` folder.
2. Create a GitHub repository and push the **contents** of that folder to its root. Keep the hidden `.github` directory. The root should directly contain `pubspec.yaml` and `.github/workflows/android.yml`.
3. Open **Actions → LINGORA Android APK → Run workflow**. A push to `main` also starts it.
4. Open the successful run and download **LINGORA-1.0.0-debug** under Artifacts. Extract the artifact and install `app-debug.apk` on Android.

The workflow generates Android project files with pinned Flutter 3.32.8. It verifies that both the executable Gradle wrapper and wrapper JAR exist before analysis, tests and APK compilation. Application ID is `com.lingora.academy`. This workflow has not been run on GitHub for this delivery.

## Build locally

Use Flutter 3.32.8, Java 17, an Android SDK configured for Flutter, Python 3 with Pillow, and Node.js 22 or later for tutor tests.

```sh
python3 -m pip install Pillow
python3 scripts/prepare_android.py
test -x android/gradlew
test -s android/gradle/wrapper/gradle-wrapper.jar
flutter pub get
flutter analyze
flutter test
node --test backend/server.test.mjs
flutter build apk --debug
```

The APK path is `build/app/outputs/flutter-apk/app-debug.apk`. The Android scaffold is generated in an isolated directory so it cannot overwrite project code or tests. The script copies in the native bridge, sets the displayed app name and permissions, and applies the launcher icon. Use `flutter run` with a connected Android device for device testing.

## Offline learning

Choose guest mode to start. The installed course contains 15 lessons, 45 distinct bilingual phrase entries and 45 synthesized English audio clips. Complete lessons to open more map nodes. Continue resumes the last stored checkpoint for that lesson. Reviews use a lesson-level interval that grows after correct practice and shortens after mistakes. Android app-private preferences persist progress, rewards and settings.

Course titles, interface labels and navigation are English. Course explanations can be Urdu or English. Urdu text uses RTL direction and Android font fallback. See [the language matrix](docs/LANGUAGES.md) for course status.

## Configure Lumi AI

Guest lessons work without a server. Live tutoring requires a configured AI provider and an HTTPS front end.

1. Copy `backend/.env.example` to `backend/.env`. Use a random access code of at least 24 characters. Generate one with `openssl rand -hex 24`.
2. Enter the provider API key, HTTPS API base URL, and a model supporting Chat Completions with `max_completion_tokens`. Keep the provider key on the server.
3. Run `node --env-file=backend/.env backend/server.mjs` from the project root. Put an HTTPS reverse proxy in front of this server. Retain the `/v1/tutor` path and set request body and connection limits on that proxy.
4. In the app, open **Lumi AI → Connect tutor server** and enter the HTTPS base URL and student access code. The code stays in memory and must be re-entered on app restart.

| Setting | Purpose |
| --- | --- |
| `AI_API_KEY` | Provider credential held by the backend |
| `AI_MODEL` | Compatible model ID at your provider |
| `AI_BASE_URL` | HTTPS Chat Completions base, defaults to OpenAI's v1 URL |
| `ACCESS_TOKENS` | Comma-separated random student codes, 24 characters or longer |
| `MINUTE_LIMIT` | Requests allowed per code per fixed minute, defaults to 8 |
| `DAILY_LIMIT` | Requests allowed per code per UTC day, defaults to 40 |
| `BIND` and `PORT` | Server bind address and port, default to loopback port 8080 |

The app supports manual retries. Requests contain the recent transcript, explanation language, scenario, self-reported level and completed lesson count. Local transcripts are kept in memory and can be cleared. The backend logs token counts without storing message bodies. The configured provider has its own retention settings. Review those before inviting students to use the server.

Voice uses Android's speech recognition interface and installed TTS. The learner can review a transcript before sending. English-only AI replies can be played or replayed when English explanations are selected. Android's recognition service may use a network connection even when offline recognition is preferred. The app does not record or retain raw audio.

## Status and asset attribution

- [Implemented features and limitations](docs/STATUS.md)
- [Testing report](docs/TESTING.md)
- Lumi launcher image supplied and approved by the project owner. Academy artwork is original Flutter drawing code. Bundled audio was synthesized using the Flite SLT voice. See [Flite notices](docs/FLITE-NOTICE.txt).
