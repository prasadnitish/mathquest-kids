# Build and deploy

Two GitHub Actions workflows do the work. Nothing is uploaded to Apple unless you start the second one by hand.

## 1. `iOS build and test` (`.github/workflows/ios-ci.yml`)

Runs on every push to `main` and `claude/**`, on pull requests, and on demand.

- **Verify question bank** (Linux): `scripts/verify_question_bank.py --ignore AUDIO.file`. Fails on any wrong answer key. Missing audio clips are ignored on purpose until the audio phase.
- **Build and unit tests** (macOS): builds the `MathQuestKids` scheme and runs `MathQuestKidsTests` on the newest iPad simulator. UI tests are not run in CI.

Download the `ios-ci-results` artifact for the full log and the `.xcresult` bundle.

## 2. `Upload to TestFlight` (`.github/workflows/testflight.yml`)

Manual only (Actions tab, Run workflow). It archives a Release build, signs it with cloud-managed signing, and uploads it to App Store Connect.

### One-time setup

1. **App record.** App Store Connect must already have an app with bundle id `com.nitishprasad.sproutmath` under team `YNCCXQ5TUR`.
2. **API key.** App Store Connect, Users and Access, Integrations, App Store Connect API. Create a key with the **App Manager** (or Admin) role. Download the `.p8` once, and note the Key ID and the Issuer ID.
3. **Repository secrets** (Settings, Secrets and variables, Actions):

   | Secret | Value |
   |---|---|
   | `ASC_KEY_ID` | the Key ID |
   | `ASC_ISSUER_ID` | the Issuer ID |
   | `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` (macOS) |

4. **Approval gate (recommended).** Settings, Environments, create `testflight`, and add yourself as a required reviewer. The job pauses for your approval before it touches Apple.

### Each release

1. Make sure `iOS build and test` is green on the commit you want.
2. Run `Upload to TestFlight` and enter a `build_number` higher than any build already in App Store Connect (`CURRENT_PROJECT_VERSION` in the project is `1`; the marketing version `1.0` is unchanged by the workflow).
3. Wait for processing in App Store Connect, then add testers.

### Things to know

- Signing is automatic (`CODE_SIGN_STYLE = Automatic`), so the API key lets Xcode create and use the distribution certificate and profile. No certificates are stored in the repository or in secrets.
- The key file is written to the runner's temp directory and deleted at the end of the job.
- The app targets kids. Before the first public release, confirm the App Store age rating and privacy answers, and see `docs/APP_STORE_COMPLIANCE.md` and `docs/qa/VOICE_ENHANCEMENT_PLAN.md` (ElevenLabs terms for child-directed apps).
- `scripts/run-local-qa.sh` has a hard-coded path from one developer's Mac; use the workflows instead, or edit `PROJECT`.
