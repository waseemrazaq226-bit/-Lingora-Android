# LINGORA 1.0.0 testing report

| Check | Result |
| --- | --- |
| Node backend test suite | 7 passed, 0 failed. Exercised authenticated request forwarding with a mocked model, invalid tokens, malformed/oversized requests, quota response, missing provider configuration, network and malformed provider errors, and basic content filtering. |
| Node syntax check | Passed for `backend/server.mjs`. |
| Offline assets | Passed. Validated five worlds, 15 lesson IDs, 45 unique bilingual phrase entries and 59 unique catalog entries. FFmpeg decoded all 45 bundled MP3 clips. |
| Configuration parsing | Python scripts parsed with Python AST. PyYAML loaded pubspec, analyzer options and the GitHub workflow. |
| Flutter analyze and tests | Unrun. Flutter and Dart are unavailable in this environment. Unit and widget tests are included for course validation, checkpoints and reviews, multilingual search, Urdu RTL text, navigation and tutor URL validation. |
| Android APK and integration checks | Unrun. The Android SDK is unavailable. The GitHub workflow is included and has not been executed. |
| Live AI and Android audio/voice | Unrun. The tutor provider was mocked in automated tests. On-device STT, TTS, asset playback, responsive layouts and animations still require Android testing. |

Reproduce the checks that ran:

```sh
node --check backend/server.mjs
node --test backend/server.test.mjs
python3 scripts/verify_assets.py
```

The asset verifier requires FFmpeg. See the README for Flutter checks and Android build steps.
