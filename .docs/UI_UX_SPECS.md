# AskmeHUMG – UI/UX Specifications

> **Design System:** Material 3
> **Font:** Inter (Variable)
> **Theme:** Dark-first (matches HUMG navy identity) — Light mode fully supported
> **Updated:** 01-03-2026

---

## 1. Color Palette

### Architecture

Colors are split into three classes in `app_colors.dart`:

- `AppDarkColors` — dark mode raw tokens (consumed by `AppTheme.dark` only)
- `AppLightColors` — light mode raw tokens (consumed by `AppTheme.light` only)
- `AppSemanticColors` — theme-invariant semantic colors (error, like, opacity tokens)

> **Rule in widgets:** Always use `Theme.of(context).colorScheme.*` — never reference `AppDarkColors` or `AppLightColors` directly in widget code. The theme engine handles dark/light switching automatically.

---

### Dark Mode Tokens (`AppDarkColors`)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#0A0D1A` | Scaffold background |
| `surface` | `#0D1B3E` | Cards, bottom nav |
| `surfaceElevated` | `#162347` | Bottom sheets, inputs, chips |
| `surfaceVariant` | `#11224D` | Snack bars |
| `primary` | `#1A3A8C` | Brand primary (container) |
| `accent` | `#2D9BD8` | Primary actions, CTAs, active tab indicator |
| `onAccent` | `#FFFFFF` | Text/icons on accent |
| `textPrimary` | `#FFFFFF` | Body text, headings |
| `textSecondary` | `#7FA8C9` | Captions, timestamps, hints |
| `textDisabled` | `#3D5A7A` | Disabled UI elements |
| `border` | `#1E3A6E` | Card borders, input borders |
| `divider` | `#152850` | List dividers |
| `shimmerBase` | `#162347` | Shimmer skeleton base |
| `shimmerHighlight` | `#213363` | Shimmer sweep highlight |

### Light Mode Tokens (`AppLightColors`)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F8FAFC` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, bottom nav |
| `surfaceElevated` | `#F1F5F9` | Bottom sheets, inputs, chips |
| `surfaceVariant` | `#E2E8F0` | Snack bars |
| `primary` | `#1A3A8C` | Brand primary (same as dark — HUMG identity) |
| `accent` | `#1A7AAF` | Primary actions (slightly darker than dark mode for contrast) |
| `onAccent` | `#FFFFFF` | Text/icons on accent |
| `textPrimary` | `#0F172A` | Body text, headings |
| `textSecondary` | `#475569` | Captions, timestamps, hints |
| `textDisabled` | `#AFC0D0` | Disabled UI elements |
| `border` | `#CBD5E1` | Card borders, input borders |
| `divider` | `#E2E8F0` | List dividers |
| `shimmerBase` | `#E2E8F0` | Shimmer skeleton base |
| `shimmerHighlight` | `#F8FAFC` | Shimmer sweep highlight |

### Semantic Colors (theme-invariant)

| Token | Hex | Usage |
|-------|-----|-------|
| `error` | `#EF4444` | Validation errors, danger actions |
| `like` | `#EF4444` | Like/heart icon (filled state) |
| `success` | `#22C55E` | Success states |
| `warning` | `#F59E0B` | Warning states |

### Opacity Tokens

Used with `Color.withValues(alpha: x)` — never use `.withOpacity()`.

| Token | Value | Usage |
|-------|-------|-------|
| `AppSemanticColors.opacityDisabled` | `0.5` | Disabled widget overlay |
| `AppSemanticColors.opacitySubtle` | `0.6` | Subtle text/icons |
| `AppSemanticColors.opacityHint` | `0.3` | Hint text, placeholders |

### M3 ColorScheme Mapping

