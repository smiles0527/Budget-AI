# SnapBudget Backend API Documentation

## Overview

The SnapBudget backend is a production-ready REST API built with FastAPI, providing comprehensive financial tracking and analytics capabilities. The system supports receipt scanning, transaction management, budget tracking, savings goals, and advanced analytics with AI-powered categorization.

## Core Features

### Authentication and User Management

The API supports multiple authentication providers including email/password, Google OAuth, and Apple Sign-In. Session management uses refresh tokens with rotation capabilities. User profiles include display name, currency preferences, timezone settings, and marketing opt-in controls.

### Receipt Processing

Receipts are processed through an asynchronous OCR pipeline. Users upload receipt images via presigned S3 URLs, and a background worker extracts structured data including merchant name, transaction date, total amount, tax, tip, and individual line items. The system supports JPEG, PNG, and PDF formats with configurable size limits.

### Transaction Management

Transactions can be created automatically from receipt scans or manually entered by premium users. The API provides full CRUD operations with cursor-based pagination, filtering by date range and category, and full-text search capabilities. Each transaction can include line items, tags, and custom metadata.

### Budget Management

Users can create per-category budgets for specific time periods. The system automatically tracks spending against budgets and generates alerts when thresholds are exceeded. Budget alerts are created at 90% usage (warning) and 100% usage (exceeded), with support for dismissing and resolving alerts.

### Savings Goals

The savings goals feature allows users to set financial targets with optional target dates. Users can track contributions toward goals, and the system automatically awards badges when goals are achieved. Progress is calculated in real-time with percentage completion indicators.

### Linked Accounts

The API supports integration with financial account aggregation services such as Plaid, TrueLayer, and MX. Linked accounts track balance history and import runs, enabling automatic transaction synchronization from bank accounts.

### Analytics and Insights

The analytics system provides multiple endpoints for spending analysis. Trends analysis shows month-over-month spending patterns with trend indicators. Forecasting uses moving averages to predict future spending. The insights endpoint generates actionable recommendations based on spending patterns, budget adherence, and category concentration.

Recurring transaction detection identifies potential subscriptions and recurring charges by analyzing merchant and amount patterns over time. Period comparison allows users to compare spending between any two time periods with category-level breakdowns.

### Categorization System

Transactions are automatically categorized using a multi-tier system. Merchant rules match transactions by merchant name patterns with configurable confidence thresholds. Keyword rules search transaction text for category indicators. When rules don't match with sufficient confidence, a machine learning fallback uses keyword scoring to assign categories. The system supports 12 predefined categories: groceries, dining, transport, shopping, entertainment, subscriptions, utilities, health, education, travel, income_adjustment, and other.

### Gamification

The badge system awards achievements automatically based on user behavior. Badges include first scan, tracking streaks (7-day and 30-day), savings milestones ($100, $500, $1000), budget adherence, and transaction count milestones. Badge awarding is integrated throughout the system and occurs automatically when qualifying conditions are met.

### Search and Organization

Full-text search uses PostgreSQL's text search capabilities to search transactions by merchant name, category, and subcategory. Transaction tags allow users to create custom organizational labels with optional color coding. Tags can be assigned to multiple transactions and used for filtering and organization.

### Data Export

Premium users can export transaction data as CSV files. Exports are processed asynchronously with job status tracking. The export includes all transaction fields and can be filtered by date range.

### Subscriptions

The API integrates with Stripe for subscription management. Users can initiate checkout sessions, and webhook handlers manage subscription lifecycle events including creation, updates, cancellations, and payment failures. Subscription status gates premium features such as manual transactions and CSV exports.

### Push Notifications

The system supports device registration for push notifications via Apple Push Notification Service (APNS) and Firebase Cloud Messaging (FCM). Device tokens are stored and can be used to send alerts for budget warnings, goal achievements, and other events.

## API Endpoints

Authentication

POST /v1/auth/signup - Create account with email and password
POST /v1/auth/login - Authenticate with email and password
POST /v1/auth/google - Authenticate with Google OAuth token
POST /v1/auth/apple - Authenticate with Apple Sign-In token
GET /v1/auth/me - Get current user information and subscription status
POST /v1/auth/logout - Invalidate current session
POST /v1/auth/logout_all - Invalidate all user sessions
POST /v1/auth/rotate - Rotate session token

Profile Management

PATCH /v1/profile - Update user profile settings

Receipts

POST /v1/receipts/upload - Request presigned URL for receipt upload
POST /v1/receipts/confirm - Confirm receipt upload and enqueue OCR processing
GET /v1/receipts/{id} - Get receipt details and processing status

Transactions

GET /v1/transactions - List transactions with pagination and filtering
GET /v1/transactions/{id} - Get transaction details including line items
GET /v1/transactions/{id}/items - Get line items for a transaction
GET /v1/transactions/search - Full-text search transactions
POST /v1/transactions/manual - Create manual transaction (premium)
PATCH /v1/transactions/{id} - Update transaction fields
DELETE /v1/transactions/{id} - Delete transaction

Budgets

PUT /v1/budgets - Create or update budget
GET /v1/budgets - List budgets with optional period filtering

Budget Alerts

GET /v1/alerts - List budget alerts with optional status filter
PATCH /v1/alerts/{id} - Update alert status (dismiss or resolve)

