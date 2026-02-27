# UC-2.1 – Generate & Share Deep Link

> **Module:** Profile & Sharing
> **SRS Reference:** FR-11
> **Actor:** Host
> **Priority:** High

---

## 1. Pre-conditions

- User is logged in as Host
- User is on the Profile screen

## 2. Main Flow – Copy Link

```
1. User taps "Copy Link" on Profile screen
2. System constructs the deep link URL: https://askme.humg.edu.vn/u/{currentUser.uid}
3. System copies URL to clipboard via Clipboard.setData()
4. System shows success snackbar: l10n.linkCopied
```

## 3. Main Flow – Share Card (Image)

```
1. User taps "Share Card" on Profile screen
2. System renders ShareCardWidget (contains avatar, name, QR code of the deep link) to an image
3. System calls share_plus SharePlus.shareXFiles() or SharePlus.share() with the URL
4. Native share sheet appears (Instagram, Facebook, WhatsApp, etc.)
```

## 4. Main Flow – Deep Link Handling (Recipient opens link)

```
Case A – App IS installed on recipient's device:
  1. OS intercepts the URL askme.humg.edu.vn/u/{userId}
  2. app_links package receives the link in AppLinks().uriLinkStream
  3. GoRouter navigates to /u/{userId} (ProfileScreen)
  4. ProfileScreen loads the Host's profile data

Case B – App is NOT installed:
  1. URL opens in browser
  2. Fallback web page shows app download links (App Store / Google Play)
```

---

## 5. Database Impact

None for link generation. Deep link handling triggers UC-2.2 (View Profile).

---

## 6. Files to Create / Modify

```
lib/app/modules/profile/
├── domain/
│   ├── entities/user_profile.dart              [CREATE] @freezed
│   ├── repositories/i_profile_repository.dart  [CREATE]
│   └── use_cases/generate_deep_link.dart       [CREATE]
├── data/
│   └── repositories/profile_repository_impl.dart  [CREATE]
└── presentation/
    ├── screens/profile_screen.dart              [CREATE] route /u/:userId
    └── widgets/
        ├── share_card_widget.dart               [CREATE] renders QR + avatar card
        └── profile_header.dart                  [CREATE]

lib/config/bootstrap.dart        [MODIFY] init app_links listener
lib/config/router.dart           [MODIFY] handle incoming deep links from app_links
android/app/src/main/AndroidManifest.xml  [MODIFY] intent-filter for deep link
ios/Runner/Info.plist             [MODIFY] Associated Domains / URL Schemes
```

---

## 7. Key Code Contracts

### Use Case: `generate_deep_link.dart`
```dart
class GenerateDeepLink {
  String call(String userId) => 'https://askme.humg.edu.vn/u/$userId';
}
```

### Deep Link Listener (in bootstrap.dart or router.dart)
```dart
// Using app_links package
final appLinks = AppLinks();
appLinks.uriLinkStream.listen((uri) {
  // uri.path = /u/{userId}
  router.go(uri.path);
});
```

### ShareCardWidget
- Uses `qr_flutter` to render QR code of the deep link URL
- Uses `RepaintBoundary` + `RenderRepaintBoundary.toImage()` to capture as PNG
- Shares via `share_plus`

---

## 8. Android Configuration (AndroidManifest.xml)

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="askme.humg.edu.vn"/>
</intent-filter>
```

## 9. iOS Configuration (Info.plist)

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:askme.humg.edu.vn</string>
</array>
```

---

## 10. Acceptance Criteria (from SRS FR-11)

- [ ] Deep link format is exactly `https://askme.humg.edu.vn/u/{userId}`
- [ ] Tapping link when app installed → opens ProfileScreen of correct user
- [ ] Tapping link when app not installed → opens browser fallback/store page
- [ ] "Copy Link" copies URL to clipboard and shows snackbar
- [ ] "Share Card" opens native share sheet with image/URL
- [ ] QR code in card decodes to the correct deep link URL
