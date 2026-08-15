# blackjack21_v2 — Project Rules

## Language Rule (MANDATORY)

The user writes in Hebrew. **All replies are written in English**, always, throughout this project.
Hebrew input is normal — it is never a request to switch reply language.

## Delivery Rule (MANDATORY)

**After every bug fix and every new feature, without being asked:**

1. **Install a fresh build on the phone** — Michael's Android, over USB:

   ```bash
   flutter build apk --release && \
     adb -s R5GYB2NHR5D install -r build/app/outputs/flutter-apk/app-release.apk
   ```

   **Both commands are required.** The install step does *not* rebuild — on its own it ships
   whatever `build/app/outputs/flutter-apk/app-release.apk` already contains, which silently
   installs a stale binary and makes the fix look like it did not work.

   **Keep the `-r` flag.** It upgrades in place, so the signed-in account, chip balance and saved
   `gameStateV1` blob survive. A plain `adb install` fails on an existing package, and uninstalling
   first would wipe the player's progress.

   Device: `R5GYB2NHR5D` (Samsung `SM_S731B`), package `com.micorlov.blackjack21_v2`. Run
   `adb devices -l` if the id ever changes; the phone must be unlocked with USB debugging on.
   Note `flutter devices` may list only iOS/wireless targets and miss it — trust `adb devices`.
   Verify the install actually landed with
   `adb shell dumpsys package com.micorlov.blackjack21_v2 | grep lastUpdateTime` and check it
   against the APK's build time. If the install fails (device offline, unauthorized, locked
   screen), say so explicitly — never report a change as delivered when it was only committed.

   **iOS delivery is unavailable** and should not be attempted: Xcode has no Apple ID signed in,
   so `flutter build ios` fails with *"No Accounts"* and *"No profiles for
   'com.micorlov.blackjack21V2' were found"*. Ask Michael to sign in under
   Xcode → Settings → Accounts before ever building for iPhone again.

2. **Commit locally** — `git add` + `git commit` in this repo only. **Never `git push`** unless the
   user asks for it in that same message.

   ```
   <type>: <one-line summary>

   <body: what changed and why>
   ```

   Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`.

3. **Report what was done** — in the reply, state the change, the install result, and the commit
   subject.

Doc-only changes (no code touched) skip step 1 and say so.

## Documentation Rule (MANDATORY)

**Every future update to this project MUST update the Markdown docs in the same change.**

No code change ships without a corresponding doc update. This applies to features, fixes,
refactors, dependency bumps, and asset additions alike.

### What to update

| Change type | Required doc update |
|---|---|
| New feature | `README.md` → **Features** + **Changelog** entry |
| Bug fix | `README.md` → **Changelog** entry |
| Refactor / file moves | `README.md` → **Project Structure** + **Changelog** entry |
| New dependency (`pubspec.yaml`) | `README.md` → **Dependencies** + **Changelog** entry |
| New assets (sfx, images) | `README.md` → **Assets** + **Changelog** entry |
| New project convention | This file (`CLAUDE.md`) |

### Changelog format

Newest first, at the top of the **Changelog** section in `README.md`:

```markdown
### YYYY-MM-DD
- <type>: <what changed, one line, user-visible framing where possible>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf` (same set as commit messages).

### Definition of done

A task is complete only when **all** of these are true:

- [ ] Code change made and verified (`flutter analyze` clean)
- [ ] `README.md` updated per the table above
- [ ] Changelog entry added with today's date
- [ ] Doc wording matches what the code actually does — no aspirational claims

If a change is genuinely doc-invisible (e.g. a whitespace-only edit), say so explicitly in the
summary rather than silently skipping the doc update.
