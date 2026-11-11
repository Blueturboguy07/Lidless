# Lidless: notes for agents

`CLAUDE.md` holds the contributor notes. This block is the publik contract.

## publik API
- Base URL: https://publikhq.com/api/v1 (OpenAI Chat Completions, Responses, Anthropic Messages)
- Models: publik-fast, publik-balanced, publik-smart only; never a vendor model name
- Sign in with publik: the publik module's gate runs at start-up, before the first screen; it also sends usage telemetry
- This app uses no AI (`Publik.usesAI` is false): the gate shows the sign-in screen only, and there is no provider choice
- Key: per-install `pk_` from POST /installs, stored at the publik credential path; env PUBLIK_API_KEY / PUBLIK_API_BASE_URL override
- App token: `PublikAppToken` in Info.plist from the `PUBLIK_APP_TOKEN` build setting (`scripts/release.sh` reads the gitignored `.publik-app-token`; CI reads the repo secret), or PUBLIK_APP_TOKEN in the environment
- 402: show error.message plus error.top_up_url only
- Never print or log a key
- Docs: https://publikhq.com/llms.txt, https://publikhq.com/developers, https://publikhq.com/skills/api.md
