# Enable the AI Sales Agent (Groq free-tier) + Serper listing search

The Sales Agent reads its keys at **compile time** via `--dart-define`.
No Groq key in the build ⇒ the screen shows its "not enabled" card and makes
zero network calls. That card is the feature working as designed, not a bug.

Providers used (both free, no credit card):

- **Groq** (`GROQ_API_KEY`) — the conversation model (Llama 3.3 70B on Groq's
  OpenAI-compatible API). Get a key at https://console.groq.com/keys.
- **Serper** (`SERPER_API_KEY`) — Google search, scoped to `site:dwelleo.sa`,
  surfaces real listings during BITEP qualification. 2,500 free credits at
  https://serper.dev. Optional: if absent, the agent still chats, just without
  listing cards.

## One-time local setup

1. Copy the template and paste your keys (file is gitignored — never commit it):

   ```bash
   cp env/ai.example.json env/ai.json
   # edit env/ai.json → "GROQ_API_KEY": "<your key>", "SERPER_API_KEY": "<your key>"
   ```

2. Run with the env file — pick ONE:

   - **VS Code:** press Run on any "Dwelleo …" config — all three carry the
     `--dart-define-from-file=env/ai.json` flag automatically.
   - **Terminal:**

     ```bash
     flutter run --flavor dev -t lib/main_dev.dart \
       --dart-define-from-file=env/ai.json
     ```

## Rules that bite

- Dart-defines apply **only on a full build** — hot reload / hot restart of a
  session started without the flag will NOT pick the key up. Stop the app and
  run again.
- Never launch from Xcode directly — it reuses the previous Flutter run's
  dart-defines and can produce a key-less build. Use VS Code or the terminal.
- 429 in chat = Groq's free rate limit was hit; wait a moment and retry. The
  app shows the specific rate-limit message.
- Rotate a key before any public/store build; restrict it in its console.

## CI / Firebase App Distribution builds

Add `GROQ_API_KEY` and `SERPER_API_KEY` secrets (Codemagic env-var group /
GitHub secret). `codemagic.yaml` already appends them to every build command:

```bash
--dart-define=GROQ_API_KEY=$GROQ_API_KEY --dart-define=SERPER_API_KEY=$SERPER_API_KEY
```

Unset secret ⇒ empty define ⇒ the agent ships in its safe not-configured
state — distribution builds never break because of a missing key.