| M3 Role | Dark value | Light value |
|---------|-----------|-------------|
| `primary` | `accent` (`#2D9BD8`) | `accent` (`#1A7AAF`) |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `primaryContainer` | `primary` (`#1A3A8C`) | `primaryLight` (`#2A4FA8`) |
| `secondary` | same as `primary` | same as `primary` |
| `surface` | `#0D1B3E` | `#FFFFFF` |
| `onSurface` | `#FFFFFF` | `#0F172A` |
| `surfaceContainerHigh` | `#162347` | `#F1F5F9` |
| `surfaceContainerHighest` | `#11224D` | `#E2E8F0` |
| `onSurfaceVariant` | `#7FA8C9` | `#475569` |
| `outline` | `#1E3A6E` | `#CBD5E1` |
| `outlineVariant` | `#152850` | `#E2E8F0` |
| `error` | `#EF4444` | `#EF4444` |
| `tertiary` | `#EF4444` (like) | `#EF4444` (like) |
| `scrim` | `rgba(0,0,0,0.7)` | `rgba(0,0,0,0.5)` |

---

## 2. Typography (Material 3 TextTheme – Inter Variable)

| M3 Style | Size | Weight | Line Height | Usage |
|----------|------|--------|-------------|-------|
| `displaySmall` | 36sp | 700 | 1.2 | Hero text (Profile name) |
| `headlineMedium` | 28sp | 700 | 1.3 | Screen titles |
| `headlineSmall` | 24sp | 600 | 1.3 | Section headers |
| `titleLarge` | 22sp | 600 | 1.4 | Card title, answer preview |
| `titleMedium` | 16sp | 600 | 1.4 | Question content |
| `titleSmall` | 14sp | 600 | 1.4 | Tab labels, badge text |
| `bodyLarge` | 16sp | 400 | 1.5 | Answer body text |
| `bodyMedium` | 14sp | 400 | 1.5 | Secondary content, comments |
| `bodySmall` | 12sp | 400 | 1.5 | Timestamps, captions |
| `labelLarge` | 14sp | 600 | — | Button labels |
| `labelSmall` | 11sp | 500 | — | Chips, tags |

> Font family: `Inter` (Variable). Set via `AppTypography.fontFamily` in `_buildTheme`.

---

## 3. Spacing & Radius System

```dart
// core/values/app_spacing.dart
abstract final class AppSpacing {
  static const double xs     = 4;
  static const double smPlus = 6;  // avatar ring padding, etc.
  static const double sm     = 8;
  static const double md     = 12;
  static const double lg    = 16;
  static const double xl    = 24;
  static const double xxl   = 32;
}

abstract final class AppRadius {
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 999;  // Fully rounded (chips, avatars, buttons)
}

abstract final class AppIconSize {
  static const double sm = 16;
  static const double md = 18;
  static const double lg = 22;
  static const double xl = 28;
}
```

---

## 4. Duration Constants

```dart
// core/values/app_durations.dart
abstract final class AppDuration {
  static const fast       = Duration(milliseconds: 150);
  static const normal     = Duration(milliseconds: 250);
  static const slow       = Duration(milliseconds: 300);
  static const loadMoreMin = Duration(milliseconds: 1000); // min shimmer display time
}
```

---

## 5. Component Patterns

### Cards
- Background: `cs.surface`
- Border: 1px `cs.outline`
- Border radius: `AppRadius.lg` (16dp)
- Padding: `AppSpacing.lg` (16dp) all sides
- Elevation: 0 (border-only depth — no shadow)
- Tap: `InkWell` with `borderRadius: AppRadius.lg`

### Buttons
- **Primary (FilledButton):** `cs.primary` background, `cs.onPrimary` label, `AppRadius.full`, min height 52dp
- **Secondary (OutlinedButton):** Transparent bg, `cs.primary` border + text
- **Ghost (TextButton):** No border, `cs.primary` text
- **Danger:** `AppSemanticColors.error` background (delete/block actions)

