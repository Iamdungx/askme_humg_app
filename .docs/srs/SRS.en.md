# AskmeHUMG – Software Requirements Specification (SRS)

> **Version:** 2.2 | **Last Updated:** 2026-03-23

---

## Table of Contents

1. [Introduction](#1-introduction)
   - 1.1 [Purpose](#11-purpose)
   - 1.2 [Scope](#12-scope)
   - 1.3 [Definitions](#13-definitions)
2. [Overall Description](#2-overall-description)
   - 2.1 [Product Perspective](#21-product-perspective)
   - 2.2 [User Classes](#22-user-classes)
   - 2.3 [Operating Environment](#23-operating-environment)
3. [Functional Requirements](#3-functional-requirements)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [System Architecture](#5-system-architecture)
6. [Data Model Overview](#6-data-model-overview)
7. [Constraints](#7-constraints)
8. [Future Enhancements](#8-future-enhancements)
9. [Conclusion](#9-conclusion)

---

## 1. Introduction

### 1.1 Purpose

This document describes the Software Requirements Specification (SRS) for **AskmeHUMG**, a mobile application that enables anonymous Q&A interaction among students of HUMG (Hanoi University of Mining and Geology).

The purpose of this system is to provide a safe, anonymous, and interactive platform for students to share questions, feedback, and experiences.

### 1.2 Scope

AskmeHUMG is a mobile application developed using **Flutter** that allows:

- Anonymous question submission to any registered student
- Students to answer received questions publicly
- Community interaction (like, comment)
- Content moderation to ensure a healthy environment
- Shareable deep links for Host users to receive questions via social media

The system is designed for internal student use and does **not** replace official academic information systems.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| Anonymous Sender | A user who sends a question without revealing identity |
| Host User | A logged-in student (`@humg.edu.vn`) who receives and answers questions |
| Feed | Public list of published answered questions |
| Chronological sort | Default ordering: newest publication first, by `createdAt` |
| Hot / trending ranking | Ordering that boosts engagement while decaying by age; conceptually aligned with Reddit-style “hot” (planned implementation) |
| AI feed labels | Optional category/tags on published answers for topic filtering on the Feed |
| Moderation | Process of filtering or removing inappropriate content |
| Deep Link | A unique URL that opens the app directly to a Host's profile page |
| Rate Limiting | A mechanism to restrict the number of requests a client can make in a time window |
| App Check | Firebase service that verifies requests originate from a legitimate app instance |

---

## 2. Overall Description

### 2.1 Product Perspective

AskmeHUMG is a standalone mobile application using:

- **Flutter** (Frontend)
- **Firebase** (Backend services)

The system follows a client-server architecture with real-time database support. Anonymous submissions are rate-limited and request authenticity is verified (target: App Check and/or server API — see FR-01).

### 2.2 User Classes

| User Type | Description |
|---|---|
| Anonymous Sender | Sends anonymous questions without logging in |
| Student (Host) | Logs in with `@humg.edu.vn` Google account, receives and answers questions |
| Viewer | Views the public feed and interacts with content |
| Admin | Manages reports and inappropriate content |

### 2.3 Operating Environment

- Android 8.0+
- iOS 13+
- Internet connection required
- Firebase Cloud Backend

---

## 3. Functional Requirements

### FR-01: Anonymous Question Submission

**Description:** Any user (without login) can send an anonymous question to a registered Host student.

**Inputs:**
- Question content (max 300 characters)

**Processing:**
1. Validate content length and format
2. Filter inappropriate words via keyword list
3. Verify request authenticity (design target: **Firebase App Check**; implementation may use an HTTPS API with equivalent controls)
4. Apply **rate limiting**: a maximum of **5 questions per device per hour** (server-side — Cloud Functions or deployed HTTP service)
5. Save to the `questions` collection

**Outputs:**
- Confirmation message to sender

**Security note:** No identity or device fingerprint is stored. App Check tokens are ephemeral and are not linked to any personal data.

---

### FR-02: User Authentication

**Description:** Any Google account may sign in to the application. Full Host features (receiving questions, answering, publishing to Feed) require additional HUMG identity verification.

**Two-tier authentication model:**
- **Tier 1 — Google Sign-In:** Any Google account can sign in. A `users` document is created on first login. The user can **browse the public Feed**. **Likes and comments** require **Tier 2** (`isHumgVerified == true`).
- **Tier 2 — HUMG Verification:** Required for full **Host** features and for **like/comment** on the Feed. The user verifies ownership of a `@humg.edu.vn` email address. Upon success, `isHumgVerified: true` and `humgEmail` are saved to the `users` document.

**Processing (Tier 1):**
1. User initiates Google Sign-In
2. Firebase Auth returns the authenticated Google account
3. On first login, a new document is created in the `users` collection with `isHumgVerified: false`
4. Session is established and the user is redirected to the home screen

**Processing (Tier 2 — HUMG Verification):**
1. User submits their `@humg.edu.vn` email address in the Settings screen
2. System sends a 6-digit OTP to the submitted email via Gmail SMTP (`mailer` package, plain-text body)
3. User enters the OTP; system validates against the `otpRequests` collection
4. On success: `isHumgVerified: true` and `humgEmail` written to the `users` document

---

### FR-03: View Received Questions

**Description:** Logged-in Host users can see the list of anonymous questions sent to them.

**Display:**
- Question content
- Timestamp
- Status (`answered` / `unanswered`)

---

### FR-04: Answer Question

**Description:** Host users can respond to received questions.

**Processing:**
1. Save the answer to the `answers` collection
2. Option to publish the answer publicly on the Feed

---

### FR-05: Public Feed

**Description:** Display published answers (`isPublished == true`) from Hosts.

**Display (each item):**
- Host name & avatar (verified badge when applicable)
- Question text
- Answer text
- Like count
- Comment count
- (Optional) AI-assigned category/tags for topic hints

**Sorting & filtering — current release (v1):**
- **Default:** Sort by answer publication time — **`createdAt` descending** (newest first).
- **Pagination:** Cursor-based (`limit`, `startAfterDocument`), no duplicate rows when loading more.
- **Optional topic filter:** When the user selects a category or tag, the query adds predicates on AI classification fields (e.g. `aiCategory`, `aiTagIds`) — requires matching Firestore composite indexes when enabled.

**Planned — “trending / hot” ranking (future):**
- Additional sort mode (alongside chronological): combine **engagement** (e.g. `likeCount`, `commentCount`, or a weighted score) with **time decay** from `createdAt`, following Reddit-style “hot” principles (log-scaled score + time component) so old posts do not rank forever.
- Implementation approach (target): denormalized **rank score** (e.g. `hotScore`) on `answers`, updated on interaction or on a schedule; query with `orderBy` and composite indexes.

**Note:** Until `hotScore` (or equivalent) is implemented, only **`createdAt`** ordering applies as in “current release”.

---

### FR-06: Like System

**Description:** Logged-in users can like a published answer.

**Constraints:**
- One like per user per answer, enforced by storing the user's ID in the `likedBy` array field of the answer document
- The UI reflects the user's current like state (active/inactive) on load

---

### FR-07: Comment System

**Description:** Users can comment on published answers, either anonymously or publicly.

---

### FR-08: Report Content

**Description:** Logged-in users can report inappropriate answers or comments for admin review. Each report is stored as a dedicated document in the `reports` collection with a status of `pending`.

---

### FR-09: Content Moderation

**Description:** The system filters inappropriate content using:
- Automatic keyword filtering (client-side pre-check + Cloud Functions server-side enforcement)
- Admin manual review via the `reports` collection

---

### FR-10: User Profile

**Description:** Display a Host user's public information:
- Display name (or anonymous handle if the user has disabled real name display)
- Avatar
- Number of published answers
- Total likes received

**Privacy control:** A Host may toggle "Show real name on profile" in Settings. When disabled, their real name is replaced with a generic placeholder on the public Feed and profile page. This preference is stored in the `users` document (`showRealName` field).

---

### FR-11: Shareable Deep Link

**Description:** Every Host user can generate and share a unique deep link that, when opened, navigates directly to their profile page where anonymous questions can be submitted.

**Processing:**
1. The system constructs a unique URL for the Host: `https://askme-humg-app.web.app/user/{userId}`
2. Host can share this link or a visual QR card (image with the link) to external platforms (Facebook, Instagram Stories, etc.)
3. When a recipient opens the link on a device with the app installed, the app opens directly to the Host's profile (handled by `app_links` + Android App Links / iOS Universal Links)
4. If the app is not installed, the link redirects to an app store or a mobile web fallback page

**Outputs:**
- Shareable URL copied to clipboard
- Option to export as a shareable image card

---

## 4. Non-Functional Requirements

### NFR-01: Anonymity

- No sender identity stored or displayed
- No public IP address or device fingerprint tracking
- Firebase App Check tokens used for verification are ephemeral and not tied to any personal identifier

### NFR-02: Performance

- Response time under **2 seconds** for all primary actions
- Smooth, paginated feed loading (cursor-based pagination via Firestore)

### NFR-03: Security

- **Firebase Authentication** with enforced `@humg.edu.vn` domain restriction
- **Firebase App Check** (using DeviceCheck on iOS, Play Integrity on Android) to authenticate all anonymous submission requests
- **Cloud Functions rate limiting**: maximum 5 anonymous submissions per device per hour
- Firestore security rules to prevent unauthorized read/write access
- All client-server communication enforced over **HTTPS**

### NFR-04: Usability

- Simple and intuitive UI
- Minimal user steps per action
- Beginner-friendly design

### NFR-05: Scalability

- Support concurrent users without performance degradation
- Expandable Firestore data model designed for horizontal scaling

---

## 5. System Architecture

### Frontend

- **Framework:** Flutter (Dart)
- **State Management:** **Riverpod** (flutter_riverpod)

> Riverpod is chosen for its compile-time safety, testability, and first-class support for asynchronous Firebase streams. GetX is not used in this project.

### Backend

| Service | Role |
|---|---|
| **Firebase Authentication** | User login & identity |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Storage** | Avatar and media storage |
| **Cloud Functions** | (Optional deployment) Rate limiting, server-side moderation; anonymous submit may be handled by HTTP API instead |
| **HTTP service (e.g. Vercel)** | Anonymous submission and/or AI classification endpoints when configured |
| **Firebase App Check** | Attestation of legitimate app instances for anonymous endpoints |
| **`app_links` package** | Deep link handling for `askme-humg-app.web.app/user/{userId}` — replaces deprecated Firebase Dynamic Links |

> **Note:** Firebase Dynamic Links was deprecated by Google in August 2025. The app uses the `app_links` package for deep link interception combined with native platform configuration (Android App Links / iOS Universal Links) pointing to `askme-humg-app.web.app`.

### Architecture Diagram (High-level)

```
Flutter App (Riverpod)
    │
    ├── Firebase Auth          (Login · any Google account)
    ├── Firebase App Check     (Bot prevention · anonymous submissions)
    ├── Cloud Firestore        (Data storage · real-time sync)
    ├── Firebase Storage       (Avatars · media)
    ├── Cloud Functions        (Rate limiting · OTP · server moderation)
    └── app_links + native     (Deep link routing: askme-humg-app.web.app/user/{userId})
```

---

## 6. Data Model Overview

### Collection: `users`

| Field | Type | Description |
|---|---|---|
| `userId` | String | Unique user identifier (Firebase Auth UID) |
| `name` | String | Display name (from Google account) |
| `avatar` | String (URL) | Avatar image URL |
| `email` | String | Google account email (any domain) |
| `role` | String | `user` (default) or `admin` |
| `createdAt` | Timestamp | Account creation time |
| `isBlocked` | Boolean | Whether the account is suspended by Admin |
| `isHumgVerified` | Boolean | Whether the user has verified a `@humg.edu.vn` email |
| `humgEmail` | String (nullable) | The verified HUMG email address |
| `showRealName` | Boolean | Whether the user's real name is shown publicly (default: `true`) |

### Collection: `questions`

| Field | Type | Description |
|---|---|---|
| `questionId` | String | Unique question identifier |
| `toUserId` | String | Target Host user ID |
| `content` | String | Question text (max 300 chars) |
| `createdAt` | Timestamp | Submission timestamp |
| `status` | String | `unanswered` or `answered` |

### Collection: `answers`

| Field | Type | Description |
|---|---|---|
| `answerId` | String | Unique answer identifier |
| `questionId` | String | Reference to parent question |
| `userId` | String | Host user who answered |
| `content` | String | Answer text |
| `createdAt` | Timestamp | Answer timestamp |
| `likeCount` | Number | Cached total like count (for display performance) |
| `likedBy` | Array\<String\> | List of `userId`s who liked this answer — enforces one-like-per-user rule |
| `commentCount` | Number | Cached total comment count (for display performance) |
| `isPublished` | Boolean | Whether the answer is visible on the public Feed |
| `aiCategory` | String (nullable) | Main category from AI classification (when enabled) |
| `aiTags` | Array\<String\> | Display labels for tags (optional) |
| `aiTagIds` | Array\<String\> | Tag IDs for `array-contains` feed filtering |
| `aiClassificationStatus` | String (nullable) | Pipeline status (e.g. `done`, `failed`, `pending`) |
| `hotScore` | Number (nullable) | **Planned:** denormalized trending rank for `orderBy` (not required in v1) |

> **Design note:** Both `likeCount` and `commentCount` are denormalized caches updated atomically via `FieldValue.increment()`. For likes, the `likedBy` array is updated in the same operation. This avoids sub-collection reads for counts on every feed item render. Both updates use `WriteBatch` to ensure atomicity. AI fields and `hotScore` are optional extensions (UC-4.1, trending roadmap).

### Collection: `comments`

| Field | Type | Description |
|---|---|---|
| `commentId` | String | Unique comment identifier |
| `answerId` | String | Reference to parent answer |
| `userId` | String (nullable) | Commenter's user ID; `null` if anonymous |
| `content` | String | Comment text |
| `isAnonymous` | Boolean | Whether comment is displayed anonymously |
| `createdAt` | Timestamp | Comment timestamp |

### Collection: `reports`

| Field | Type | Description |
|---|---|---|
| `reportId` | String | Unique report identifier |
| `targetId` | String | ID of the reported content (answer or comment ID) |
| `targetType` | String | Type of reported content: `answer` or `comment` |
| `reportedBy` | String | `userId` of the user who submitted the report |
| `reason` | String | Report reason: `inappropriate_language`, `spam`, `misinformation`, `other` |
| `status` | String | `pending`, `resolved_removed`, or `resolved_dismissed` |
| `createdAt` | Timestamp | Report submission timestamp |
| `resolvedAt` | Timestamp (nullable) | Timestamp when Admin acted on the report |

### Collection: `otpRequests`

Per UC-1.3: the client generates an OTP, hashes it with SHA-256, writes `otpRequests/{uid}`, and sends email via Gmail SMTP (`mailer`). Successful verification updates `users` and removes the OTP request.

| Field | Type | Description |
|---|---|---|
| `email` | String | The `@humg.edu.vn` email the OTP was sent to |
| `otpHash` | String | SHA-256 hash of the OTP (plain-text OTP never stored) |
| `expiresAt` | Timestamp | OTP expiry time (10 minutes from generation) |
| `attempts` | Number | Failed attempt count (max 3 before lockout) |

---

## 7. Constraints

- Internet connection is required to use the application
- Any Google account may sign in; Host features (receiving questions, answering, publishing) require additional `@humg.edu.vn` HUMG email verification (UC-1.3)
- No direct messaging feature between users
- No real-time chat system
- Anonymous question submissions are rate-limited to **5 per device per hour**

---

## 8. Future Enhancements

### Version 2 (Planned)

- **Push notifications** for new received questions and new comments on answers — via Firebase Cloud Messaging (FCM). UI placeholder already exists in the Settings screen; backend implementation deferred pending FCM setup.
- **Avatar & display name editing** — upload new avatar to Firebase Storage and update `name` in the `users` document. Edit Profile screen is a placeholder pending v2.
- **`showRealName` Firestore persistence** — currently in-memory; v2 will persist the toggle to `users.showRealName`.

### Version 3+ (Future Consideration)

- **Feed — full “hot” trending:** implement FR-05 trending mode (`hotScore`, UI toggle New / Trending if needed)
- AI-based answer suggestion using an LLM API
- Analytics dashboard for popular questions and trending topics
- Trend analysis segmented by faculty or department
- Integration with HUMG's official student information systems

---

## 9. Conclusion

AskmeHUMG aims to create a safe, spam-resistant, and anonymous communication platform exclusively for HUMG students. By enforcing institutional email authentication, Firebase App Check, rate limiting, and structured content moderation, the application balances open interaction with meaningful security and privacy guarantees.
