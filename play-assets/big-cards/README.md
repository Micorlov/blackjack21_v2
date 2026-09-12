# Staged Big Cards screenshots

English set: `en-US/01.png` (readable cards), `02.png` (guided play), `03.png` (sweep result).

1080×1920, rendered from actual app widgets with deterministic game states. No phone frame; headline is 10.9% of the canvas. These are staged review assets, not a published store update or device-captured session. Compare with the released build before upload. Existing artwork and live listing screenshots are untouched.

Regenerate from the repository root:

```bash
flutter test --no-pub --dart-define=CAPTURE_STORE_SHOTS=true test/store_screenshot_capture_test.dart
```

See `docs/growth/README.md` for measurement and release separation.
