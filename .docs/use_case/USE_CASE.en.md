# AskmeHUMG - Use Cases Specification

> **Document for AI Assistant (Cursor/Copilot)**
> When implementing a feature, reference the corresponding Use Case code (e.g., UC-1.1) in this document to ensure correct Business Logic flow and Database operations.

---

## 1. Actors

1. **Anonymous Sender:** A user who is not logged in, accessing via a Deep Link.
2. **Host (Student):** A HUMG student logged in with an `@humg.edu.vn` email. Has a personal profile page to receive questions.
3. **Viewer:** Any user browsing the Public Feed. Two sub-types:
   - *Logged-in Viewer:* An authenticated student (essentially a Host browsing the Feed).
   - *Guest Viewer:* An unauthenticated visitor.
4. **Admin:** A user granted admin privileges via Firebase Custom Claims (`admin: true`) or a `role: 'admin'` field in the `users` collection document.

---

## 2. Use Cases by Module

### MODULE 1: AUTHENTICATION

#### UC-1.1: Google Sign-In
* **Actor:** Host
* **Pre-condition:** App is installed, internet connection is available.
* **Main Flow:**
  1. User taps "Sign in with Google".
  2. System invokes Firebase Auth Google Sign-In.
  3. Retrieves the returned email address.
  4. Checks: `email.endsWith('@humg.edu.vn')`.
  5. If false: Cancel the login session, display error message "Only HUMG student emails are accepted".
  6. If true: Allow sign-in and proceed.
* **Database Impact:**
  * Collection `users`: Create or update document with Firebase Auth UID as the document ID. Stores fields: `name`, `email`, `avatar`, `role: 'user'`, `createdAt`.

#### UC-1.2: Logout
* **Actor:** Host, Logged-in Viewer
* **Main Flow:** Clear the current Firebase Auth session and navigate back to the Login screen.

---

### MODULE 2: PROFILE & SHARING

#### UC-2.1: Generate Shareable Deep Link
* **Actor:** Host
* **Pre-condition:** Must be logged in.
* **Main Flow:**
  1. User navigates to the Profile screen.
  2. System generates a unique link (via Firebase Dynamic Links or a custom URL scheme) in the format `askme-humg-app.web.app/user/{userId}`.
  3. User taps "Copy Link" or "Share to Instagram/Facebook Story".
  4. System generates a visual Card Image containing the link/QR code for easy sharing.
* **Alternative Flow (Fallback):** When another person taps the link:
  * If the device HAS the app installed: Opens the app directly and navigates to the Host's Profile screen.
  * If the device does NOT have the app: Redirects the user to the App Store/Google Play or a web fallback page.

#### UC-2.2: View User Profile
* **Actor:** Viewer, Host, Anonymous Sender
* **Main Flow:**
  1. User navigates to a Host's Profile (via avatar tap on the Feed or via Deep Link).
  2. System fetches the user's information.
  3. Displays: Display name, Avatar, Total answered questions, Total likes received.
* **Database Impact:**
  * Collection `users`: `GET` the document matching the `userId`.
  * Collection `answers`: Query the user's answers to calculate total answer count and total likes (can be optimized in the future by denormalizing these stats directly into the `users` document if needed).

---

### MODULE 3: CORE Q&A

#### UC-3.1: Submit Anonymous Question
* **Actor:** Anonymous Sender, Host, Viewer
* **Pre-condition:** Currently on a Host's Profile screen (accessed via Deep Link or in-app navigation).
* **Main Flow:**
  1. User types a question (max 300 characters).
  2. Taps "Send Anonymously".
  3. Client validates length and applies basic profanity filtering.
  4. Attaches a **Firebase App Check** token to the request to prove it is not a bot.
  5. Calls Cloud Functions / Firestore to submit data. Cloud Functions enforces Rate Limiting (max 5 questions per device per hour).
  6. On success: Displays a success animation/effect.
* **Database Impact:**
  * Collection `questions`: Creates a new document (`toUserId`, `content`, `createdAt`, `status: 'unanswered'`).

