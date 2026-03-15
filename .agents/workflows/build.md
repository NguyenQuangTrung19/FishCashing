---
description: Build and run Flutter app or NestJS backend locally
---
// turbo-all

# Build & Run — Flutter Frontend

1. Kiểm tra Flutter environment:
```bash
flutter doctor
```

2. Cài dependencies:
```bash
flutter pub get
```

3. Generate code (nếu dùng build_runner/drift):
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Chạy app ở chế độ debug:
```bash
# Android/iOS
flutter run

# Desktop (Windows)
flutter run -d windows

# Desktop (macOS)
flutter run -d macos
```

5. Build production:
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release
```

# Build & Run — NestJS Backend

1. Cài dependencies:
```bash
cd backend && npm install
```

2. Setup environment:
```bash
cp .env.example .env
# Chỉnh sửa DATABASE_URL, JWT_SECRET, etc.
```

3. Chạy migrations:
```bash
npm run migration:run
```

4. Chạy dev server:
```bash
npm run start:dev
```

5. Build production:
```bash
npm run build
npm run start:prod
```
