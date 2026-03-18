<p align="center">
  <img src="assets/images/logo_icon.png" alt="FishCash POS Logo" width="120" />
</p>

<h1 align="center">🐟 FishCash POS</h1>

<p align="center">
  <strong>Hệ thống quản lý cửa hàng hải sản chuyên nghiệp</strong><br/>
  Point of Sale • Quản lý giao dịch • Đồng bộ đa thiết bị
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.3.3-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?style=flat-square&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/NestJS-11-E0234E?style=flat-square&logo=nestjs" alt="NestJS" />
  <img src="https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/license-UNLICENSED-lightgrey?style=flat-square" alt="License" />
</p>

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng chính](#-tính-năng-chính)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Cài đặt & Khởi chạy](#-cài-đặt--khởi-chạy)
- [Triển khai (Deployment)](#-triển-khai-deployment)
- [Database Schema](#-database-schema)
- [API Documentation](#-api-documentation)
- [CI/CD Pipeline](#-cicd-pipeline)

---

## 🎯 Giới thiệu

**FishCash POS** là hệ thống quản lý bán hàng (Point of Sale) được thiết kế đặc biệt cho ngành **kinh doanh hải sản** tại Việt Nam. Hệ thống hỗ trợ quy trình mua bán sỉ/lẻ với các đơn vị đo lường đặc thù (kg, yến, tạ, tấn, con, khay) và quản lý công nợ đối tác.

### Đặc điểm nổi bật

- 🔌 **Offline-first** — Hoạt động đầy đủ khi mất kết nối internet, tự động đồng bộ khi có mạng
- 🖥️ **Đa nền tảng** — Hỗ trợ Windows, Android, iOS, macOS
- 🔄 **Đồng bộ real-time** — Dữ liệu đồng bộ giữa nhiều thiết bị qua Socket.io
- 📊 **Dashboard trực quan** — Biểu đồ doanh thu, lợi nhuận, tồn kho theo thời gian thực
- 🧾 **Xuất hóa đơn PDF** — In hóa đơn chuyên nghiệp với thông tin cửa hàng, QR code thanh toán
- 🔒 **Bảo mật** — JWT Authentication, Helmet security headers, Rate limiting

---

## ✨ Tính năng chính

| Module | Mô tả |
|--------|--------|
| **Tổng quan (Dashboard)** | Biểu đồ doanh thu, lợi nhuận, thống kê phiên giao dịch |
| **Giao dịch (Trading)** | Quản lý phiên giao dịch sỉ, tạo đơn mua/bán |
| **POS (Bán lẻ)** | Bán hàng nhanh cho khách lẻ, giỏ hàng, tính tiền |
| **Sản phẩm** | CRUD sản phẩm, phân loại, đơn giá, đơn vị tính |
| **Danh mục** | Quản lý nhóm sản phẩm |
| **Đối tác** | Quản lý nhà cung cấp & khách mua sỉ |
| **Tài chính** | Báo cáo thu chi, sổ giao dịch tài chính |
| **Kho hàng** | Theo dõi tồn kho, điều chỉnh kho (thanh lý, hao hụt) |
| **Công nợ** | Quản lý công nợ theo đối tác, thanh toán từng phần |
| **Cài đặt** | Thông tin cửa hàng, logo, QR thanh toán |
| **Đồng bộ** | Push/Pull sync, trạng thái kết nối server |
| **Cập nhật tự động** | Kiểm tra & cài đặt phiên bản mới từ GitHub Releases |

---

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Client                       │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐    │
│  │   UI     │→ │   BLoC   │→ │   Repository       │    │
│  │ (Pages)  │  │ (State)  │  │ (DAO + ApiClient)  │    │
│  └──────────┘  └──────────┘  └─────────┬──────────┘    │
│                                        │               │
│                              ┌─────────┴──────────┐    │
│                              │  Drift (SQLite)    │    │
│                              │  Local Database    │    │
│                              └────────────────────┘    │
└──────────────────────┬─────────────────────────────────┘
                       │ REST API + Socket.io
┌──────────────────────┴─────────────────────────────────┐
│                   NestJS Backend                        │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐    │
│  │Controller│→ │ Service  │→ │ TypeORM Repository │    │
│  └──────────┘  └──────────┘  └─────────┬──────────┘    │
│                                        │               │
│                              ┌─────────┴──────────┐    │
│                              │    PostgreSQL       │    │
│                              │  (Neon.tech cloud)  │    │
│                              └────────────────────┘    │
└────────────────────────────────────────────────────────┘
```

### Layered Architecture (Flutter)

| Layer | Thư mục | Vai trò |
|-------|---------|---------|
| **Presentation** | `lib/presentation/` | Pages, Widgets, BLoC (UI + State) |
| **Domain** | `lib/domain/` | Business models (CartModel, CategoryModel, etc.) |
| **Data** | `lib/data/` | Repositories, DAOs, Database tables |
| **Core** | `lib/core/` | Theme, Services, Utils, Constants |
| **App** | `lib/app/` | Router (GoRouter), App config |

---

## 🛠️ Công nghệ sử dụng

### Frontend (Flutter/Dart)

| Công nghệ | Phiên bản | Mục đích |
|-----------|----------|----------|
| **Flutter** | 3.11+ | Framework đa nền tảng |
| **Dart** | 3.11+ | Ngôn ngữ lập trình |
| **flutter_bloc** | 9.1.0 | State management (BLoC pattern) |
| **go_router** | 14.8.1 | Declarative routing |
| **drift** | 2.25.0 | Type-safe SQLite ORM |
| **fl_chart** | 0.70.2 | Biểu đồ (Dashboard) |
| **pdf** / **printing** | 3.11.2 / 5.14.1 | Xuất & in hóa đơn PDF |
| **google_fonts** | 6.2.1 | Typography (Inter font) |
| **http** | 1.6.0 | HTTP client |
| **socket_io_client** | 3.1.4 | Real-time sync |
| **connectivity_plus** | 7.0.0 | Kiểm tra kết nối mạng |
| **shared_preferences** | 2.5.4 | Lưu cấu hình local |
| **decimal** | 3.2.1 | Tính toán tiền tệ chính xác |
| **archive** | 4.0.9 | Giải nén ZIP (auto-update) |
| **package_info_plus** | 9.0.0 | Đọc phiên bản app |
| **equatable** | 2.0.7 | So sánh objects (BLoC states) |
| **file_picker** | 8.3.7 | Chọn file (export PDF) |
| **flutter_adaptive_scaffold** | 0.3.1 | Responsive layout |

### Backend (NestJS/TypeScript)

| Công nghệ | Phiên bản | Mục đích |
|-----------|----------|----------|
| **NestJS** | 11.x | Node.js backend framework |
| **TypeScript** | 5.7+ | Ngôn ngữ lập trình |
| **TypeORM** | 0.3.28 | ORM cho PostgreSQL |
| **PostgreSQL** | 16 | Database chính (server) |
| **Passport + JWT** | 0.7 / 11.0 | Authentication |
| **Socket.io** | 4.8.3 | Real-time communication |
| **Swagger** | 11.2.6 | API documentation |
| **Helmet** | 8.1.0 | HTTP security headers |
| **Throttler** | 6.5.0 | Rate limiting (60 req/60s) |
| **class-validator** | 0.14.4 | DTO validation |
| **class-transformer** | 0.5.1 | Request transformation |
| **bcrypt** | 6.0.0 | Password hashing |

### DevOps & Deployment

| Công nghệ | Mục đích |
|-----------|----------|
| **Docker** | Containerization (multi-stage build) |
| **Nginx** | Reverse proxy + SSL termination |
| **Render.com** | Cloud hosting (backend API) |
| **Neon.tech** | Managed PostgreSQL cloud |
| **GitHub Actions** | CI/CD (4 workflows) |
| **GitHub Releases** | Auto-update distribution |

---

## 📁 Cấu trúc dự án

```
FishCashing/
├── lib/                          # Flutter source code
│   ├── main.dart                 # Entry point, DI setup
│   ├── app/                      # App config & routing
│   │   ├── app.dart              # MaterialApp wrapper
│   │   └── router.dart           # GoRouter routes (10 routes)
│   ├── core/                     # Core utilities
│   │   ├── constants/            # App constants, units, formats
│   │   ├── services/             # ApiClient, SyncService, InvoiceService, AppUpdater
│   │   ├── theme/                # Ocean Theme (Light/Dark, Material 3)
│   │   └── utils/                # Formatters, validators, price calculator
│   ├── data/                     # Data layer
│   │   ├── database/             # Drift tables + DAOs + migrations
│   │   └── repositories/        # 10 repositories (business logic)
│   ├── domain/                   # Domain models
│   │   └── models/               # CartModel, CategoryModel, PartnerModel, ProductModel
│   └── presentation/             # UI layer (13 modules)
│       ├── dashboard/            # Tổng quan
│       ├── trading/              # Giao dịch sỉ
│       ├── pos/                  # Bán lẻ POS
│       ├── products/             # Quản lý sản phẩm
│       ├── categories/           # Danh mục
│       ├── partners/             # Đối tác
│       ├── finance/              # Tài chính
│       ├── inventory/            # Kho hàng
│       ├── debt/                 # Công nợ
│       ├── settings/             # Cài đặt cửa hàng
│       ├── sync/                 # Đồng bộ dữ liệu
│       ├── setup/                # Thiết lập ban đầu
│       └── shared/               # Shared widgets (AppShell, SearchBar, UpdateDialog)
│
├── backend/                      # NestJS API server
│   ├── src/
│   │   ├── main.ts               # Bootstrap (Swagger, CORS, Helmet)
│   │   ├── app.module.ts         # Root module
│   │   ├── auth/                 # JWT Authentication
│   │   ├── categories/           # Categories CRUD
│   │   ├── products/             # Products CRUD
│   │   ├── partners/             # Partners CRUD
│   │   ├── sessions/             # Trading Sessions
│   │   ├── orders/               # Trade Orders
│   │   ├── transactions/         # Financial Transactions
│   │   ├── inventory/            # Inventory Adjustments
│   │   ├── payments/             # Payments (partial/full)
│   │   ├── store/                # Store Info
│   │   ├── sync/                 # Push/Pull Sync Engine
│   │   ├── common/               # Middleware (Request Logger)
│   │   └── config/               # Database config
│   ├── Dockerfile                # Multi-stage build
│   ├── docker-compose.prod.yml   # Production stack (PostgreSQL + API + Nginx)
│   └── nginx/                    # Nginx reverse proxy config
│
├── assets/images/                # App icons & logos
├── .github/workflows/            # CI/CD pipelines
│   ├── flutter-ci.yml            # Flutter lint + test
│   ├── backend-ci.yml            # NestJS lint + test
│   ├── build-windows.yml         # Build + Release Windows
│   └── db-backup.yml             # Database backup
├── render.yaml                   # Render.com deployment blueprint
├── release.ps1                   # Local release script (PowerShell)
└── pubspec.yaml                  # Flutter dependencies
```

---

## 🚀 Cài đặt & Khởi chạy

### Yêu cầu hệ thống

- **Flutter SDK** ≥ 3.11.0
- **Node.js** ≥ 20.0.0
- **PostgreSQL** ≥ 16 (cho backend)
- **Git** ≥ 2.x

### Frontend (Flutter)

```bash
# 1. Clone project
git clone https://github.com/NguyenQuangTrung19/FishCashing.git
cd FishCashing

# 2. Cài đặt dependencies
flutter pub get

# 3. Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# 4. Chạy ứng dụng
flutter run -d windows    # Windows
flutter run -d chrome      # Web (dev)
flutter run                # Android/iOS (cần device/emulator)
```

### Backend (NestJS)

```bash
# 1. Di chuyển vào thư mục backend
cd backend

# 2. Cài đặt dependencies
npm ci

# 3. Cấu hình môi trường
cp .env.example .env
# Chỉnh sửa .env: DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE, JWT_SECRET

# 4. Chạy development server
npm run start:dev

# Server khởi động tại http://localhost:3000
# Swagger docs tại http://localhost:3000/api/docs
```

### Build Production (Windows)

```powershell
# Dùng release script
.\release.ps1 1.3.3

# Hoặc build thủ công
flutter build windows --release
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "FishCash-POS-Windows.zip" -Force
```

---

## 🌐 Triển khai (Deployment)

### Backend — Render.com (Khuyến nghị)

1. Push code lên GitHub
2. Tạo Web Service trên [Render.com](https://render.com), trỏ repo
3. Render tự đọc `render.yaml` để deploy
4. Cấu hình `DATABASE_URL` qua Render Dashboard (trỏ tới Neon.tech)

### Backend — Docker (Self-hosted)

```bash
cd backend

# Cấu hình production env
cp .env.production.example .env.production
# Chỉnh sửa .env.production

# Khởi chạy stack (PostgreSQL + API + Nginx)
docker compose -f docker-compose.prod.yml up -d
```

Stack bao gồm:
- **PostgreSQL 16** — Database, persistent volume
- **NestJS API** — Node.js 20 Alpine, non-root user
- **Nginx** — Reverse proxy, SSL termination (port 80/443)

---

## 🗄️ Database Schema

### SQLite (Local — Drift)

10 bảng, schema version 4:

| Bảng | Mô tả | Khóa chính |
|------|--------|------------|
| `categories` | Danh mục sản phẩm | UUID (text) |
| `products` | Sản phẩm (giá tính bằng cents) | UUID (text) |
| `partners` | Nhà cung cấp / Khách mua | UUID (text) |
| `trading_sessions` | Phiên giao dịch sỉ | UUID (text) |
| `trade_orders` | Đơn hàng (buy/sell/pos) | UUID (text) |
| `order_items` | Chi tiết đơn hàng (quantity tính bằng grams) | UUID (text) |
| `transactions` | Giao dịch tài chính (income/expense) | UUID (text) |
| `store_infos` | Thông tin cửa hàng | UUID (text) |
| `inventory_adjustments` | Điều chỉnh kho | UUID (text) |
| `payments` | Thanh toán công nợ | UUID (text) |

> **Quy ước lưu trữ:**
> - Tiền tệ: `INTEGER` (cents, ×100) — Ví dụ: 150.000₫ → `15000000`
> - Khối lượng: `INTEGER` (milligrams, ×1000) — Ví dụ: 3.5 kg → `3500`
> - UUID: `TEXT` — Tạo bởi `uuid` package trên client

### PostgreSQL (Server — TypeORM)

Cấu trúc tương tự SQLite, bổ sung thêm:
- `NUMERIC(15,2)` cho tiền tệ
- `NUMERIC(12,3)` cho khối lượng
- `userId` và `isDeleted` cho multi-tenant & soft delete
- Index trên các cột thường query

---

## 📖 API Documentation

### Endpoints chính

| Method | Endpoint | Mô tả |
|--------|----------|--------|
| `GET` | `/api/v1/health` | Health check (monitoring) |
| `GET` | `/api/v1/health/detailed` | Health check chi tiết (memory, latency) |
| `POST` | `/api/v1/auth/setup` | Thiết lập cửa hàng mới (nhận JWT) |
| `CRUD` | `/api/v1/categories` | Quản lý danh mục |
| `CRUD` | `/api/v1/products` | Quản lý sản phẩm |
| `CRUD` | `/api/v1/partners` | Quản lý đối tác |
| `CRUD` | `/api/v1/sessions` | Quản lý phiên giao dịch |
| `CRUD` | `/api/v1/orders` | Quản lý đơn hàng |
| `CRUD` | `/api/v1/transactions` | Quản lý giao dịch tài chính |
| `CRUD` | `/api/v1/inventory` | Điều chỉnh kho |
| `CRUD` | `/api/v1/payments` | Thanh toán công nợ |
| `GET/PUT` | `/api/v1/store` | Thông tin cửa hàng |
| `POST` | `/api/v1/sync/push` | Đẩy dữ liệu lên server |
| `GET` | `/api/v1/sync/pull` | Kéo dữ liệu từ server |

### Authentication

- Sử dụng **Bearer Token** (JWT, long-lived — 365 ngày)
- Tạo token khi setup cửa hàng lần đầu
- Tất cả endpoints (trừ health & setup) yêu cầu Authorization header

### Swagger UI

Truy cập `/api/docs` khi chạy ở chế độ development.

---

## ⚡ CI/CD Pipeline

| Workflow | Trigger | Mô tả |
|----------|---------|--------|
| `flutter-ci.yml` | Push/PR to `main` | Lint + test Flutter |
| `backend-ci.yml` | Push/PR to `main` | Lint + test NestJS |
| `build-windows.yml` | Tag `v*` / Manual | Build Windows + tạo GitHub Release |
| `db-backup.yml` | Scheduled | Backup PostgreSQL database |

### Auto-Update Flow

```
1. Developer tạo tag v1.3.3 → push lên GitHub
2. GitHub Actions build Windows → upload FishCash-POS-Windows.zip
3. App kiểm tra GitHub Releases API → phát hiện phiên bản mới
4. Người dùng nhấn "Cập nhật" → tải ZIP, giải nén, tự cập nhật
```

---

## 👤 Tác giả

**Nguyễn Quang Trung** — [@NguyenQuangTrung19](https://github.com/NguyenQuangTrung19)

---

<p align="center">
  <sub>Built with ❤️ for Vietnamese seafood businesses</sub>
</p>
