# UC-1.3 – Verify HUMG Email (OTP)

> **Module:** Authentication
> **SRS Reference:** FR-02 (extended)
> **Actor:** Host (logged-in Google user, not yet HUMG-verified)
> **Priority:** High
> **Depends on:** UC-1.1 (must be signed in)

---

## 1. Pre-conditions

- User is signed in via Google (Firebase Auth session exists)
- `users/{uid}.isHumgVerified == false`
- Internet connection is available

---

## 2. Main Flow

```
1. User is redirected to /verify-humg-email screen after UC-1.1
2. User enters their @humg.edu.vn email address
3. User taps "Gửi mã OTP"
4. Client validates: email.endsWith('@humg.edu.vn') — if not: show inline error
5. Client calls Cloud Function: generateOtp({ email, uid })
6. Cloud Function:
   a. Generates 6-digit OTP
   b. Stores in Firestore otpRequests/{uid}:
      { email, otpHash (bcrypt), expiresAt (now+10min), attempts: 0 }
   c. Calls Resend API to send email to @humg.edu.vn
   d. Returns { success: true }
7. UI transitions to OTP input step (same screen, step 2)
8. User enters 6-digit OTP
9. User taps "Xác nhận"
10. Client calls Cloud Function: verifyOtp({ otp, uid })
11. Cloud Function:
    a. Reads otpRequests/{uid}
    b. Checks expiresAt > now — if expired: return error 'otp_expired'
    c. Checks attempts < 3 — if exceeded: return error 'otp_max_attempts'
    d. Compares bcrypt hash — if mismatch: increment attempts, return error 'otp_invalid'
    e. On match:
       - Updates users/{uid}: { isHumgVerified: true, humgEmail: email }
       - Deletes otpRequests/{uid}
       - Returns { success: true }
12. Client reads updated user doc, navigates to / (Feed)
```

---

## 3. Alternative Flows

### A – Invalid email format
```
A1. Client detects email does NOT end with @humg.edu.vn
A2. Show inline field error: l10n.otpErrorInvalidEmail
A3. No Cloud Function call made
```

### B – OTP expired
```
B1. Cloud Function returns error 'otp_expired'
B2. UI shows error + "Gửi lại mã" button
B3. User can restart from step 3
```

### C – Wrong OTP (attempts < 3)
```
C1. Cloud Function returns error 'otp_invalid'
C2. UI shows remaining attempts: l10n.otpErrorInvalidCode(remaining)
```

### D – Max attempts exceeded
```
D1. Cloud Function returns error 'otp_max_attempts'
D2. UI shows error + "Gửi lại mã" button (new OTP, resets attempts)
```

### E – Skip (Continue as guest)
```
E1. User taps "Bỏ qua, tiếp tục với tư cách khách"
E2. Navigate to / (Feed) — isHumgVerified remains false
E3. User can only view Feed, cannot use inbox/answer features
```

---

## 4. Database Impact

### Collection: `users`

| Operation | Condition | Fields Written |
|---|---|---|
| `update` | OTP verified successfully | `isHumgVerified: true`, `humgEmail: String` |

### Collection: `otpRequests`

| Operation | Condition | Fields Written |
|---|---|---|
| `set` | generateOtp called | `email`, `otpHash`, `expiresAt`, `attempts: 0` |
| `update` | Wrong OTP | `attempts: increment(1)` |
| `delete` | OTP verified successfully | entire doc |

```
otpRequests/{uid}:
  email      : String        — @humg.edu.vn address
  otpHash    : String        — bcrypt hash of 6-digit OTP
  expiresAt  : Timestamp     — now + 10 minutes
  attempts   : int           — max 3, then block until resend
```

---

## 5. Cloud Functions

### `generateOtp` (callable)
```typescript
// functions/src/auth/generateOtp.ts
export const generateOtp = onCall(async (request) => {
  const { email, uid } = request.data;
  // validate @humg.edu.vn
  // generate 6-digit OTP
  // bcrypt hash + store in otpRequests/{uid}
  // send via Resend API
});
```