Dashboard

GET /v1/dashboard/summary - Get spending summary for a period
GET /v1/dashboard/categories - Get category breakdown for a period

Analytics

GET /v1/analytics/trends - Get month-over-month spending trends
GET /v1/analytics/forecast - Get spending forecast for future months
GET /v1/analytics/insights - Get actionable spending insights
GET /v1/analytics/recurring - Detect recurring transactions
GET /v1/analytics/compare - Compare spending between two periods

Savings Goals

POST /v1/savings/goals - Create savings goal
GET /v1/savings/goals - List savings goals with progress
GET /v1/savings/goals/{id} - Get goal details with contributions
POST /v1/savings/goals/{id}/contributions - Add contribution to goal
PATCH /v1/savings/goals/{id} - Update goal
DELETE /v1/savings/goals/{id} - Cancel goal

Tags

POST /v1/tags - Create transaction tag
GET /v1/tags - List user's tags
POST /v1/transactions/{id}/tags/{tag_id} - Assign tag to transaction
DELETE /v1/transactions/{id}/tags/{tag_id} - Remove tag from transaction
DELETE /v1/tags/{id} - Delete tag

Linked Accounts

POST /v1/linked-accounts - Link financial account
GET /v1/linked-accounts - List linked accounts with balances
GET /v1/linked-accounts/{id} - Get account details with history
POST /v1/linked-accounts/{id}/balances - Update account balance
DELETE /v1/linked-accounts/{id} - Revoke account link

Badges

GET /v1/badges - List all available badges
GET /v1/user/badges - List user's earned badges

Usage

GET /v1/usage - Get monthly scan usage and remaining quota

Exports

POST /v1/export/csv - Request CSV export (premium)
GET /v1/export/csv/{job_id} - Get export job status

Subscriptions

GET /v1/subscription - Get current subscription status
POST /v1/subscription/checkout - Initiate Stripe checkout session
POST /v1/subscription/webhook - Stripe webhook handler

Push Notifications

POST /v1/push/devices - Register push notification device
GET /v1/push/devices - List registered devices
DELETE /v1/push/devices/{id} - Unregister device

Account Management

DELETE /v1/account - Schedule account deletion

Rules Management

GET /v1/rules/merchant - List merchant categorization rules
POST /v1/rules/merchant - Create merchant rule (admin)
GET /v1/rules/keyword - List keyword categorization rules
POST /v1/rules/keyword - Create keyword rule (admin)

## Technical Architecture

### Database

The system uses PostgreSQL 15 with asyncpg for asynchronous database access. The schema includes 20+ tables with proper foreign key constraints, indexes optimized for common queries, and materialized views for analytics. Database functions handle complex calculations such as remaining scan quotas and dashboard aggregations.

### Storage

Receipt images and export files are stored in S3-compatible object storage (MinIO for development, AWS S3 for production). The API uses presigned URLs for direct client-to-storage uploads, reducing server load and improving upload performance.

### Job Processing

Background jobs are processed by a separate worker service that polls for pending jobs. The worker handles OCR processing, CSV export generation, and account deletion. Jobs are tracked in the database with status, error handling, and retry logic.

### Observability

The API exposes Prometheus metrics for monitoring request rates, latencies, and error rates. Request IDs are generated for each request and included in logs for tracing. Structured JSON logging is supported for production environments.

### Security

Password hashing uses bcrypt with appropriate cost factors. Session tokens are hashed before storage. The API includes CORS configuration, security headers, rate limiting (120 requests per minute per IP), and input validation. Admin operations require authentication via header secret in non-development environments.

### Performance

The API uses async/await throughout for non-blocking I/O operations. Cursor-based pagination prevents performance degradation with large datasets. Database queries are optimized with appropriate indexes, and materialized views cache expensive analytics calculations.

## Data Models

### Transaction

Transactions represent individual spending events. Fields include merchant name, transaction date, total amount in cents, optional tax and tip amounts, currency code, category, subcategory, source (receipt, manual, or import), and raw OCR text stored as JSONB.

### Receipt

Receipts track the upload and processing status of receipt images. Each receipt has a storage URI, OCR processing status (pending, processing, done, failed), timestamps for upload and processing, and optional failure reason.

### Budget

Budgets define spending limits for specific categories over time periods. Each budget includes period start and end dates, category, and limit amount in cents. The system enforces uniqueness per user, period, and category combination.

### Savings Goal

Savings goals track progress toward financial targets. Goals include a name, optional category, target amount, start date, optional target date, and status (active, paused, achieved, cancelled). Contributions are tracked separately with timestamps and optional notes.

### Badge

Badges represent achievements users can earn. Each badge has a unique code, display name, and description. User badge assignments track when badges were awarded.

## Error Handling

The API uses consistent error response format with error code, message, and optional details. Common error codes include authentication failures, validation errors, resource not found, premium feature gates, and rate limit exceeded.

## Rate Limiting

Default rate limit is 120 requests per minute per client IP address. Rate limiting is implemented in-memory and applies to all endpoints except health checks.

## Premium Features

Premium subscription is required for manual transaction creation, CSV exports, and unlimited receipt scans. Free tier includes 20 scans per month with basic features.
