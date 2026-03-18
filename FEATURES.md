# 📋 FishCash POS — Chi tiết Chức năng & Công nghệ

> Tài liệu mô tả chi tiết toàn bộ chức năng và công nghệ trong hệ thống FishCash POS.

---

## 1. Tổng quan hệ thống

FishCash POS là hệ thống **Point of Sale** chuyên biệt cho ngành kinh doanh hải sản, gồm 2 thành phần chính:

| Thành phần | Công nghệ | Vai trò |
|------------|-----------|---------|
| **Flutter App** | Dart 3.11+ / Flutter 3.11+ | Ứng dụng đa nền tảng (Windows, Android, iOS) |
| **NestJS API** | TypeScript 5.7+ / NestJS 11 | REST API server, đồng bộ dữ liệu |

---

## 2. Chi tiết Chức năng

### 2.1 🏠 Tổng quan (Dashboard)

**Đường dẫn:** `/` → `DashboardPage`

| Chức năng | Mô tả |
|-----------|--------|
| Thống kê tổng doanh thu | Tổng tiền mua vào, bán ra, lợi nhuận |
| Biểu đồ doanh thu | Biểu đồ trực quan bằng `fl_chart` |
| Tổng quan phiên giao dịch | Số phiên hôm nay, tuần này, tháng này |
| Trạng thái kết nối | Hiển thị trạng thái kết nối server |

**BLoC:** Không có BLoC riêng — sử dụng `DashboardRepository` đọc dữ liệu từ `TradingSessionDao`.

---

### 2.2 📦 Giao dịch sỉ (Trading)

**Đường dẫn:** `/trading` → `TradingPage`

| Chức năng | Mô tả |
|-----------|--------|
| Tạo phiên giao dịch | Nhóm nhiều đơn hàng mua/bán trong 1 phiên |
| Thêm đơn mua (`buy`) | Tạo đơn mua hàng từ nhà cung cấp |
| Thêm đơn bán (`sell`) | Tạo đơn bán hàng cho khách sỉ |
| Chi tiết phiên | Xem tổng mua, tổng bán, lợi nhuận |
| Ghi chú phiên | Thêm ghi chú cho từng phiên |

**BLoC:** `TradingBloc` → `TradingSessionRepository` + `TradeOrderRepository`

**Luồng xử lý:**
```
Tạo phiên → Thêm đơn mua/bán → Thêm sản phẩm vào đơn → 
Tính tổng tiền → Cập nhật phiên → Lưu vào SQLite
```

---

### 2.3 🛒 Bán lẻ POS

**Đường dẫn:** Tích hợp trong Trading (orderType = `pos`)

| Chức năng | Mô tả |
|-----------|--------|
| Giỏ hàng | Thêm/xóa sản phẩm, điều chỉnh số lượng |
| Tính tiền tự động | Tự tính tổng dựa trên giá × khối lượng |
| Chuyển đổi đơn vị | Hỗ trợ kg, yến (10kg), tạ (100kg), tấn (1000kg), con, khay |
| Tính giá linh hoạt | `PriceCalculator` hỗ trợ tính giá theo nhiều đơn vị |

**BLoC:** `PosBloc` → `TradeOrderRepository`

**Model giỏ hàng:** `CartModel`
- `CartItem`: sản phẩm, số lượng, đơn giá, đơn vị
- Quản lý CRUD items trong giỏ
- Tính tổng tiền (`subtotal`)

---

### 2.4 📦 Quản lý Sản phẩm

**Đường dẫn:** `/products` → `ProductPage`

| Chức năng | Mô tả |
|-----------|--------|
| Danh sách sản phẩm | Hiển thị toàn bộ sản phẩm, tìm kiếm, lọc theo danh mục |
| Thêm sản phẩm | Tên, danh mục, đơn giá, đơn vị tính |
| Sửa sản phẩm | Cập nhật thông tin sản phẩm |
| Ẩn/Hiện sản phẩm | Soft delete qua flag `isActive` |

