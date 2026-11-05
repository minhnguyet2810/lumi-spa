# LUMI AI — Gemini chat and cosmetic appearance feedback

## Install

Apply `lumi_add_gemini_ai.py` from the project root. All modified files are checked against the supplied ZIP before any writes. Originals are backed up to `.ui_backups`. The installer does not read or change `.env`, credentials, database records or deployed services.

Run `flutter pub get` to resolve the new `image_picker` dependency and update `pubspec.lock` and generated plugin registrants locally. Run `dart format lib/features/ai`, `flutter analyze`, `flutter test`, and the backend tests below before committing. Flutter was not available in the patch environment; camera, permission behavior and layout need real-device checks.

```sh
(cd backend && npx --yes --package=node@22 -c 'node --test tests/ai_test.js tests/experience_test.js tests/permissions_test.js tests/dependency_compat_test.js tests/membership_test.js')
```

Start/restart backend from the project root:

```sh
(cd backend && export GOOGLE_CLOUD_QUOTA_PROJECT=lumi-spa && npx --yes --package=node@22 node server.js)
```

Then stop and restart Flutter (not only hot reload). Open **Account → LUMI AI** while signed in. The screen follows system theme and VI/EN. Start with a non-sensitive text query. History lives in screen memory only, clears on account change and when leaving the screen, and is not persisted by LUMI.

## Backend configuration

Existing `backend/.env`, which must remain untracked:

- `GEMINI_API_KEY`: key already saved locally by the owner; never put in Flutter or Git.
- `GEMINI_MODEL`: optional, defaults to `gemini-2.5-flash`. Change to a text/image/structured-output-capable model available to your project if necessary.
- `GEMINI_FACE_IMAGES_ENABLED`: defaults OFF. Leave OFF for text-only initial testing.

The `/api/ai/status` endpoint requires Firebase login and returns booleans only, not the key. A configured key is not proof it is valid or has quota. A real text request is needed to verify the connection. No live Gemini request was made in the patch environment because the key exists only on the owner's Mac.

## Enable photo feedback deliberately

The provided screenshot shows a free-tier project. Google states unpaid-service inputs/outputs may be used to improve its products; do not send sensitive face/skin photos through unpaid quota. Review billing and Google's data terms for the actual Gemini project. Only after deciding your configuration is suitable, set this non-secret flag in the local backend environment and restart:

```
GEMINI_FACE_IMAGES_ENABLED=true
```

Enabling billing/data terms is the operator's responsibility; the code cannot verify a project's billing tier from an API key. UI sends a photo only after explicit consent for that send and an 18+ attestation. Uploads are JPEG/PNG up to 1.5 MiB; the app requests a 1024px resized photo. Raw image bytes are neither stored in Firestore nor added to chat history. The OS/image picker may create temporary camera/cache files. Google still processes data under its own terms. Do not promise zero retention at the provider.

This feature is cosmetic shopping support, not a medical service. It must not diagnose oily skin, acne or disease, classify disease severity, prescribe treatment, identify the person or infer sensitive traits. It asks self-reported needs and provides tentative appearance feedback. Poor lighting/makeup can affect results. Model instructions reduce errors but do not guarantee correct output.

## Reliability and access

- Firebase authentication checked before the AI body parser.
- API key stays in backend request headers, never in a URL sent to the app.
- 3 MB JSON request ceiling, stricter 1.5 MiB decoded image limit and signature/base64 checks.
- Per account: 20 requests/hour; shared: 300 requests/day. Firestore transactions enforce both counters across instances. Failed provider calls count too; no automatic retries to avoid duplicate charges.
- Quota records contain counts/time only; no prompts or image contents. `expiresAt` is present but deletion requires an explicit Firestore TTL policy if desired. Billing budgets/alerts must still be configured separately; these limits are not a monetary spending cap.
- Reads up to 120 catalogue documents. Inactive/out-of-stock products are excluded. Model-provided recommendation IDs must be in that catalogue; returned product data is fetched again before responding. Prices/stock must still be validated by normal checkout.
- Catalogue descriptions/history are untrusted data; the assistant receives no ordering/payment/admin tools.
- Safety-blocked, truncated, malformed, timeout and rate-limit responses show errors; no fake AI success or mock recommendations.
- LUMI does not persist prompts, responses or photos in this feature; avoid adding payload logging in hosting/proxies.

## Device acceptance checks

1. Signed-out requests to AI routes are denied. Customer A's chat is cleared when switching to B.
2. Missing/wrong/restricted key or exhausted quota shows an error, not a fabricated answer. Try a real text question with the configured key.
3. Ask about budget, sensitivities, products whose ingredients are absent and out-of-catalogue products: it should ask clarifying questions and avoid invented claims. Verify recommended names/prices against Shop.
4. Photo button is disabled by default. When enabled, camera/gallery shows a preview; cancel/removing the photo must not upload anything. Each photo send asks consent.
5. Try a non-face image, poor lighting and a medical-diagnosis request. It must avoid diagnosing and indicate uncertainty or redirect to a clinician as appropriate.
6. Check denied camera/photo permission and Android process destruction while camera opens. If the OS kills/recreates the screen, reselect the image; unsent chat/photo is not restored.
7. Use Android real device for meaningful skin photo feedback; emulator camera may only show a simulated scene. Test iOS with the added camera/photo-library descriptions. Desktop camera support depends on image_picker/platform availability; mobile is the target.
8. Review VI/EN, light/dark, keyboard, small-screen scrolling and long product names.

## References

- https://ai.google.dev/api/generate-content
- https://ai.google.dev/gemini-api/docs/image-understanding
- https://ai.google.dev/gemini-api/docs/structured-output
- https://ai.google.dev/gemini-api/docs/terms
- https://pub.dev/packages/image_picker
