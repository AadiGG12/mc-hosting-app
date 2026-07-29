# RenCloud — Minecraft Hosting App

A **Flutter** mobile app (Android + iOS) with a **FastAPI** backend for managing Minecraft hosting through the Pterodactyl panel.

![RenCloud](https://www.rencloud.online/og-image.png)

## Features

### 📱 Mobile App
- **Plans Catalog** — Browse hosting plans with pricing, RAM, player slots
- **Razorpay Checkout** — Pay for plans with auto server provisioning
- **Server Panel** — Full Pterodactyl experience: server list, power controls, console
- **In-App Admin** — Plan management for Pterodactyl root admins
- **OTA Updates** — GitHub Release-based Android updates

### 🖥️ Backend API
- **Auth Bridge** — Pterodactyl credential verification without exposing Application API key
- **Plans CRUD** — PostgreSQL-backed hosting plan management
- **Payment Processing** — Razorpay integration with webhook support
- **Auto Provisioning** — Automatic Pterodactyl server creation on payment

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter + Dart |
| State | Riverpod |
| Navigation | GoRouter |
| Backend | FastAPI + PostgreSQL |
| Payments | Razorpay |
| Panel | Pterodactyl Client API |
| CI/CD | GitHub Actions |

## Project Structure

```
Rencloud/
├── mobile/                    # Flutter app
│   ├── lib/
│   │   ├── core/              # Theme, API clients, router
│   │   └── features/          # Auth, plans, servers, admin, payments
│   └── pubspec.yaml
├── backend/
│   ├── app/
│   │   ├── routes/            # Auth, plans, admin, payments
│   │   ├── services/          # Pterodactyl client, Razorpay
│   │   └── models/            # Plan, Order
│   ├── docker-compose.yml
│   └── Dockerfile
├── .github/workflows/
│   └── release.yml
└── README.md
```

## Setup

### Prerequisites
- Flutter SDK 3.6+
- Docker Desktop
- Git
- Android Studio (for emulator)

### Backend

```bash
cd backend
cp .env.example .env
# Edit .env with your Pterodactyl API key and Razorpay keys
docker compose up -d
# API runs on http://localhost:8000
# Docs at http://localhost:8000/docs
```

### Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `PTERODACTYL_URL` | Your Pterodactyl panel URL |
| `PTERODACTYL_APP_KEY` | Application API key (never expose to client) |
| `JWT_SECRET` | Random secret for JWT signing |
| `RAZORPAY_KEY_ID` | Razorpay Key ID |
| `RAZORPAY_KEY_SECRET` | Razorpay Key Secret |
| `RAZORPAY_WEBHOOK_SECRET` | Razorpay Webhook Secret |

## Releasing

```bash
# Bump version in mobile/pubspec.yaml
git tag v1.1.0
git push origin main --tags
# GitHub Actions auto-builds APK and attaches to Release
```

## License

Proprietary — RenCloud Infrastructure