**BLoC:** `ProductBloc` → `ProductRepository` → `ProductDao`

**Lưu trữ giá:** `priceInCents` (INTEGER) — Ví dụ: 150.000₫ → `15000000`

---

### 2.5 🏷️ Quản lý Danh mục

**Đường dẫn:** `/categories` → `CategoryPage`

| Chức năng | Mô tả |
|-----------|--------|
| Danh sách danh mục | Xem tất cả nhóm sản phẩm |
| Thêm/Sửa/Xóa danh mục | CRUD danh mục |
| Phân loại sản phẩm | Liên kết sản phẩm với danh mục |

**BLoC:** `CategoryBloc` → `CategoryRepository` → `CategoryDao`

---

### 2.6 🤝 Quản lý Đối tác

**Đường dẫn:** `/partners` → `PartnerPage`

| Chức năng | Mô tả |
|-----------|--------|
| Nhà cung cấp (`supplier`) | Quản lý người bán hàng cho cửa hàng |
| Khách mua sỉ (`buyer`) | Quản lý khách hàng sỉ |
| Thông tin liên hệ | Tên, số điện thoại, địa chỉ, ghi chú |
| Lịch sử giao dịch | Xem đơn hàng theo đối tác |

**BLoC:** `PartnerBloc` → `PartnerRepository` → `PartnerDao`

---

### 2.7 💰 Tài chính

**Đường dẫn:** `/finance` → `FinancePage`

| Chức năng | Mô tả |
|-----------|--------|
| Tổng thu (income) | Tổng tiền bán hàng |
| Tổng chi (expense) | Tổng tiền mua hàng |
| Lợi nhuận ròng | Thu trừ chi |
| Lọc theo thời gian | Xem báo cáo theo ngày/tuần/tháng |
| Danh sách giao dịch | Chi tiết từng khoản thu/chi |

**BLoC:** `FinanceBloc` → `FinanceRepository` → `TradeOrderDao`

---

### 2.8 📊 Kho hàng

**Đường dẫn:** `/inventory` → `InventoryPage`

| Chức năng | Mô tả |
|-----------|--------|
| Tồn kho hiện tại | Số lượng tồn = Mua vào - Bán ra ± Điều chỉnh |
| Điều chỉnh kho | Thanh lý, hao hụt, làm mới kho |
| Lịch sử điều chỉnh | Xem lý do và số lượng điều chỉnh |

**BLoC:** `InventoryBloc` → `InventoryRepository` → `TradeOrderDao`

**Bảng `InventoryAdjustments`:**
- `quantityInGrams`: Số lượng điều chỉnh (âm = bớt kho)
- `reason`: Lý do (*Thanh lý*, *Hao hụt*, *Làm mới kho*)

---

### 2.9 📝 Công nợ

**Đường dẫn:** `/debt` → `DebtPage`

| Chức năng | Mô tả |
|-----------|--------|
| Danh sách công nợ | Tổng nợ theo từng đối tác |
| Chi tiết nợ đối tác | Danh sách đơn hàng chưa thanh toán |
| Thanh toán từng phần | Trả nợ một phần cho đơn hàng |
| Chọn nhiều đơn | Multi-select để xuất PDF hoặc xóa batch |
| Xuất PDF công nợ | Export danh sách nợ ra PDF |

**BLoC:** `DebtBloc` → `DebtRepository` → `TradeOrderDao`

**Bảng `Payments`:**
- `orderId`: Liên kết đơn hàng
- `amountInCents`: Số tiền thanh toán
- `note`: Ghi chú thanh toán

---

### 2.10 ⚙️ Cài đặt

**Đường dẫn:** `/settings` → `SettingsPage`

