---
name: add-l10n-string
description: Adds localization strings to AskmeHUMG ARB files and regenerates localizations. Use when a widget needs a new user-facing string, when hardcoded text is found in a widget, when adding new screen strings, or when the user says "add l10n", "add translation", "add string to ARB", "hardcoded text". Always run after adding new screens or features.
---

# Add l10n String (AskmeHUMG)

## 3 ARB files — always update all 3

```
lib/l10n/app_en.arb   ← English (source of truth)
lib/l10n/app_vi.arb   ← Vietnamese
lib/l10n/app_ja.arb   ← Japanese
```

## Key naming convention

```
{screen}_{element}_{state?}

Examples:
  profileShareLink
  inboxTabUnanswered
  questionSubmitErrorTooLong
  feedEmpty
  answerPublishSuccess
  adminActionRemove
```

## Simple string

```json
// app_en.arb
"myNewKey": "My text here",

// app_vi.arb
"myNewKey": "Văn bản của tôi",

// app_ja.arb
"myNewKey": "テキスト",
```

## String with placeholder

```json
// app_en.arb
"questionCharCount": "{current}/300",
"@questionCharCount": {
  "placeholders": { "current": { "type": "int" } }
},

// app_vi.arb — same key, translated value
"questionCharCount": "{current}/300",
"@questionCharCount": {
  "placeholders": { "current": { "type": "int" } }
},
```

> `@` metadata block must be present in EVERY ARB file that has placeholders.

## Using in widget

```dart
// Import
import 'package:askme_humg/l10n/app_localizations.dart';

// In build()
final l10n = AppLocalizations.of(context);

// Simple
Text(l10n.feedEmpty)

// With placeholder
Text(l10n.questionCharCount(currentLength))
```

> Shortcut: `context.l10n.*` works if `context_ext.dart` extension exists.

## After editing ARB files — MUST run

```bash
flutter gen-l10n
```

This regenerates `lib/l10n/app_localizations*.dart`. Never edit generated files.

## Checklist

- [ ] Key added to all 3 ARB files (en + vi + ja)
- [ ] `@` metadata added for any placeholder
- [ ] Key name follows `{screen}_{element}` convention
- [ ] `flutter gen-l10n` run
- [ ] Widget uses `l10n.keyName` (no hardcoded string)

## Existing keys (do not duplicate)

Common keys already in ARB: `commonRetry`, `commonCancel`, `commonConfirm`, `commonSave`, `commonDelete`, `commonShare`, `commonLoading`, `commonEmpty`, `commonError`.

Check `lib/l10n/app_en.arb` before adding — key may already exist.