### `verifyOtp` (callable)
```typescript
// functions/src/auth/verifyOtp.ts
export const verifyOtp = onCall(async (request) => {
  const { otp, uid } = request.data;
  // read otpRequests/{uid}
  // check expiry, attempts, hash
  // on success: update users/{uid}, delete otpRequests/{uid}
});
```

---

## 6. Files to Create / Modify

```
lib/app/modules/auth/
├── domain/
│   └── use_cases/
│       ├── generate_otp.dart          [CREATE]
│       └── verify_otp.dart            [CREATE]
├── data/
│   └── datasources/
│       └── otp_datasource.dart        [CREATE] — calls Cloud Functions
└── presentation/
    ├── screens/
    │   └── verify_humg_email_screen.dart  [CREATE] route /verify-humg-email
    └── widgets/
        ├── email_input_step.dart          [CREATE]
        └── otp_input_step.dart            [CREATE] — 6 individual digit boxes

lib/config/router.dart  [MODIFY] — add /verify-humg-email route + guard
```

---

## 7. UI Screens

### Step 1 — Email Input
```
┌─────────────────────────────┐
│  ← back                     │
│                             │
│  [envelope icon 64px]       │
│  Xác minh email HUMG        │  ← titleLarge
│  Nhập email @humg.edu.vn    │  ← bodyMedium, textSecondary
│  để mở khóa tính năng Host  │
│                             │
│  ┌────────────────────────┐ │
│  │ email@humg.edu.vn      │ │  ← TextField, keyboard: emailAddress
│  └────────────────────────┘ │
│                             │
│  [  Gửi mã OTP  ]          │  ← FilledButton, full-width
│                             │
│  Bỏ qua, tiếp tục           │  ← TextButton, textSecondary
│  với tư cách khách          │
└─────────────────────────────┘
```

### Step 2 — OTP Input
```
┌─────────────────────────────┐
│  ← back (về step 1)         │
│                             │
│  Nhập mã xác nhận           │  ← titleLarge
│  Mã 6 số đã gửi đến         │  ← bodyMedium
│  email@humg.edu.vn          │  ← accent color
│                             │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ │  ← 6 OtpDigitBox
│  │  │ │  │ │  │ │  │ │  │ │  │ │    auto-focus next on input
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ │
│                             │
│  [  Xác nhận  ]            │  ← FilledButton, enabled khi đủ 6 số
│                             │
│  Không nhận được mã?        │
│  Gửi lại (59s)              │  ← countdown timer, TextButton
└─────────────────────────────┘
```

---

## 8. Router Guard Logic

```dart
// Sau khi sign-in thành công:
// authUser != null && isHumgVerified == false → /verify-humg-email
// authUser != null && isHumgVerified == true  → /
// authUser == null                            → /login
```

---

## 9. Resend Email Template

**Subject:** `[AskmeHUMG] Mã xác minh email của bạn`

**Body:**
```
Xin chào,

Mã xác minh AskmeHUMG của bạn là:

  ██████
  123456
  ██████

Mã có hiệu lực trong 10 phút.
Không chia sẻ mã này với bất kỳ ai.

Nếu bạn không yêu cầu mã này, hãy bỏ qua email này.

— Đội ngũ AskmeHUMG
```

---

## 10. Acceptance Criteria

- [ ] Only `@humg.edu.vn` email accepted in input field (client-side)
- [ ] OTP sent within 5 seconds of request
- [ ] OTP expires after 10 minutes
- [ ] Max 3 wrong attempts before requiring resend
- [ ] Resend cooldown: 60 seconds
- [ ] On success: `users/{uid}.isHumgVerified = true`, `humgEmail` set
- [ ] `otpRequests/{uid}` deleted after successful verification
- [ ] Skip option available — user enters app as guest (limited features)
- [ ] All strings via `context.l10n.*`
- [ ] No `print()` — logger only
