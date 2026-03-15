---
description: Systematic debugging workflow khi gặp bug hoặc behavior bất thường
---

# Debug Workflow

> ⚠️ **BẮT BUỘC** đọc `systematic-debugging/SKILL.md` trước khi bắt đầu debug.
> KHÔNG BAO GIỜ fix bug bằng cách đoán.

## The Iron Law
Không bao giờ thay đổi code để fix bug cho đến khi hiểu chính xác root cause.

## Phase 1: Thu thập chứng cứ (Root Cause Investigation)
1. **Reproduce bug**: xác nhận bug xảy ra lại được
2. **Thu thập thông tin**:
   - Error message chính xác
   - Stack trace đầy đủ
   - Input data khi xảy ra bug
   - Điều kiện môi trường (OS, device, network status)
3. **Trace theo layers**: từ UI → State → Service → API → Database
   - Flutter: Widget → Bloc/Provider → Repository → HTTP Client → Backend
   - NestJS: Controller → Service → Repository → PostgreSQL query

## Phase 2: Phân tích Pattern
- Bug xảy ra **luôn** hay **ngẫu nhiên**?
- Bug chỉ trên **1 platform** hay tất cả?
- Bug liên quan đến **data cụ thể** (ví dụ: số thập phân, ký tự đặc biệt)?
- Bug chỉ xảy ra khi **offline** hay cả online?

## Phase 3: Giả thuyết & Kiểm chứng
1. Đặt **1 giả thuyết cụ thể** về nguyên nhân
2. Thiết kế **1 test** để verify/falsify giả thuyết
3. Chạy test:
   - Nếu **confirmed** → tiến sang Phase 4
   - Nếu **falsified** → quay lại Phase 2, đặt giả thuyết mới

## Phase 4: Fix & Verify
1. Viết **test case cho bug** (test phải FAIL trước khi fix)
2. Fix code — thay đổi **tối thiểu cần thiết**
3. Chạy lại test → phải PASS
4. Chạy **toàn bộ test suite** → không regression

## Red Flags — DỪNG LẠI ngay nếu:
- 🚩 Bạn đang thử "fix" thứ 3 mà chưa hiểu root cause
- 🚩 Bạn thêm workaround thay vì fix gốc
- 🚩 Fix ở chỗ này lại gây bug chỗ khác
- 🚩 Bạn tắt error handling thay vì fix lỗi

## Debug tools theo stack

### Flutter
// turbo
```bash
flutter analyze
flutter test
```
- DevTools: `flutter run --debug` → mở DevTools
- Logging: `debugPrint()`, `log()` from `dart:developer`

### NestJS
// turbo
```bash
npm run test
npm run test:e2e
```
- Logging: NestJS Logger, `console.log` cho dev
- PostgreSQL: `EXPLAIN ANALYZE <query>` cho slow queries
