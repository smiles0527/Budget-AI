# Budget AI

> Modern expense tracking platform with AI-powered receipt scanning, gamified budgeting, and intelligent insights for students and young professionals

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Last Commit](https://img.shields.io/badge/last%20commit-today-brightgreen.svg)
![Swift](https://img.shields.io/badge/swift-5.9-orange.svg)
![Python](https://img.shields.io/badge/python-3.11-blue.svg)
![Languages](https://img.shields.io/badge/languages-3-yellow.svg)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
  - [Project Index](#project-index)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Testing](#testing)
- [Documentation](#documentation)
- [Project Roadmap](#project-roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Overview

Budget AI is a comprehensive mobile expense tracking application built with SwiftUI and FastAPI, designed specifically for Gen Z and young professionals. The platform enables users to track expenses effortlessly by snapping photos of receipts, with AI-powered categorization, interactive dashboards, and gamified budgeting features.

The application leverages modern technologies including SwiftUI for native iOS development, FastAPI for the backend API, PostgreSQL for data persistence, and Docker for containerized deployment. With features like real-time receipt OCR processing, budget tracking with alerts, savings goals with progress tracking, and achievement badges, Budget AI provides a polished user experience that makes financial management simple and engaging.

---

## Features

| Feature | Summary |
|---------|---------|
| **Receipt Scanning** | AI-powered OCR extracts transaction details from receipt photos automatically |
| **Smart Categorization** | Multi-tier categorization system using merchant rules, keywords, and ML fallback |
| **Interactive Dashboards** | Real-time spending summaries, category breakdowns, and trend visualizations |
| **Budget Management** | Per-category budgets with automatic spending tracking and threshold alerts |
| **Gamification** | Achievement badges, streaks, and progress tracking to make budgeting fun |
| **Savings Goals** | Set and track savings goals with contribution tracking and milestone badges |
| **Advanced Analytics** | Spending trends, forecasts, insights, and recurring transaction detection |
| **Transaction Tags** | Custom tags with color coding for flexible transaction organization |
| **Linked Accounts** | Integration with bank account aggregation services (Plaid, TrueLayer) |
| **Data Export** | Premium CSV export with async job processing and download links |
| **Secure Auth** | Email/password, Google OAuth, and Apple Sign-In with session management |
| **Freemium Model** | Free tier with scan limits, Premium unlocks unlimited scans and advanced features |
| **Native iOS** | SwiftUI app with optimized UX, dark mode support, and native components |
| **Figma Integration** | Design system synced from Figma for seamless designer-developer workflow |
| **Push Notifications** | Budget alerts, goal achievements, and streak reminders (APNs/FCM) |

---

## Project Structure

```
Budget-AI/
├── backend/                    # FastAPI backend application
│   ├── app/
│   │   ├── routers/           # API route handlers
│   │   │   └── v1.py         # Main API endpoints
│   │   ├── utils/             # Utility modules
│   │   │   ├── analytics.py  # Spending analytics & insights
│   │   │   ├── badges.py      # Gamification badge logic
│   │   │   ├── categorize.py  # Transaction categorization
│   │   │   └── receipt_parser.py # OCR receipt parsing
│   │   ├── main.py            # FastAPI application entry
│   │   └── config.py         # Configuration management
│   ├── Dockerfile             # Backend container definition
│   ├── requirements.txt       # Python dependencies
│   └── tests/                 # Backend test suite
│
├── BudgetAI/                   # iOS SwiftUI application
│   ├── Views/                 # SwiftUI view components
│   │   ├── Dashboard/         # Dashboard & analytics views
│   │   ├── Transactions/      # Transaction management views
│   │   ├── Budgets/           # Budget tracking views
│   │   ├── Badges/            # Gamification views
│   │   └── Settings/          # App settings & profile
│   ├── ViewModels/            # MVVM view models
│   ├── Services/              # API client & services
│   │   ├── APIClient.swift    # Main API client
│   │   └── AuthManager.swift  # Authentication manager
│   ├── Utils/                 # Utility extensions
│   │   ├── DesignSystem.swift # Figma-synced design tokens
│   │   └── PremiumGate.swift  # Premium feature gating
│   └── BudgetAI.xcodeproj/     # Xcode project
│
├── db/                        # Database migrations
│   └── migrations/            # PostgreSQL schema migrations
│
├── worker/                    # Background worker (OCR processing)
│   ├── main.py                # Worker entry point
│   └── Dockerfile             # Worker container definition
│
├── docker-compose.yml         # Development environment setup
├── docs/                      # Additional documentation
└── planning.md               # Business plan and project planning
```

### Project Index

- **Backend API**: FastAPI REST API with async PostgreSQL, S3 storage, and background workers
- **iOS App**: Native SwiftUI application with MVVM architecture
- **Database**: PostgreSQL 15 with migrations and schema management
- **Storage**: MinIO (S3-compatible) for receipt image storage
- **Worker**: Python worker for async OCR processing and transaction creation
- **Design System**: Figma-integrated design tokens for consistent UI

---

## Getting Started

### Prerequisites

Before getting started with Budget AI, ensure your development environment meets the following requirements:

- **Docker Desktop**: Version 20.10 or higher (for backend services)
- **Xcode**: Version 15.0 or higher (for iOS development)
- **macOS**: Version 13.0 (Ventura) or higher
- **Python**: Version 3.11 (included in Docker, optional for local dev)
- **PostgreSQL**: Version 15 (included in Docker)
- **Node.js**: Version 18+ (optional, for design token scripts)

### Installation

Install Budget AI using the following method:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/Budget-AI.git
   cd Budget-AI
   ```

2. **Start backend services:**
   ```bash
   # Start database and storage
   docker compose up -d db minio
   
   # Wait for services to be ready (about 10 seconds)
   sleep 10
   
   # Apply database migrations
   docker exec snapbudget-postgres sh -c "mkdir -p /migrations"
   for file in db/migrations/*.sql; do
     docker cp "$file" snapbudget-postgres:/migrations/$(basename "$file")
     docker exec -e PGPASSWORD=password snapbudget-postgres psql -h 127.0.0.1 -U app -d appdb -f "/migrations/$(basename "$file")" || true
   done
   
   # Start API and worker
   docker compose up -d --build api worker
   ```

3. **Open iOS project:**
   ```bash
   open BudgetAI.xcodeproj
   ```

### Usage

#### Run Budget AI in different modes:

**Development Mode**

```bash
# Start backend services
> docker compose up -d db minio api worker
# Backend API running at http://localhost:8000

# Run iOS app
> open BudgetAI.xcodeproj
# Select iPhone 15 Pro simulator
# Press ⌘R to run
```

**Production Mode**

```bash
# Build and run with Docker Compose
> docker compose up -d --build
# All services running in production mode
```

**Development Tools**

```bash
# Check backend API health
> curl http://localhost:8000/healthz

# View API logs
> docker compose logs api

# View worker logs
> docker compose logs worker

# Access MinIO console
> open http://localhost:9001
# Login: minioadmin / minioadmin
```

#### The application will be available at:

- **iOS Simulator**: `http://localhost:8000/v1` (API endpoint)
- **Backend API**: `http://localhost:8000`
- **API Docs**: `http://localhost:8000/docs` (Swagger UI)
- **MinIO Console**: `http://localhost:9001`
- **PostgreSQL**: `localhost:5432` (user: `app`, password: `password`, db: `appdb`)

### Testing

Budget AI includes comprehensive testing capabilities:

**Backend Testing**

```bash
# Run backend tests
> cd backend && pytest tests/
```

**iOS Testing**

```bash
# Run unit tests in Xcode
> ⌘U (or Product → Test)

# Run UI tests
> Select test scheme and run
```

**Manual Testing Flow**

1. **Sign Up**: Create account with email/password or OAuth
2. **Upload Receipt**: Take photo or select from library
3. **View Transaction**: Check dashboard for processed transaction
4. **Create Budget**: Set spending limit for a category
5. **Track Progress**: View badges, streaks, and savings goals
6. **Export Data**: Premium users can export CSV (requires subscription)

---

## Documentation

Additional documentation is available in the `docs/` directory:

- **[Setup Guide](docs/SETUP.md)** - Detailed setup instructions for development environment
- **[Backend API](docs/BACKEND.md)** - Complete backend API documentation and features
- **[Mobile App](docs/MOBILE.md)** - iOS app integration status and API reference
- **[Figma Integration](docs/FIGMA.md)** - Design system setup and sync instructions
- **[Roadmap](docs/ROADMAP.md)** - Planned features and development roadmap
- **[iOS Setup](docs/IOS_SETUP.md)** - iOS-specific setup and troubleshooting

---

## Project Roadmap

### Completed Features

- [x] Authentication (Email, Google, Apple)
- [x] Receipt scanning with OCR
- [x] Transaction management (CRUD)
- [x] Budget tracking with alerts
- [x] Savings goals with contributions
- [x] Dashboard with analytics
- [x] Badge system and gamification (collection view, celebrations, streaks)
- [x] Tag management
- [x] Linked accounts integration
- [x] CSV export (premium)
- [x] Figma design system integration
- [x] Premium feature gating and usage limits
- [x] Auto badge detection and celebrations

### In Progress / High Priority

- [ ] Receipt image viewing and gallery
- [ ] Charts and visualizations (trends, category breakdowns)
- [ ] Push notifications (APNs/FCM)
- [ ] Subscription management UI (cancel, change plan)

### Planned Features

- [ ] Social sharing features
- [ ] Bank account sync (Plaid integration)
- [ ] Recurring transaction detection UI
- [ ] Spending insights recommendations UI
- [ ] Apple Watch app
- [ ] Widget support
- [ ] Voice commands

---

## Contributing

We welcome contributions to Budget AI! Here are several ways you can help:

- **Join the Discussions**: Share your insights, provide feedback, or ask questions in our [Discussions](https://github.com/yourusername/Budget-AI/discussions)
- **Report Issues**: Submit bugs found or log feature requests for the `Budget-AI` project
- **Submit Pull Requests**: Review open PRs, and submit your own PRs

### Contributing Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the existing style guidelines and includes appropriate tests.

---

## License

This project is protected under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.

---

## Acknowledgments

Budget AI is built with the following amazing technologies and libraries:

- **[FastAPI](https://fastapi.tiangolo.com/)** - Modern Python web framework for building APIs
- **[SwiftUI](https://developer.apple.com/xcode/swiftui/)** - Declarative UI framework for iOS
- **[PostgreSQL](https://www.postgresql.org/)** - Advanced open-source relational database
- **[MinIO](https://min.io/)** - High-performance object storage compatible with S3
- **[Tesseract OCR](https://github.com/tesseract-ocr/tesseract)** - OCR engine for receipt text extraction
- **[Docker](https://www.docker.com/)** - Containerization platform for deployment
- **[Figma API](https://www.figma.com/developers/api)** - Design system integration
- **[Stripe](https://stripe.com/)** - Payment processing for premium subscriptions
- **[Plaid](https://plaid.com/)** - Bank account integration (planned)

Special thanks to the open-source community for the incredible tools that make this project possible.
