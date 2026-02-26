# FLUTTER MOBILE APP BASEBASE

## Quick Start
```bash
dart pub global activate melos
melos run get
```

If "melos: command not found":
```bash
# Use without PATH change
dart pub global run melos run get

# Or add to PATH (Windows - Git Bash, current session)
export PATH="$PATH:/c/Users/admin/AppData/Local/Pub/Cache/bin"
melos run get

# Or PowerShell (current session)
$env:Path += ";C:\Users\admin\AppData\Local\Pub\Cache\bin"
melos run get
```

## Environment
```bash
cp .env.example .env
```
Run with predefined env (via Melos, uses dart-define under the hood):
```bash
melos run run:android:debug   # APP_ENV=debug
melos run run:android:stg     # APP_ENV=stg
melos run run:android:release # APP_ENV=release

melos run run:ios:debug
melos run run:ios:stg
melos run run:ios:release
```

## Dev Commands
```bash
# Localization
melos run gen:l10n

# Launcher icons (Android/iOS)
melos run icons

# Native splash (Android/iOS)
melos run splash

# Android builds
melos run build:apk
melos run build:appbundle

# iOS build (on macOS)
melos run build:ios

# Utilities
melos run clean
melos run format
melos run analyze
```

Notes:
- Icon/Splash assets: `assets/icon/` (paths configured in `pubspec.yaml`).
- ARB l10n files: `lib/l10n/*.arb` (configured in `l10n.yaml`).
- Fonts: put files in `assets/fonts/` and use family `Inter`.

## Environment (APP_ENV)
Copy file `.env` mẫu và cập nhật giá trị theo môi trường của bạn:
```bash
cp .env.example .env
```

Chạy bằng Melos (đã cấu hình sẵn APP_ENV bằng dart-define):
```bash
melos run run:android:debug   # APP_ENV=debug
melos run run:android:stg     # APP_ENV=stg
melos run run:android:release # APP_ENV=release

melos run run:ios:debug
melos run run:ios:stg
melos run run:ios:release
```

## Folder Structure
```
lib/
 ├─ main.dart                    # Điểm vào ứng dụng
 ├─ app/                         # Mã ứng dụng theo kiến trúc/layers
 │  ├─ bindings/                 # Định nghĩa DI/bindings cho module
 │  ├─ core/                     # Nền tảng dùng chung (theme/values/...)
 │  │  ├─ theme/                 # Chủ đề, màu sắc, typography, spacing
 │  │  └─ values/                # Hằng số, enums, keys
 │  ├─ data/                     # Tầng dữ liệu (model/providers/repositories)
 │  │  ├─ model/                 # Models/DTOs
 │  │  ├─ providers/             # Data sources (API, local,...)
 │  │  └─ repositories/          # Implement repositories
 │  ├─ global_widgets/           # Widget dùng chung
 │  ├─ modules/                  # Tổ chức theo tính năng (auth, home,...)
 │  │  ├─ auth/
 │  │  └─ home/
 │  ├─ routes/                   # Điều hướng, router
 │  └─ services/                 # Services (logging, analytics, notification,...)
 ├─ config/
 │  └─ languages.dart            # Danh sách supportedLocales
 ├─ l10n/                        # Localization (ARB + generated)
 │  ├─ *.arb                     # Chuỗi đa ngôn ngữ
 │  └─ app_localizations*.dart   # File sinh từ gen_l10n
 └─ generated/                   # Mã sinh tự động khác (nếu có)
```

## Modules (MVC)
Ví dụ cấu trúc 1 module theo MVC (có thể nhân bản cho các feature khác):
```
lib/app/modules/<feature>/
 ├─ models/          # Model/Entity, mapper
 ├─ views/           # Widgets/Màn hình (UI)
 ├─ controllers/     # State/controller (Bloc/Notifier/ChangeNotifier)
 ├─ services/        # Logic riêng của module (tùy chọn)
 └─ repository/      # Giao tiếp dữ liệu của module (tùy chọn)
```
Gợi ý: nếu module có nhiều màn hình, tạo `views/pages/` và `views/widgets/` để tách rõ.

## Coding Tips
- Env: `cp .env.example .env` rồi chỉnh giá trị cần thiết.
- L10n: viết chuỗi trong `lib/l10n/*.arb`, chạy `melos run gen:l10n` (hoặc hot-restart).
- API client: lấy `dio` từ DI
```dart
import 'package:askme_humg/config/di.dart';
import 'package:askme_humg/app/services/api_client.dart';

final dio = di<ApiClient>().dio;
```
- Logger: `AppLogger.d('message', tag: 'HOME')` (tự tắt ở release).
- Validator: dùng từ `Validators` (nonEmpty, email, combine, ...).
