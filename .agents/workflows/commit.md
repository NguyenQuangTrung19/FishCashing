---
description: Commit changes theo Conventional Commits standard
---

# Commit Workflow

## Trước khi commit
1. Đọc `git-commit` skill (`.agent/skills/git-commit/SKILL.md`)

## Bước 1: Kiểm tra thay đổi
// turbo
```bash
git status --porcelain
```

## Bước 2: Xem diff
// turbo
```bash
git diff --staged
```
Nếu chưa staged:
// turbo
```bash
git diff
```

## Bước 3: Stage files theo nhóm logic
```bash
# Stage theo feature/module, KHÔNG stage tất cả một lần
git add <files-thuộc-cùng-feature>
```

⚠️ **KHÔNG BAO GIỜ** commit các file sau:
- `.env`, `credentials.json`, private keys
- Compiled binaries, `.apk`, `.exe`
- `node_modules/`, `.dart_tool/`, `build/`

## Bước 4: Xác định commit type
Phân tích diff để chọn type phù hợp:

| Type | Khi nào dùng |
|---|---|
| `feat` | Tính năng mới |
| `fix` | Sửa bug |
| `docs` | Chỉ thay đổi documentation |
| `style` | Format code, không ảnh hưởng logic |
| `refactor` | Restructure code, không thêm feature/fix bug |
| `perf` | Cải thiện hiệu suất |
| `test` | Thêm/sửa test |
| `build` | Thay đổi build system, dependencies |
| `ci` | CI/CD config |
| `chore` | Maintenance tasks |

## Bước 5: Viết commit message
Format: `<type>(<scope>): <description>`

- **scope**: module bị ảnh hưởng (pos, order, product, auth, db, api...)
- **description**: imperative mood, present tense, < 72 ký tự
- Kèm `Closes #<issue>` nếu liên quan issue

Ví dụ:
```
feat(pos): add ESC/POS thermal printer support via USB
fix(order): correct decimal precision for seafood weight calculation
refactor(auth): extract JWT validation to dedicated guard
```

## Bước 6: Commit
```bash
git commit -m "<type>(<scope>): <description>"
```

## Quy tắc an toàn
- ❌ KHÔNG `git push --force` lên main/master
- ❌ KHÔNG `git reset --hard` mà không hỏi user
- ❌ KHÔNG skip hooks (`--no-verify`) trừ khi user yêu cầu