| Chức năng | Mô tả |
|-----------|--------|
| Thông tin cửa hàng | Tên, địa chỉ, số điện thoại |
| Logo cửa hàng | Upload logo hiển thị trên hóa đơn |
| QR thanh toán | Upload mã QR ngân hàng cho hóa đơn |
| Dark/Light mode | Chuyển đổi giao diện |

**BLoC:** `StoreInfoBloc` → `StoreInfoRepository` → `StoreInfoDao`

---

### 2.11 🔄 Đồng bộ dữ liệu

**Đường dẫn:** `/sync` → `SyncSettingsPage`

| Chức năng | Mô tả |
|-----------|--------|
| Kết nối server | Nhập API key để kết nối backend |
| Push dữ liệu | Đẩy dữ liệu local chưa sync lên server |
| Pull dữ liệu | Kéo dữ liệu mới từ server về local |
| Full sync | Push + Pull trong 1 thao tác |
| Trạng thái sync | Hiển thị idle/syncing/success/error |
| Auto-sync | Tự đồng bộ khi app khởi động |

**BLoC:** `ConnectionBloc` (trong `SyncBloc`)  
**Service:** `SyncService` + `SyncSocketService` (real-time)

**Luồng Sync:**
```
┌─────────┐         ┌─────────┐         ┌──────────┐
│ SQLite  │ ──Push→ │ Server  │ ←Pull── │ Device 2 │
│(unsynced)│         │(PostgreSQL)│        │ (SQLite) │
└─────────┘         └─────────┘         └──────────┘
```

---

### 2.12 🏪 Thiết lập ban đầu (Setup)

**Đường dẫn:** `/setup` → `StoreSetupPage`

| Chức năng | Mô tả |
|-----------|--------|
| Đăng ký cửa hàng | Nhập tên, SĐT, địa chỉ → nhận JWT |
| Auto-redirect | Tự chuyển về Dashboard sau setup |
| First-launch check | Kiểm tra API key, redirect nếu chưa setup |

---

### 2.13 🔄 Cập nhật tự động (Auto-Update)

| Chức năng | Mô tả |
|-----------|--------|
| Kiểm tra phiên bản | So sánh version hiện tại với GitHub Releases |
| Tải xuống tự động | Download ZIP qua HTTP với progress bar |
| Cài đặt tự động | Giải nén + ghi đè + khởi động lại app |
| Release notes | Hiển thị ghi chú phiên bản mới |

**Service:** `AppUpdater` → GitHub Releases API  
**UI:** `UpdateDialog` (dialog thông báo + progress bar)

---

### 2.14 🧾 Xuất hóa đơn PDF

| Chức năng | Mô tả |
|-----------|--------|
| Hóa đơn giao dịch | In hóa đơn cho từng đơn hàng |
| Logo cửa hàng | Hiển thị logo trên đầu hóa đơn |
| QR thanh toán | Nhúng mã QR ngân hàng |
| Bảng chi tiết | Liệt kê sản phẩm, SL, đơn giá, thành tiền |
| Thông tin cửa hàng | Tên, địa chỉ, SĐT |
| Chọn file lưu | `file_picker` cho phép chọn nơi lưu PDF |
| In trực tiếp | Gửi lệnh in qua `printing` package |

**Service:** `InvoiceService` (66KB — service lớn nhất trong project)

---

## 3. Chi tiết Công nghệ

### 3.1 Frontend — Flutter

#### State Management: BLoC Pattern

```
UI (Widget) ──Event──→ BLoC ──State──→ UI (rebuild)
                        │
                   Repository
                        │
                       DAO (Drift)
```

**9 BLoCs:** CategoryBloc, ProductBloc, PartnerBloc, PosBloc, TradingBloc, StoreInfoBloc, FinanceBloc, InventoryBloc, DebtBloc, ConnectionBloc

#### Database: Drift (SQLite)

- **10 bảng** với type-safe queries
- **7 DAOs** cho truy vấn dữ liệu
- **Code generation** bằng `build_runner`
- **Schema migration** (v1 → v4)
- **Offline-first:** mọi thao tác lưu vào SQLite trước

