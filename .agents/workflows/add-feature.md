---
description: Workflow thêm tính năng mới vào dự án FishCash POS
---

# Add Feature Workflow

## Bước 1: Phân tích yêu cầu
- Xác định tính năng thuộc **Frontend**, **Backend**, hay **cả hai**
- Xác định tính năng có **ảnh hưởng đến database schema** không
  - ⚠️ Nếu có: PHẢI hỏi user trước khi thay đổi schema
- Xác định skills cần đọc (tra bảng trong `rules.md`)

## Bước 2: Đọc Skills bắt buộc
Tùy vào loại tính năng, đọc SKILL.md tương ứng:

### Nếu là tính năng Flutter:
1. Đọc `flutter-architecting-apps/SKILL.md` — để đặt file đúng layer
2. Đọc `ui-ux-pro-max/SKILL.md` — để thiết kế UI chuẩn
3. Đọc skill chuyên biệt:
   - Có form? → `flutter-building-forms`
   - Có animation? → `flutter-animating-apps`
   - Có state phức tạp? → `flutter-managing-state`
   - Cần lưu offline? → `flutter-working-with-databases` + `dart-drift`
   - Cần gọi API? → `flutter-handling-http-and-json`
   - Cần hardware? → `flutter-interoperating-with-native-apis`

### Nếu là tính năng Backend:
1. Đọc `nestjs-best-practices/SKILL.md` — kiến trúc module
2. Đọc `api-design-principles/SKILL.md` — thiết kế API
3. Đọc `typescript-advanced-types/SKILL.md` — type safety
4. Nếu có query phức tạp: đọc `postgresql-optimization/SKILL.md`

## Bước 3: Viết test TRƯỚC (TDD)
- Đọc `test-driven-development/SKILL.md`
- Viết test case cho tính năng mới (RED phase)
- Xác nhận test FAIL như mong đợi

## Bước 4: Implement
- Code tính năng theo hướng dẫn từ skills đã đọc
- Đảm bảo tuân thủ:
  - Kiểu number: **Decimal** cho tiền/khối lượng
  - Offline-first: hoạt động khi mất mạng
  - Responsive: mobile + desktop
- Chạy test → GREEN phase
- Refactor nếu cần

## Bước 5: Review UI/UX
- Kiểm tra theo checklist `ui-ux-pro-max`:
  - [ ] Touch target ≥ 48dp (mobile)
  - [ ] Tap feedback < 100ms
  - [ ] Loading states (skeleton/shimmer)
  - [ ] Dark/Light mode hoạt động đúng
  - [ ] Platform-adaptive (iOS vs Android vs Desktop)

## Bước 6: Commit
- Chạy `/commit` workflow