### Input Fields
- `filled: true`, fill color `cs.surfaceContainerHigh`
- Border: `OutlineInputBorder` with `cs.outline`, radius `AppRadius.md`
- Focused border: `cs.primary`, width 2
- Error border: `AppSemanticColors.error`
- Hint color: `AppLightColors.inputHint` / `AppDarkColors.inputHint` (via theme)
- States: default / focused / error / disabled (opacity `AppSemanticColors.opacityDisabled`)

### Bottom Sheets
All bottom sheets use the shared `showAppBottomSheet` / `showAppScrollableSheet` helpers in `lib/app/global_widgets/layout/app_bottom_sheet.dart`.

- Background: `cs.surfaceContainerHigh` (via `BottomSheetThemeData`)
- Corner radius: `AppRadius.xl` (top only, via `BottomSheetThemeData`)
- Drag handle: system-provided via `showDragHandle: true` — **never draw manually**
- `useSafeArea: true`, `isScrollControlled: true`
- For scrollable content (comments): use `showAppScrollableSheet` with `DraggableScrollableSheet` — default `initialSize: 0.75`, `minSize: 0.4`, `maxSize: 0.95`
- For fixed content (action menus, share): use `showAppBottomSheet` + `AppBottomSheetBody`

---

## 6. Screen Specifications

---

### SCREEN 1: Profile Screen (Deep Link Landing Page)
**Route:** `/user/:userId` (outside shell — no bottom nav)
**Primary Actor:** Anonymous Sender
**Goal:** Understand who the Host is and submit a question anonymously.

```
┌─────────────────────────────────────┐
│  ← Back        [Share Icon]         │  ← AppBar (transparent, overlays hero)
│                                     │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  │    [Avatar 80dp circular]    │   │  ← Hero image with accent ring border
│  │                              │   │
│  │     Nguyen Van A             │   │  ← displaySmall, onSurface
│  │     HUMG Student             │   │  ← bodyMedium, onSurfaceVariant
│  │                              │   │
│  │  ┌────────┐  ┌────────────┐  │   │
│  │  │  24    │  │   312      │  │   │  ← Stats row (answers | likes)
│  │  │ Answers│  │   Likes    │  │   │
│  │  └────────┘  └────────────┘  │   │
│  └──────────────────────────────┘   │
│                                     │
│  ── Recent Answers ──────────────── │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  Q: "Best study tips?"       │   │  ← FeedItemCard (read-only preview)
│  │  A: "Start with Pomodoro..." │   │
│  │  ❤ 12   💬 3                 │   │
│  └──────────────────────────────┘   │
│                                     │
│  ── If viewing someone else's profile:
│  [Ask Question] bottom sheet opens  │  ← AskQuestionSheet (bottom sheet)
└─────────────────────────────────────┘
```

**Key UX Notes:**
- Question input is a **bottom sheet** (`AskQuestionSheet`) — not inline on the profile screen
- If user IS the Host (same UID): show Share Link card + Edit button instead of "Ask" CTA
- On question sent: `"Question sent!"` SnackBar (floating, `SnackBarBehavior.floating`)
- Rate limit hit: show error SnackBar with rate limit message

---

### SCREEN 2: Inbox Screen
**Route:** `/inbox`
**Primary Actor:** Host
**Goal:** Review received questions and respond to them.