#### UC-3.2: Manage Inbox
* **Actor:** Host
* **Pre-condition:** Must be logged in.
* **Main Flow:**
  1. Host opens the Inbox tab.
  2. System queries the `questions` collection where `toUserId == currentUser.uid`.
  3. Displays a categorized list: "Unanswered" (`status == 'unanswered'`) and "Answered" (`status == 'answered'`).

#### UC-3.3: Answer Question & Publish to Feed
* **Actor:** Host
* **Main Flow:**
  1. Host selects an `unanswered` question from the Inbox.
  2. Types a reply.
  3. Toggles "Publish to Feed" (`isPublished`) on or off.
  4. Taps "Submit".
* **Database Impact:** *(Must use Batch Write to ensure data integrity)*
  * Collection `answers`: Creates a new document (`questionId`, `userId`, `content`, `isPublished`, `likedBy: []`, `likeCount: 0`, `commentCount: 0`).
  * Collection `questions`: Updates the corresponding document to `status: 'answered'`.

---

### MODULE 4: FEED & INTERACTION

#### UC-4.1: View Public Feed
* **Actor:** Viewer (both Guest and Logged-in)
* **Main Flow:**
  1. Open the Feed tab.
  2. System queries the `answers` collection with condition `isPublished == true`, sorted by `createdAt` descending.
  3. Data is loaded with cursor-based Pagination.
  4. Displays: Host Avatar, Question content, Answer content, Like count (`likeCount`), Comment count (`commentCount`).

#### UC-4.2: Like an Answer
* **Actor:** Logged-in Viewer / Host
* **Pre-condition:** Must be logged in.
* **Main Flow:**
  1. User taps the Like button on an answer.
  2. System checks whether `currentUser.uid` is already in the answer's `likedBy` array.
  3. If not present: Add UID to `likedBy`, increment `likeCount` by 1. UI updates the Like icon to red/filled.
  4. If already present: Remove UID from `likedBy`, decrement `likeCount` by 1. UI updates the Like icon to outline/empty.
* **Database Impact:**
  * Collection `answers`: Update the `likedBy` array (`arrayUnion`/`arrayRemove`) and `likeCount` (`increment` 1 or -1).

#### UC-4.3: Comment on an Answer
* **Actor:** Logged-in Viewer / Host
* **Pre-condition:** Must be logged in.
* **Main Flow:**
  1. User taps the Comment icon under an Answer.
  2. Types comment content. Optionally enables "Comment anonymously".
  3. Taps "Submit".
* **Database Impact:**
  *(Use Batch Write)*
  * Collection `comments`: Creates a new document (`answerId`, `userId` (null if anonymous), `content`, `isAnonymous`, `createdAt`).
  * Collection `answers`: Updates `commentCount` field (`increment` 1) on the corresponding answer.

---

### MODULE 5: MODERATION

#### UC-5.1: Report a Violation
* **Actor:** Logged-in Viewer / Host
* **Pre-condition:** Must be logged in.
* **Main Flow:**
  1. Tap the 3-dot menu (...) on an answer or comment.
  2. Select "Report inappropriate content".
  3. Choose a reason (Spam, Offensive language, etc.).
  4. Tap "Submit Report".
* **Database Impact:**
  * Collection `reports`: Creates a new document (`targetId`, `targetType`, `reportedBy`, `reason`, `status: 'pending'`, `createdAt`).

#### UC-5.2: Manage Reports
* **Actor:** Admin
* **Pre-condition:** Logged in with an account that has Admin privileges (determined via Firebase Custom Claims or a `role: 'admin'` field in the `users` collection document).
* **Main Flow:**
  1. Admin opens the Admin Dashboard.
  2. Views the list of reports with `status: 'pending'`.
  3. Admin reviews the reported content (answer or comment).
  4. Makes a decision:
     - *Remove:* Set status to `resolved_removed`. Delete or hide the reported document.
     - *Dismiss:* Set status to `resolved_dismissed`. Keep the content unchanged.
* **Database Impact:**
  * Collection `reports`: Update `status` and `resolvedAt`.
  * Collection `answers`/`comments`: Delete or set `isPublished = false` (if Admin chose Remove).
