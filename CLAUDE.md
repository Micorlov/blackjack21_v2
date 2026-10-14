# blackjack21_v2 — Project Rules

## Language Rule (MANDATORY)

The user writes in Hebrew. **All replies are written in English**, always, throughout this project.
Hebrew input is normal — it is never a request to switch reply language.

## Delivery Rule (MANDATORY)

**After every bug fix and every new feature, without being asked:**

1. **Install a fresh build on the phone** — Michael's Android, over USB:

   ```bash
   /Applications/Unity/Hub/Editor/6000.3.25f1/Unity.app/Contents/MacOS/Unity -batchmode -nographics -quit \
     -projectPath Unity -executeMethod Blackjack.EditorTools.BuildTools.BuildAndroid -logFile /tmp/build.log && \
     adb -s R5GYB2NHR5D install -r Unity/Builds/Android/blackjack21-unity.apk
   ```

   **Both commands are required.** The install step does *not* rebuild — on its own it ships
   whatever `Unity/Builds/Android/blackjack21-unity.apk` already contains, which silently
   installs a stale binary and makes the fix look like it did not work. The Unity editor cannot
   be open on this project while the batch build runs (it holds `Temp/UnityLockfile`), and the
   build log only reaches `-logFile`, so read it there: `grep "error CS\|Build Finished" /tmp/build.log`.

   **Keep the `-r` flag.** It upgrades in place, so the signed-in account, chip balance and saved
   `gameStateV1` blob survive. A plain `adb install` fails on an existing package, and uninstalling
   first would wipe the player's progress. The APK is signed with `~/.android/debug.keystore`, the
   same key the old Flutter build used, which is what makes the in-place upgrade work — never
   re-sign it with another key.

   Device: `R5GYB2NHR5D` (Samsung `SM_S731B`), package `com.micorlov.blackjack21_v2`. Run
   `adb devices -l` if the id ever changes; the phone must be unlocked with USB debugging on.
   Verify the install actually landed with
   `adb shell dumpsys package com.micorlov.blackjack21_v2 | grep lastUpdateTime` and check it
   against the APK's build time. If the install fails (device offline, unauthorized, locked
   screen), say so explicitly — never report a change as delivered when it was only committed.

   **iOS delivery is unavailable** and should not be attempted: Xcode has no Apple ID signed in.
   Ask Michael to sign in under Xcode → Settings → Accounts before ever building for iPhone.

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

## Unity Project

The game is a Unity 6000.3.25f1 project in `Unity/`; the Flutter app it was ported from was deleted
on 2026-10-14 and lives only in git history. Everything is built in code at runtime — no prefabs, and
the scene is empty — so UI changes are C# changes.

Rules logic lives in `Unity/Assets/Scripts/Core` (no `UnityEngine` references) and is tested with
`Unity -runTests` (command in the README); a Core change is not done until those tests pass.

Firebase is **not committed** (~760 MB of native libraries). After a fresh clone run
`Unity/tools/install_firebase.sh`; without it the `FIREBASE_SDK` define is off and the game falls back
to the offline Null services, so a build that "loses" sign-in is usually a missing SDK, not a bug.
Never commit `Assets/Firebase/`, `Assets/ExternalDependencyManager/`, `Assets/GeneratedLocalRepo/` or
the generated Gradle templates — `.gitignore` covers them.

## Design rules (enforced by RulesAudit)

The UI follows "The Seat" (`docs/design-concepts/the-seat/`). These rules are checked by
`Unity/Assets/Tests/PlayMode/RulesAudit.cs` on every scenario in `Scenarios.cs` at four phone sizes; known
violations sit in `rules-baseline.txt`, which is now **empty** and may only stay that way: a change that
breaks a rule is fixed, never added to the baseline.

| Rule | Value |
|---|---|
| Type ramp (`Type.cs`) | display 40 · h1 32 · h2 24 · title/button 17 · body 15 · bodySm 13 · caption 12 = **floor**, measured on screen (felt `Scale` and `Shrink` included) |
| Tap targets | ≥ 48×48 (`Theme.MinTarget`), disabled controls included |
| Contrast | text ≥ 4.5:1 · control outlines (`ControlBorder`) ≥ 3:1; disabled controls exempt |
| On screen | no glyph cut off by the screen edge (`offscreen`); text a scroll view clips away is exempt |
| Fonts | Sora (UI, card ranks) · Instrument Serif italic (titles) · Space Mono (numbers) · Cinzel only for felt print |
| Tokens | spacing 2/4/8/12/16/20/24/32/48 · radius 8/12/16/20/24/pill — no other values |
| Labels | sentence case as in `en.json`; button captions stay in caps as `en.json` has them |
| Cards | dealer 66×96 · hero 88 wide (≤ 1.4×) · other seats ≥ 42×60 · rank text ≥ 12 |
| Felt | `Theme.Felt #175943`; text on felt uses the `…OnFelt` tokens |

New UI code uses `Type.*` styles and `Theme` tokens, never raw sizes or hex values. Labels on a scaled
canvas (the felt) get `TextFloor.Apply`.

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
| New dependency (Unity package or SDK) | `README.md` → **Dependencies** + **Changelog** entry |
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

- [ ] Code change made and verified (batch build/tests compile with no `error CS`)
- [ ] `README.md` updated per the table above
- [ ] Changelog entry added with today's date
- [ ] Doc wording matches what the code actually does — no aspirational claims

If a change is genuinely doc-invisible (e.g. a whitespace-only edit), say so explicitly in the
summary rather than silently skipping the doc update.