```
┌─────────────────────────────────────┐
│  Inbox              [Avatar]        │  ← AppBar with user avatar top-right
│                                     │
│  ┌─────────────┬───────────────┐   │
│  │  Unanswered │   Answered    │   │  ← TabBar, accent underline indicator
│  │     (5)     │     (24)      │   │     Badge count on Unanswered tab
│  └─────────────┴───────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  🕐 2 hours ago              │   │  ← bodySmall, onSurfaceVariant
│  │  "What is your favorite      │   │  ← titleMedium, onSurface
│  │   subject in HUMG?"          │   │
│  │  [Reply]        [Delete]     │   │  ← TextButton primary / TextButton error
│  └──────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘

── On tap [Reply] → Answer Compose Screen ──────────────────
┌─────────────────────────────────────┐
│  ← Answer Question                  │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  📩 Question (read-only)     │   │  ← Surface card
│  │  "What is your favorite      │   │
│  │   subject in HUMG?"          │   │
│  └──────────────────────────────┘   │
│                                     │
│  Your Answer                        │
│  ┌──────────────────────────────┐   │
│  │  Write your reply...         │   │  ← Multiline text field
│  └──────────────────────────────┘   │
│                                     │
│  🌍 Publish to Public Feed    ◉    │  ← SwitchListTile, default ON
│                                     │
│  ┌──────────────────────────────┐   │
│  │        Post Answer           │   │  ← FilledButton, full width
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Key UX Notes:**
- Unanswered tab badge count syncs via `StreamProvider` (real-time)
- Swipe-to-delete with confirmation snackbar
- "Publish to Feed" toggle defaults to `true`

---

### SCREEN 3: Public Feed Screen
**Route:** `/` (Home, tab 0)
**Primary Actor:** Viewer (Guest or Logged-in)
**Goal:** Scroll through published Q&A, like and comment.

```
┌─────────────────────────────────────┐
│  AskmeHUMG       [🔍 Search] [🔔]  │  ← AppBar
│                                     │
│  ┌──────────────────────────────┐   │
│  │  [Avatar 40dp]  Nguyen Van A  │  ← Row: Avatar + name + timestamp + lock/more
│  │                  2 hours ago  │
│  │                    [🔒] [···] │
│  │                              │   │
│  │  [🔒] hỏi:                   │   │  ← AnonymousBadge + "hỏi:" label
│  │  "What is your favorite      │   │  ← bodyMedium, onSurfaceVariant, italic
│  │   subject in HUMG?"          │   │
│  │                              │   │
│  │  ▌ "I love Geology because.. │   │  ← Left border accent + bodyMedium (14sp)
│  │    it connects the classroom │   │
│  │    to the real world."       │   │
│  │                              │   │
│  │  ─────────────────────────   │   │
│  │  ❤ 24   💬 6   [Share]      │   │  ← Actions row
│  └──────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘

── Pull-to-refresh ────────────────────
  Shows full-screen shimmer (3 skeleton cards) for min 1s, then replaces with new data.

── Load more (scroll near bottom) ─────
  Spinner (CircularProgressIndicator, strokeWidth 2) centered below last item.
  Minimum display time: AppDuration.loadMoreMin (1s).

── End of feed ─────────────────────────
  Centered label text: l10n.feedReachedEnd

── On tap Like (guest) ─────────────────
  Bottom sheet: "Sign in to like answers" → [Sign in with Google]

── On tap Comment ──────────────────────
  DraggableScrollableSheet via showAppScrollableSheet:
  - initialSize: 0.75, minSize: 0.4, maxSize: 0.95
  - Comment list (StreamProvider) + anonymous-toggle input bar at bottom

── On tap [···] (More) ─────────────────
  showAppBottomSheet with AppBottomSheetBody:
  - 🚩 Report → TODO(phase-5): ReportBottomSheet (UC-5.1)
  - (Share and View profile: handled directly in FeedItemCard action row)
```

**Key UX Notes:**
- Old answers without `hostName`: show `l10n.feedFallbackHostName` ("HUMG Student")
- Old answers without `questionContent`: show `l10n.feedEmptyQuestion` in italic
- Tapping avatar navigates to `/user/{userId}` (full-screen, outside shell)

---

## 7. Navigation Structure

```
Shell (AppShell — StatefulShellRoute):
├── [🏠] Feed          → /         (tab 0 — always visible)
├── [📩] Inbox         → /inbox    (tab 1 — redirect to /login if unauthenticated)
├── [👤] Profile       → /me       (tab 2 — shows sign-in CTA if unauthenticated)
└── [⚙️] Settings      → /settings (tab 3 — account items hidden when guest)

