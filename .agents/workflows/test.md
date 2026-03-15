---
description: Test workflow theo TDD cho cả Flutter và NestJS
---

# Test Workflow

> Đọc `test-driven-development/SKILL.md` trước khi viết test.

## Nguyên tắc TDD: Red → Green → Refactor

### RED — Viết test TRƯỚC
1. Xác định behavior cần test
2. Viết test case mô tả expected behavior
3. Chạy test → phải **FAIL** (nếu pass ngay = test sai)

### GREEN — Code tối thiểu
1. Viết code **vừa đủ** để test pass
2. Không optimize, không refactor ở bước này
3. Chạy test → phải **PASS**

### REFACTOR — Dọn dẹp code
1. Clean up code nhưng không thay đổi behavior
2. Chạy test lại → vẫn phải **PASS**

## Flutter Testing

### Unit Test (logic thuần)
// turbo
```bash
flutter test test/unit/
```
- Test models, services, repositories
- Mock external dependencies

### Widget Test (UI components)
// turbo
```bash
flutter test test/widget/
```
- Test widget rendering, user interaction
- Dùng `pumpWidget()`, `find.byType()`, `tap()`

### Integration Test (end-to-end)
// turbo
```bash
flutter test integration_test/
```
- Test full user flows
- Test offline → online sync

## NestJS Testing

### Unit Test
// turbo
```bash
cd backend && npm run test
```
- Test services, guards, pipes
- Mock repositories, external services
- Dùng `@nestjs/testing` TestingModule

### E2E Test
// turbo
```bash
cd backend && npm run test:e2e
```
- Test full API endpoints
- Dùng `supertest`
- Test auth flows, CRUD operations

## Checklist trước khi commit
- [ ] Tất cả test mới PASS
- [ ] Không test cũ nào bị FAIL (no regression)
- [ ] Test coverage cho critical paths:
  - [ ] Decimal calculation (tiền, khối lượng)
  - [ ] Offline data persistence
  - [ ] API error handling
  - [ ] Auth/authorization
