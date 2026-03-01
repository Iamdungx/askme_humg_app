# AskmeHUMG – UI/UX Specifications

> **Design System:** Material 3
> **Font:** Inter (Variable)
> **Theme:** Dark-first (matches `AppColors` – HUMG navy identity)
> **Updated:** 26-02-2026

---

## 1. Color Palette (Material 3 ColorScheme)

All colors derive from the existing `AppColors` class. Below is the mapping to Material 3 roles:

| M3 Role | Token | Hex | Usage |
|---------|-------|-----|-------|
| `primary` | `AppColors.primary` | `#1A3A8C` | Buttons, selected tabs, active states |
| `onPrimary` | white | `#FFFFFF` | Text/icons on primary |
| `secondary` | `AppColors.accent` | `#2D9BD8` | CTAs, links, FAB, active indicators |
| `onSecondary` | white | `#FFFFFF` | Text/icons on secondary |
| `surface` | `AppColors.surface` | `#0D1B3E` | Cards, bottom sheets, dialogs |
| `surfaceContainerHigh` | `AppColors.surfaceElevated` | `#162347` | Modals, drawers |
| `background` | `AppColors.background` | `#0A0D1A` | App scaffold background |
| `onBackground` | `AppColors.textPrimary` | `#FFFFFF` | Primary text |
| `onSurface` | `AppColors.textPrimary` | `#FFFFFF` | Text on cards |
| `onSurfaceVariant` | `AppColors.textSecondary` | `#7FA8C9` | Captions, metadata, timestamps |
| `outline` | `AppColors.border` | `#1E3A6E` | Card borders, dividers, input borders |
| `error` | `AppColors.error` | `#EF4444` | Validation errors |
| `tertiary` | `AppColors.like` | `#EF4444` | Like/heart icon (filled) |

### ColorScheme Definition

```dart
// core/values/app_theme.dart
static ColorScheme get darkColorScheme => ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  secondary: AppColors.accent,
  onSecondary: Colors.white,
  surface: AppColors.surface,
  onSurface: AppColors.textPrimary,
  background: AppColors.background,
  onBackground: AppColors.textPrimary,
  error: AppColors.error,
  onError: Colors.white,
  outline: AppColors.border,
  surfaceVariant: AppColors.surfaceElevated,
  onSurfaceVariant: AppColors.textSecondary,
);
```

---

## 2. Typography (Material 3 TextTheme – Inter Variable)

| M3 Style | Size | Weight | Usage |
|----------|------|--------|-------|
| `displaySmall` | 36sp | 700 | Hero text (Profile name) |
| `headlineMedium` | 28sp | 700 | Screen titles |
| `headlineSmall` | 24sp | 600 | Section headers |
| `titleLarge` | 22sp | 600 | Card title, answer preview |
| `titleMedium` | 16sp | 600 | Question content |
| `titleSmall` | 14sp | 600 | Tab labels, badge text |
| `bodyLarge` | 16sp | 400 | Answer body text |
| `bodyMedium` | 14sp | 400 | Secondary content, comments |
| `bodySmall` | 12sp | 400 | Timestamps, captions |
| `labelLarge` | 14sp | 600 | Button labels |
| `labelSmall` | 11sp | 500 | Chips, tags |

---

## 3. Spacing & Radius System

```dart
// core/values/app_spacing.dart
abstract final class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 999;  // Fully rounded (chips, avatars)
}
```

---

## 4. Component Patterns

### Cards
- Background: `AppColors.surface` (`#0D1B3E`)
- Border: 1px `AppColors.border` (`#1E3A6E`)
- Border radius: `AppRadius.lg` (16dp)
- Padding: `AppSpacing.lg` (16dp) all sides
- Elevation: 0 (border-only depth — no shadow)

### Buttons
- **Primary (FilledButton):** `AppColors.accent` background, white label, radius `AppRadius.full`
- **Secondary (OutlinedButton):** Transparent bg, `AppColors.accent` border + text
- **Ghost (TextButton):** No border, `AppColors.textSecondary` text
- **Danger:** `AppColors.error` background (for delete/block actions)

### Input Fields
- `InputDecoration` with `filled: true`, fill color `AppColors.surfaceElevated`
- Border: `OutlineInputBorder` with `AppColors.border`
- Focused border: `AppColors.accent`
- Counter text for 300-char limit on question input

---

## 5. Screen Specifications

---