Outside shell (no bottom nav):
  /splash          → SplashScreen
  /login           → LoginScreen
  /user/:userId    → ProfileScreen (other user / deep link)
  /inbox/answer/:questionId → AnswerComposeScreen
  /me/edit         → EditProfileScreen
  /admin           → AdminDashboardScreen
```

- Bottom nav uses `NavigationBar` (M3), `indicatorColor: cs.secondary.withValues(alpha: 0.15)` (secondary = accent in this theme)
- Tab switches use `Duration.zero` (instant, no animation)
- Tapping active tab scrolls to top (implemented via `goBranch(initialLocation: true)`)

### Profile tab (`/me`) — owner actions
- AppBar: `[✏️ Edit]` icon → push `/me/edit`
- AppBar: `[🔗 Share]` icon → `showAppBottomSheet` with `ShareCardWidget`

### Settings screen sections

| Section | Items | Auth required |
|---------|-------|---------------|
| Account | Edit Profile, HUMG Verification, Show real name toggle | ✅ |
| Notifications | New question (TODO v2 FCM), New comment (TODO v2 FCM) | ✅ |
| App | Language (vi/en/ja), Theme (light/dark/system via SegmentedButton), Clear cache | ❌ |
| About | Version (PackageInfo), Terms of Service, Privacy Policy | ❌ |
| Sign out | Button (error color) with confirmation dialog | ✅ |

### L10n keys for navigation labels

| Key | EN | VI | JA |
|-----|----|----|-----|
| `navFeed` | Feed | Feed | フィード |
| `navInbox` | Inbox | Hộp thư | 受信箱 |
| `navProfile` | Profile | Hồ sơ | プロフィール |
| `navSettings` | Settings | Cài đặt | 設定 |

---

## 8. Motion & Animation Guidelines

| Interaction | Animation | Duration | Library |
|-------------|-----------|----------|---------|
| Like button tap | Scale 1.0 → 1.3 → 1.0 + color fill | `AppDuration.fast` | `flutter_animate` |
| Feed refresh | Full-screen shimmer (min 1s) | `AppDuration.loadMoreMin` | — |
| Load more indicator | `CircularProgressIndicator` (strokeWidth 2) | — | — |
| Tab switch | Instant (Duration.zero) | — | GoRouter |
| Bottom sheet present/dismiss | System default slide-up | — | Flutter |
| Shimmer sweep | Horizontal shimmer sweep | loop | `shimmer` |
| Empty state | Loop Lottie animation (planned) | loop | `lottie` |

---

## 9. Error & Empty States

| State | Widget | Copy tone |
|-------|--------|-----------|
| Feed load error | `ErrorState` (icon + message + retry button) | Friendly: "Something went wrong. Try again?" |
| Feed empty | `EmptyState` (icon + message + retry) | Encouraging: `l10n.feedEmpty` |
| Feed end of list | Centered `labelMedium` text | Neutral: `l10n.feedReachedEnd` |
| Inbox empty (unanswered) | `EmptyState` | Positive: "No unanswered questions 🎉" |
| Network offline | `ErrorState` | Informative: detected via exception type |

---

## 10. Accessibility Checklist

### FeedItemCard
- [x] Like button: `Semantics(label: "{n} likes, liked" / "{n} likes", button: true)`
- [ ] Avatar: `Semantics(label: hostName)` — add to `AppAvatar`
- [ ] More button: `Semantics(label: "More options")` — add tooltip to `IconButton`
- [x] Touch targets: `visualDensity: VisualDensity.compact` on icon buttons (not zeroed out)
- [x] Like and Comment buttons use `InkWell` for visual tap feedback

### CommentSheet
- [ ] Input field hint is screen-reader accessible
- [ ] Send button disabled state announced
- [ ] Anonymous toggle has descriptive label

### General
- [ ] Color contrast ratio ≥ 4.5:1 for all text (verified for both light and dark)
- [ ] Anonymous badge uses icon + text (not color alone)
- [ ] Character counter (`0/300`) announced by screen readers
- [ ] Error messages displayed as text, not only red color
