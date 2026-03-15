# FishCash POS — Project Rules

## Ngôn ngữ
- Giao tiếp bằng **tiếng Việt**
- Comment code và commit message bằng **tiếng Anh**

## Kiến trúc dự án
- **Frontend**: Flutter (Dart) — Offline-first, đa nền tảng
- **Backend**: NestJS (TypeScript) — REST API + Socket.io real-time
- **Database**: PostgreSQL (self-hosted) + SQLite (local on device)

## Quy tắc sử dụng Skills

### Khi nào dùng skill nào

| Tình huống | Skill phải đọc |
|---|---|
| Tạo/sửa **widget, page, screen** Flutter | `flutter-architecting-apps` + `ui-ux-pro-max` |
| Quản lý **state** (Bloc/Riverpod/Provider) | `flutter-managing-state` |
| Thêm **animation, transition** | `flutter-animating-apps` |
| Thay đổi **theme, color, typography** | `flutter-theming-apps` + `ui-ux-pro-max` |
| Lưu dữ liệu **offline** (SQLite/Isar) | `flutter-working-with-databases` + `dart-drift` |
| Gọi **HTTP API** hoặc parse JSON | `flutter-handling-http-and-json` |
| Xử lý **background task, isolate** | `flutter-handling-concurrency` |
| Kết nối **hardware** (máy in ESC/POS, Bluetooth) | `flutter-interoperating-with-native-apis` |
| Viết **test** cho Flutter | `flutter-testing-apps` |
| Tạo/sửa **API endpoint** NestJS | `nestjs-best-practices` + `api-design-principles` |
| Viết **TypeScript types/interfaces** | `typescript-advanced-types` |
| Viết/tối ưu **SQL query** PostgreSQL | `postgresql-optimization` |
| Gặp **bug** hoặc behavior bất thường | `systematic-debugging` (BẮT BUỘC đọc trước khi fix) |
| Viết **test** cho backend | `test-driven-development` |
| **Commit** code | `git-commit` |

### Nguyên tắc QUAN TRỌNG

1. **PHẢI đọc SKILL.md** của skill tương ứng TRƯỚC KHI viết code
2. **KHÔNG được** fix bug bằng cách đoán — PHẢI theo `systematic-debugging` workflow
3. **KHÔNG được** commit mà không theo conventional commits format từ `git-commit`
4. **KHÔNG được** tự ý thay đổi schema database mà không hỏi user trước
5. **KHÔNG được** xóa hoặc ghi đè dữ liệu người dùng mà không có confirmation

## Quy tắc Code

### Flutter (Dart)
- Dùng **Material 3** theming (`ColorScheme.fromSeed`)
- State management: **Bloc** hoặc **Riverpod** (nhất quán trong toàn project)
- Kiểu số tiền/khối lượng: **Decimal** (không dùng double)
- Offline-first: mọi thao tác phải hoạt động khi mất mạng
- Responsive: hỗ trợ cả mobile (360dp) và desktop (1280dp+)

### NestJS (TypeScript)
- Tổ chức theo **feature modules** (không theo technical layers)
- Dùng **DTOs + class-validator** cho tất cả input
- Transaction cho mọi thao tác ghi nhiều bảng
- Dùng **Decimal.js** hoặc PostgreSQL `NUMERIC` cho tiền tệ

### Database (PostgreSQL)
- Kiểu tiền tệ: `NUMERIC(15,2)` — KHÔNG dùng `FLOAT`
- Kiểu khối lượng: `NUMERIC(12,3)` — chính xác đến gram
- Luôn dùng **migrations** cho schema changes
- Index trên các cột thường query (product_id, order_date, status)

## Workflows
- Build & Run: xem `.agents/workflows/build.md`
- Thêm tính năng: xem `.agents/workflows/add-feature.md`
- Commit: xem `.agents/workflows/commit.md`
- Debug: xem `.agents/workflows/debug.md`
- Test: xem `.agents/workflows/test.md`