### SCREEN 1: Profile Screen (Deep Link Landing Page)
**Route:** `/u/:userId`
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
│  │     Nguyen Van A             │   │  ← displaySmall, textPrimary
│  │     HUMG Student             │   │  ← bodyMedium, textSecondary
│  │                              │   │
│  │  ┌────────┐  ┌────────────┐  │   │
│  │  │  24    │  │   312      │  │   │  ← Stats row (answers | likes)
│  │  │ Answers│  │   Likes    │  │   │  ← titleMedium bold / bodySmall label
│  │  └────────┘  └────────────┘  │   │
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  💬 Ask me anything...       │   │  ← Question input field (max 300 chars)
│  │                              │   │     filled, multiline, accent focus border
│  │                    [0/300]   │   │  ← char counter, bodySmall, textSecondary
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │   🔒 Send Anonymously        │   │  ← FilledButton, accent color, full width
│  └──────────────────────────────┘   │     icon: lock_outline
│                                     │
│  ─────── Recent Answers ──────────  │  ← Section header, titleSmall, textSecondary
│                                     │
│  ┌──────────────────────────────┐   │
│  │  Q: "Best study tips?"       │   │  ← FeedItemCard (read-only preview)
│  │  A: "Start with Pomodoro..." │   │
│  │  ❤ 12   💬 3                 │   │
│  └──────────────────────────────┘   │
│  [Load more...]                     │
└─────────────────────────────────────┘
```

**Key UX Notes:**
- Anonymous badge always visible: `"Your identity is hidden 🔒"` — small chip below send button
- On success: Lottie confetti animation + `"Question sent! 🎉"` snackbar
- Rate limit hit: Show warning chip `"You can send 5 questions per hour"`
- If user IS the Host (same UID): show "Share Link" card instead of question input

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
│  ─ TAB: Unanswered ─────────────── │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  🕐 2 hours ago              │   │  ← bodySmall, textSecondary
│  │                              │   │
│  │  "What is your favorite      │   │  ← titleMedium, textPrimary
│  │   subject in HUMG?"          │   │
│  │                              │   │
│  │  [Reply]        [Delete]     │   │  ← TextButton accent / TextButton error
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  🕐 5 hours ago              │   │
│  │  "How do you balance study   │   │
│  │   and social life?"          │   │
│  │  [Reply]        [Delete]     │   │
│  └──────────────────────────────┘   │
│                                     │
│  ─ Empty state (all answered) ─── │
│  [Illustration: empty mailbox]      │  ← Lottie or SVG empty state
│  "No unanswered questions 🎉"       │
│                                     │
└─────────────────────────────────────┘

── On tap [Reply] → Answer Compose Screen ──────────────────
┌─────────────────────────────────────┐
│  ← Answer Question                  │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  📩 Question                 │   │  ← Surface card, read-only
│  │  "What is your favorite      │   │
│  │   subject in HUMG?"          │   │
│  └──────────────────────────────┘   │
│                                     │
│  Your Answer                        │  ← labelLarge
│  ┌──────────────────────────────┐   │
│  │  Write your reply...         │   │  ← Multiline text field
│  │                              │   │
│  └──────────────────────────────┘   │
│                                     │
│  ┌────────────────────────────┐     │
│  │  🌍 Publish to Public Feed │ ◉  │  ← SwitchListTile, default ON
│  └────────────────────────────┘     │
│                                     │
│  ┌──────────────────────────────┐   │
│  │        Post Answer           │   │  ← FilledButton, full width, accent
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Key UX Notes:**
- Unanswered tab shows badge count (red dot with number)
- Swipe-to-delete gesture on question cards (with confirmation dialog)
- "Publish to Feed" toggle defaults to `true` — Host can opt out
- Success: navigates back to Inbox with answered tab highlighted

---

### SCREEN 3: Public Feed Screen
**Route:** `/` (Home)
**Primary Actor:** Viewer (Guest or Logged-in)
**Goal:** Scroll through published Q&A, like and comment.

```
┌─────────────────────────────────────┐
│  AskMe HUMG          [Search] [🔔]  │  ← AppBar, logo/title left, icons right
│                                     │
│  ┌──────────────────────────────┐   │
│  │  ┌──────────┐  Nguyen Van A  │   │  ← Row: Avatar (40dp) + name + timestamp
│  │  │ [Avatar] │  2 hours ago   │   │
│  │  └──────────┘                │   │
│  │                              │   │
│  │  📩 Anonymous asked:         │   │  ← labelSmall chip, accent color
│  │  "What is your favorite      │   │  ← bodyMedium, textSecondary, italic
│  │   subject in HUMG?"          │   │
│  │                              │   │
│  │  💬 Nguyen Van A answered:   │   │  ← labelSmall, textSecondary
│  │  "I love Geology because...  │   │  ← bodyLarge, textPrimary
│  │   it connects the classroom  │   │
│  │   to the real world."        │   │
│  │                              │   │
│  │  ─────────────────────────   │   │  ← Thin divider
│  │  ❤ 24   💬 6   [···]        │   │  ← Actions row: Like | Comment | More
│  └──────────────────────────────┘   │  ← like in AppColors.like if liked
│                                     │
│  ┌──────────────────────────────┐   │
│  │  [Avatar]  Tran Thi B        │   │  ← Next feed item
│  │  3 hours ago                 │   │
│  │  📩 "Best study resources?"  │   │
│  │  💬 "Check the library..."   │   │
│  │  ❤ 8    💬 2   [···]        │   │
│  └──────────────────────────────┘   │
│                                     │
│  [Loading shimmer card...]          │  ← Shimmer skeleton during pagination load
│                                     │
└─────────────────────────────────────┘