#### Theme: Ocean Theme (Material 3)

- **Light + Dark mode** — `ColorScheme.fromSeed`
- **Ocean color palette:** Deep (#023E8A), Primary (#0077B6), Light (#00B4D8), Surface (#48CAE4), Foam (#90E0EF), Mist (#CAF0F8)
- **Semantic colors:** Buy Blue (#1565C0), Sell Green (#2E7D32), Profit Gold (#F4A261), Loss Red (#D32F2F)
- **Typography:** Google Fonts Inter
- **Customized:** AppBar, NavigationRail, Card, Button, Input, Dialog, Snackbar, ListTile, Chip

#### Navigation: GoRouter

- **10 routes** chính + 1 setup route
- **ShellRoute** cho persistent sidebar (AppShell)
- **Auto-redirect** tới `/setup` nếu chưa cấu hình
- **NoTransitionPage** cho navigation mượt

#### Đơn vị đo lường

| Đơn vị | Tên Việt | Hệ số → kg |
|--------|----------|-------------|
| `kg` | Kilogram | × 1 |
| `yến` | Yến | × 10 |
| `tạ` | Tạ | × 100 |
| `tấn` | Tấn | × 1.000 |
| `con` | Con | (đếm) |
| `khay` | Khay | (đếm) |

---

### 3.2 Backend — NestJS

#### Module Architecture

```
AppModule
├── AuthModule          # JWT setup, store registration
├── CategoriesModule    # CRUD categories
├── ProductsModule      # CRUD products
├── PartnersModule      # CRUD partners (supplier/buyer)
├── SessionsModule      # Trading sessions
├── OrdersModule        # Trade orders (buy/sell/pos)
├── TransactionsModule  # Financial transactions
├── InventoryModule     # Inventory adjustments
├── PaymentsModule      # Partial/full payments
├── StoreModule         # Store info management
└── SyncModule          # Push/Pull sync engine
```

#### Security

| Feature | Implementation |
|---------|---------------|
| Authentication | JWT Bearer Token (365 ngày) |
| Password Hashing | bcrypt |
| HTTP Headers | Helmet (X-Content-Type-Options, X-Frame-Options, etc.) |
| Rate Limiting | ThrottlerGuard — 60 requests/60 seconds/IP |
| Input Validation | class-validator + whitelist |
| CORS | Configurable origins |

#### API Design

- **Prefix:** `/api/v1/`
- **DTOs:** class-validator cho tất cả input
- **Swagger:** Auto-generated docs tại `/api/docs`
- **Global validation pipe:** whitelist + transform
- **Request logging:** Custom middleware

---

### 3.3 DevOps & CI/CD

#### GitHub Actions (4 Workflows)

| Workflow | File | Trigger | Chi tiết |
|----------|------|---------|----------|
| Flutter CI | `flutter-ci.yml` | Push/PR → `main` | `flutter analyze` + `flutter test` |
| Backend CI | `backend-ci.yml` | Push/PR → `main` | `npm run lint` + `npm test` |
| Build Windows | `build-windows.yml` | Tag `v*` | Build release + tạo GitHub Release |
| DB Backup | `db-backup.yml` | Scheduled | Backup PostgreSQL |

#### Docker Production Stack

```yaml
Services:
  postgres:     # PostgreSQL 16 Alpine + healthcheck
  api:          # NestJS (Node 20 Alpine, non-root user) 
  nginx:        # Reverse proxy + SSL (port 80/443)
```

**Multi-stage Dockerfile:**
1. **Builder stage:** `npm ci` → `npm run build`
2. **Production stage:** `npm ci --only=production` + non-root user

#### Release Process

```
.\release.ps1 1.3.3
  → Cập nhật pubspec.yaml
  → flutter build windows --release
  → Tạo ZIP
  → git commit + tag + push
  → GitHub Actions tạo Release tự động
```

---

## 4. Quy ước Code

### Tiền tệ & Khối lượng

| Loại | Lưu trữ | Ví dụ |
|------|---------|-------|
| Tiền tệ (VNĐ) | `INTEGER` (cents × 100) | 150.000₫ → `15000000` |
| Khối lượng | `INTEGER` (grams × 1000) | 3.5 kg → `3500` |
| Không dùng | `FLOAT` / `DOUBLE` | ❌ Gây sai lệch tính toán |

### Dart

- **Decimal** package cho tính toán tiền tệ (không dùng `double`)
- **Equatable** cho BLoC states (so sánh chính xác)
- **UUID** cho tất cả primary keys

### TypeScript

- **DTOs + class-validator** cho mọi input
- **Feature modules** (không tổ chức theo technical layers)
- **NUMERIC(15,2)** cho tiền tệ trong PostgreSQL
- **NUMERIC(12,3)** cho khối lượng trong PostgreSQL

---

## 5. Danh sách Dependencies

### Flutter (`pubspec.yaml`)

| Package | Version | Category |
|---------|---------|----------|
| `flutter_bloc` | ^9.1.0 | State Management |
| `equatable` | ^2.0.7 | State Management |
| `go_router` | ^14.8.1 | Navigation |
| `drift` | ^2.25.0 | Database |
| `sqlite3_flutter_libs` | ^0.5.28 | Database |
| `path_provider` | ^2.1.5 | File System |
| `decimal` | ^3.2.1 | Utils |
| `intl` | ^0.20.2 | Localization |
| `uuid` | ^4.5.1 | Utils |
| `pdf` | ^3.11.2 | PDF Generation |
| `printing` | ^5.14.1 | PDF Printing |
| `file_picker` | ^8.3.7 | File System |
| `fl_chart` | ^0.70.2 | Charts |
| `http` | ^1.6.0 | Networking |
| `shared_preferences` | ^2.5.4 | Storage |
| `connectivity_plus` | ^7.0.0 | Networking |
| `socket_io_client` | ^3.1.4 | Real-time |
| `archive` | ^4.0.9 | Auto-update |
| `package_info_plus` | ^9.0.0 | App Info |
| `cupertino_icons` | ^1.0.8 | UI |
| `google_fonts` | ^6.2.1 | Typography |
| `flutter_adaptive_scaffold` | ^0.3.1 | Responsive |

### NestJS (`package.json`)

| Package | Version | Category |
|---------|---------|----------|
| `@nestjs/core` | ^11.0.1 | Framework |
| `@nestjs/config` | ^4.0.3 | Configuration |
| `@nestjs/typeorm` | ^11.0.0 | ORM |
| `@nestjs/jwt` | ^11.0.2 | Auth |
| `@nestjs/passport` | ^11.0.5 | Auth |
| `@nestjs/swagger` | ^11.2.6 | API Docs |
| `@nestjs/throttler` | ^6.5.0 | Security |
| `@nestjs/websockets` | ^11.1.17 | Real-time |
| `@nestjs/platform-socket.io` | ^11.1.17 | Real-time |
| `typeorm` | ^0.3.28 | ORM |
| `pg` | ^8.20.0 | PostgreSQL Driver |
| `bcrypt` | ^6.0.0 | Security |
| `class-validator` | ^0.14.4 | Validation |
| `class-transformer` | ^0.5.1 | Transformation |
| `helmet` | ^8.1.0 | Security |
| `passport-jwt` | ^4.0.1 | Auth |
| `socket.io` | ^4.8.3 | Real-time |
| `uuid` | ^13.0.0 | Utils |
| `rxjs` | ^7.8.1 | Reactive |

---

<p align="center">
  <sub>📅 Cập nhật lần cuối: 18/03/2026 | FishCash POS v1.3.3</sub>
</p>
