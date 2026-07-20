# Enable the AI Sales Agent (demo Gemini adapter)

The Sales Agent reads its key at **compile time** via `--dart-define`.
No key in the build ⇒ the screen shows its red "not enabled" card and makes
zero network calls. That card is the feature working as designed, not a bug.

## One-time local setup

1. Copy the template and paste your key (file is gitignored — never commit it):

   ```bash
   cp env/gemini.example.json env/gemini.json
   # edit env/gemini.json → "GEMINI_API_KEY": "<your key>"
   ```

2. Run with the env file — pick ONE:

   - **VS Code:** select the launch config **“Dwelleo Dev + AI (Gemini)”**.
   - **Terminal:**

     ```bash
     flutter run --flavor dev -t lib/main_dev.dart \
       --dart-define-from-file=env/gemini.json
     ```

## Rules that bite

- Dart-defines apply **only on a full build** — hot reload / hot restart of a
  session started without the flag will NOT pick the key up. Stop the app and
  run again.
- The plain "Dwelleo Dev" launch config intentionally has no define, so the
  app still builds when `env/gemini.json` doesn't exist.
- 429 in chat = the Google AI Studio project has no credits
  (https://ai.studio/projects). The app shows the specific quota message.
- Rotate the key before any public/store build; restrict it in AI Studio.

## CI / Firebase App Distribution builds (local agents)

Add a `GEMINI_API_KEY` secret (Codemagic env-var group / GitHub secret) and
append to the build command:

```bash
--dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

Unset secret ⇒ empty define ⇒ the agent ships in its safe not-configured
state — distribution builds never break because of a missing key.
