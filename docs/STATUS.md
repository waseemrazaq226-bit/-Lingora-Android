# Feature status

| Area | Implemented in source | Remaining work |
| --- | --- | --- |
| Magic Academy UI | Five themed canvas environments, floating islands, castles, waterfall, illustrated banners, light and dark palettes, onset and completion transitions, haptic feedback | Device performance and visual QA, richer path animation, separate 3D Lumi character and ten poses |
| Onboarding | Seven guest setup steps, explanation language, goal, level and interests, searchable catalog | Additional courses, native-language menus, sign-in and sync |
| Courses | One introductory English course with bilingual learning material across five worlds | Full beginner curriculum depth, external educator review, unit exams, placement and other courses |
| Exercises | Phrase study, bilingual recognition, word ordering, missing words and audio comprehension with feedback | Dedicated matching, validated open translation and writing, contextual dialogue completion, picture vocabulary and speaking exercise types |
| Progress | Local lesson checkpoints, XP, gems, achievements, streak preference, daily goal, accessories, activity bars, phrase collection, spaced review | Per-item mastery, multiple simultaneous checkpoints, daily and weekly challenges |
| Offline | Bundled English content and synthetic audio, local progress and rewards | Downloadable packs and online synchronization |
| Lumi tutor | Configurable HTTPS backend and selectable roleplay, persona and curriculum context, token authentication, rate limits, input/output heuristics, token reporting, local conversation clearing | Live provider verification, production moderation, authenticated accounts, distributed durable quotas, cloud sync and consent flows |
| Speaking | Device speech recognition, transcript, TTS playback controls and listen-and-repeat | Streaming/full duplex, real pronunciation assessment, fluency and word-level scoring, voice testing on device |
| Accessibility | System font scaling, scrolling layouts, Urdu text direction, semantic labels and reduced-motion handling for custom transitions | Device screen-reader checks, broad font coverage checks, full RTL UI, device size and performance testing |
| Build | Scaffold preparation script, native Kotlin bridge, CI job, automated test sources | First successful clean GitHub Actions run, verified APK, Android integration tests |

## Deployment boundary

The optional tutor is a single-process reference deployment. Access codes are provisioned by the operator. Quotas reset if the backend restarts. The filters and prompts provide basic safeguards. A public student deployment requires production moderation, identity and consent decisions, abuse procedures, provider privacy review, and live device testing. The shipped course works in guest mode without sending learning progress to a server.

Only English has a course. All 59 entries from the brief appear in the catalog, including Esperanto and Latin. The course is an original starter curriculum and has not been independently reviewed.
