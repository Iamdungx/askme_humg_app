---
name: stitch-to-flutter
description: Converts Google Stitch HTML mockup screens into Flutter widgets for the AskmeHUMG project. Use when the user pastes Stitch HTML, says "convert this screen", "implement this UI from Stitch", or shares HTML from a design tool to be converted to Flutter code.
---

# Stitch → Flutter Converter (AskmeHUMG)

## What this skill does

Analyzes Google Stitch-exported HTML and converts it to production-ready Flutter widgets that match the AskmeHUMG design system.

## Step-by-step process

**Step 1 — Analyze the HTML**
- Identify layout structure (columns, rows, stacks)
- Note colors → map to `AppColors.*` tokens
- Note spacing values → map to `AppSpacing.*` / `AppRadius.*`
- Identify interactive elements (buttons, inputs, taps)
- Note which existing global widgets can be reused

**Step 2 — Map to design system**

| HTML element | Flutter equivalent |
|---|---|
| Card/panel with border | `AppCard` |
| Button (primary) | `AppButton(variant: AppButtonVariant.primary)` |
| Button (outlined) | `AppButton(variant: AppButtonVariant.secondary)` |
| Text link / ghost | `AppButton(variant: AppButtonVariant.ghost)` |
| User avatar circle | `AppAvatar(imageUrl: ..., name: ...)` |
| "Anonymous" chip | `AnonymousBadge()` |
| Empty list state | `EmptyState(message: ..., icon: ...)` |
| Loading skeleton | `LoadingShimmer(...)` |
| Error state | `ErrorState(onRetry: ...)` |

**Step 3 — Write Flutter code**

Rules:
- Widget class: `ConsumerWidget` if reads providers, else `StatelessWidget`
- File path: `lib/app/modules/{feature}/presentation/screens/{name}_screen.dart`
- Sub-widgets: private classes `_WidgetName` in same file if < 60 lines, else separate file in `widgets/`
- Colors: always `AppColors.*` or `Theme.of(context).colorScheme.*` — never hex literals
- Spacing: always `AppSpacing.*` or `AppRadius.*` — never raw numbers
- Text: always `context.l10n.*` — never hardcoded strings (add key to ARB files if missing)
- `withOpacity` is BANNED → use `Color.withValues(alpha: x)`
- Navigation: `context.go('/')` / `context.push(...)` via GoRouter typed routes in `app_routes.dart`

**Step 4 — Wire navigation**

Update `lib/config/app_routes.dart`:
- Replace `_PlaceholderScreen(title: '...')` with the real screen class
- Keep `@TypedGoRoute` annotation and route class intact

**Step 5 — State (if screen needs data)**

Use placeholder/mock data for pure UI screens. If the screen needs live data:
- Create provider in `lib/app/modules/{feature}/presentation/{feature}_providers.dart`
- Use `AsyncNotifier` pattern
- Show `LoadingShimmer` for `isLoading`, `ErrorState` for error, content for data

## Screen-specific notes

### Profile Screen (`/u/:userId`)
- If `currentUserId == userId`: show "Share Link" card, hide question input
- If different user / guest: show `AskQuestionSheet` text input (max 300 chars)
- Recent answers list → read-only `FeedItemCard` previews

### Inbox Screen (`/inbox`)
- Two tabs using `DefaultTabController`: Unanswered | Answered
- Badge count on Unanswered tab
- Each card: question text + timestamp + Reply/Delete buttons
- Reply → `AnswerComposeRoute(questionId: q.id).push(context)`

### Answer Compose Screen (`/inbox/answer/:questionId`)
- Read-only question card at top
- Multiline `TextField` for answer
- `SwitchListTile` for "Publish to Feed" (default `true`)
- Submit → `WriteBatch` (UC-3.3) — do NOT call separately

### Feed Screen (`/`)
- `ListView.builder` with `FeedItemCard`
- Scroll-to-bottom triggers pagination (`loadMore()`)
- Pull-to-refresh resets feed
- Like button uses `flutter_animate` scale bounce
- Comments → `DraggableScrollableSheet` bottom sheet

### Comments Bottom Sheet
- Part of Feed screen file or separate `comments_screen.dart`
- `DraggableScrollableSheet` with `initialChildSize: 0.6`
- Anonymous toggle + text input at bottom

## Checklist after converting each screen

- [ ] No hardcoded colors (hex literals)
- [ ] No hardcoded spacing numbers outside AppSpacing/AppRadius
- [ ] No hardcoded strings (all in l10n ARB)
- [ ] `app_routes.dart` updated — placeholder removed
- [ ] `flutter pub run build_runner build --delete-conflicting-outputs` if new `@riverpod` or `@freezed` added
- [ ] Lints pass: `flutter analyze`

## Reference files

- Design tokens: `lib/app/core/values/app_colors.dart`, `app_spacing.dart`, `app_typography.dart`
- Global widgets: `lib/app/global_widgets/`
- Routes: `lib/config/app_routes.dart`
- UI specs: `.docs/UI_UX_SPECS.md`
- UC details: `.docs/use_case/`