── On tap Like (if not logged in) ─────
  Bottom sheet: "Sign in to like answers"  → [Sign in with Google] button

── On tap Comment ──────────────────────
  Bottom sheet (DraggableScrollableSheet)
  ┌──────────────────────────────────┐
  │  Comments (6)             [✕]    │
  │  ─────────────────────────────   │
  │  [Avatar] User A  "Great post!"  │  ← Comment tile, bodyMedium
  │           1h ago                 │  ← bodySmall, textSecondary
  │  [🔒 Anon] "I agree!"            │  ← Anonymous badge instead of avatar
  │           30m ago                │
  │  ─────────────────────────────   │
  │  [🔒] Write a comment...  [Send] │  ← Input bar + anonymous toggle
  └──────────────────────────────────┘

── On tap [···] (More) ─────────────────
  Bottom sheet:
  - 🚩 Report this answer   → UC-5.1
  - 🔗 Share link
  - 👤 View profile
```

**Key UX Notes:**
- Feed is infinite scroll — shimmer skeleton shown for next page loading
- Like button animates: scale bounce + color fill using `flutter_animate`
- Guest viewers can read and comment (anonymous), but must sign in to like
- Tapping Avatar navigates to `/u/{userId}` (Profile Screen)
- "Report" bottom sheet shows reason chips: `Spam`, `Offensive Language`, `Misinformation`, `Other`
- Empty feed: Lottie empty state animation + "Be the first to answer something!" CTA

---

## 6. Navigation Structure

```
Bottom Navigation Bar (4 tabs):
├── [🏠] Feed          → /         (tab 0 — always visible)
├── [📩] Inbox         → /inbox    (tab 1 — redirect to /login if unauthenticated)
├── [👤] Profile       → /me       (tab 2 — shows sign-in CTA if unauthenticated)
└── [⚙️] Settings      → /settings (tab 3 — account items hidden when guest)
```

- Bottom nav uses `NavigationBar` (Material 3), `indicatorColor: AppColors.accent` with low opacity
- Floating Action Button on Feed: `"Share my link"` — only visible when logged in
- Full-screen routes rendered **outside** the shell (no bottom nav): `/login`, `/splash`, `/u/:userId` (other user), `/admin`, `/inbox/answer/:questionId`, `/me/edit`
- Implementation: GoRouter `StatefulShellRoute` wrapping an `AppShell` widget (`lib/app/core/widgets/app_shell.dart`)
- See `ARCHITECTURE.md` → "Shell Navigation" section for route tree and edge cases

### Profile tab (`/me`) — owner actions
- AppBar shows `[✏️ Edit]` icon → push `/me/edit` (full-screen, outside shell)
- AppBar shows `[🔗 Share]` icon → opens ShareCardWidget bottom sheet

### Settings screen (`/settings`) — sections

| Section | Items | Auth required |
|---------|-------|---------------|
| Account | Edit Profile, HUMG Verification, Show real name toggle | ✅ |
| Notifications | New question (TODO v2 FCM), New comment (TODO v2 FCM) | ✅ |
| App | Language (vi/en/ja), Theme (light/dark/system), Clear cache | ❌ |
| About | Version, Terms of Service, Privacy Policy | ❌ |
| Sign out | Button (red) | ✅ |

### L10n keys for navigation labels

| Key | EN | VI | JA |
|-----|----|----|-----|
| `navFeed` | Feed | Feed | フィード |
| `navInbox` | Inbox | Hộp thư | 受信箱 |
| `navProfile` | Profile | Hồ sơ | プロフィール |
| `navSettings` | Settings | Cài đặt | 設定 |

---

## 7. Motion & Animation Guidelines

| Interaction | Animation | Library |
|-------------|-----------|---------|
| Like button tap | Scale 1.0 → 1.3 → 1.0 + color fill | `flutter_animate` |
| Question sent success | Confetti burst | `lottie` |
| Screen transitions | Shared-axis (horizontal) | `go_router` + `animations` |
| Card appear on feed | Fade + slide up (stagger 50ms per item) | `flutter_animate` |
| Empty state | Loop Lottie animation | `lottie` |
| Shimmer loading | Horizontal shimmer sweep | `shimmer` |

---

## 8. Accessibility Checklist

- [ ] All interactive elements have `Semantics` labels
- [ ] Minimum touch target: 48×48dp
- [ ] Color contrast ratio ≥ 4.5:1 for all text on backgrounds
- [ ] Anonymous badge has icon + text (not color alone to convey meaning)
- [ ] Character counter (`0/300`) is announced by screen readers
- [ ] Error messages are displayed as text, not only with red color
