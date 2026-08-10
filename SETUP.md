# SETUP — Math Buddies (step by step, Hinglish)

## 1) GitHub repo
1. github.com → **New repository**
2. Name: `math-buddies` → **Private** ✅ → Create.
3. Repo page pe **"uploading an existing file"** link → is zip ke saare files drag-drop karo → **Commit changes**.

## 2) GitHub Secrets (4) — signing kit zip se values lo
Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:
| Secret name | Value |
|---|---|
| `SIGNING_KEYSTORE_BASE64` | signing kit ke `SECRET_SIGNING_KEYSTORE_BASE64.txt` ka poora content |
| `SIGNING_STORE_PASSWORD` | signing kit ke `SECRET_SIGNING_STORE_PASSWORD.txt` ka content |
| `SIGNING_KEY_PASSWORD` | signing kit ke `SECRET_SIGNING_KEY_PASSWORD.txt` ka content |
| `SIGNING_KEY_ALIAS` | signing kit ke `SECRET_SIGNING_KEY_ALIAS.txt` ka content (alias: `mathbuddies`) |

## 3) Build chalao
- Repo → **Actions** → pehla run apne aap chal jayega (push pe trigger).
- Nahi chala to: Actions → **Build Math Buddies APKs** → **Run workflow**.
- Green ✅ hone par run kholo → neeche **Artifacts**:
  - `AMAZON-UPLOAD-signed-release` → **Amazon Console mein yehi upload karna hai**
  - `APPETIZE-ONLY-debug` → sirf Appetize.io test ke liye. **Amazon pe kabhi nahi!**

## 4) Test
- Appetize.io: debug APK upload karo → sab 6 games khel ke dekho.
- Ya apne Android/Fire tablet pe debug APK sideload karo.

## 5) Amazon submission
Jab test pass ho jaye, mujhe bolo — main Console ka step-by-step walkthrough dunga
(price $4.99, Fire tablets, Kids+, privacy policy URL, India tax interview — sab).

## Common errors → matlab
| Error | Matlab |
|---|---|
| `key.properties NOT FOUND` | Secrets set nahi hue — step 2 dobara check karo |
| `ANDROID DEBUG certificate` | Debug APK Amazon pe upload kar diya — sirf signed-release upload karo |
| `Signature MISMATCH` | Galat keystore/secret — signing kit wale values hi use karo |
| Version code error (Console) | `pubspec.yaml` mein version bump karo (rule J12) |
