//
//  APIClient.swift
//  testapp
//
//  API client for SnapBudget backend
//

import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL: String
    private var authToken: String?
    
    private init() {
        // TODO: Move to config/environment variable
        // For simulator: use localhost
        // For real device: use your Mac's IP address (e.g., "http://192.168.1.100:8000/v1")
        self.baseURL = "http://localhost:8000/v1"
    }
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(errorData.error.message)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Authentication
    
    func signup(email: String, password: String) async throws -> SignupResponse {
        struct SignupRequest: Codable {
            let email: String
            let password: String
        }
        
        return try await makeRequest(
            endpoint: "/auth/signup",
            method: "POST",
            body: SignupRequest(email: email, password: password)
        )
    }
    
    func login(email: String, password: String) async throws -> LoginResponse {
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }
        
        let response: LoginResponse = try await makeRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password)
        )
        
        setAuthToken(response.token)
        return response
    }
    
    func loginWithGoogle(idToken: String) async throws -> LoginResponse {
        struct GoogleLoginRequest: Codable {
            let id_token: String
        }
        
        let response: LoginResponse = try await makeRequest(
            endpoint: "/auth/google",
            method: "POST",
            body: GoogleLoginRequest(id_token: idToken)
        )
        
        setAuthToken(response.token)
        return response
    }
    
    func loginWithApple(identityToken: String) async throws -> LoginResponse {
        struct AppleLoginRequest: Codable {
            let identity_token: String
        }
        
        let response: LoginResponse = try await makeRequest(
            endpoint: "/auth/apple",
            method: "POST",
            body: AppleLoginRequest(identity_token: identityToken)
        )
        
        setAuthToken(response.token)
        return response
    }
    
    func getCurrentUser() async throws -> UserResponse {
        return try await makeRequest(endpoint: "/auth/me")
    }
    
    func logout() async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/auth/logout",
            method: "POST"
        )
        setAuthToken(nil)
    }
    
    // MARK: - Receipts
    
    func uploadReceipt(mime: String? = nil, size: Int? = nil) async throws -> ReceiptUploadResponse {
        struct ReceiptCreateRequest: Codable {
            let mime: String?
            let size: Int?
        }
        
        return try await makeRequest(
            endpoint: "/receipts/upload",
            method: "POST",
            body: ReceiptCreateRequest(mime: mime, size: size)
        )
    }
    
    func confirmReceipt(receiptId: String, objectKey: String, mime: String?, size: Int?) async throws {
        struct ReceiptConfirmRequest: Codable {
            let receipt_id: String
            let object_key: String
            let mime: String?
            let size: Int?
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/receipts/confirm",
            method: "POST",
            body: ReceiptConfirmRequest(
                receipt_id: receiptId,
                object_key: objectKey,
                mime: mime,
                size: size
            )
        )
    }
    
    func getReceipt(id: String) async throws -> Receipt {
        return try await makeRequest(endpoint: "/receipts/\(id)")
    }
    
    // MARK: - Transactions
    
    func getTransactions(
        limit: Int = 50,
        cursor: String? = nil,
        fromDate: String? = nil,
        toDate: String? = nil,
        category: String? = nil
    ) async throws -> TransactionsResponse {
        var endpoint = "/transactions?limit=\(limit)"
        if let cursor = cursor { endpoint += "&cursor=\(cursor)" }
        if let fromDate = fromDate { endpoint += "&from_date=\(fromDate)" }
        if let toDate = toDate { endpoint += "&to_date=\(toDate)" }
        if let category = category { endpoint += "&category=\(category)" }
        
        return try await makeRequest(endpoint: endpoint)
    }
    
    func getTransaction(id: String) async throws -> Transaction {
        return try await makeRequest(endpoint: "/transactions/\(id)")
    }
    
    func searchTransactions(query: String, limit: Int = 50, cursor: String? = nil) async throws -> TransactionsResponse {
        var endpoint = "/transactions/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&limit=\(limit)"
        if let cursor = cursor { endpoint += "&cursor=\(cursor)" }
        
        return try await makeRequest(endpoint: endpoint)
    }
    
    // MARK: - Dashboard
    
    func getDashboardSummary(period: String = "month", anchor: String? = nil) async throws -> DashboardSummary {
        var endpoint = "/dashboard/summary?period=\(period)"
        if let anchor = anchor { endpoint += "&anchor=\(anchor)" }
        
        return try await makeRequest(endpoint: endpoint)
    }
    
    func getDashboardCategories(period: String = "month", anchor: String? = nil) async throws -> DashboardCategoriesResponse {
        var endpoint = "/dashboard/categories?period=\(period)"
        if let anchor = anchor { endpoint += "&anchor=\(anchor)" }
        
        return try await makeRequest(endpoint: endpoint)
    }
    
    // MARK: - Budgets
    
    func createBudget(periodStart: String, periodEnd: String, category: String, limitCents: Int) async throws {
        struct BudgetRequest: Codable {
            let period_start: String
            let period_end: String
            let category: String
            let limit_cents: Int
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/budgets",
            method: "PUT",
            body: BudgetRequest(
                period_start: periodStart,
                period_end: periodEnd,
                category: category,
                limit_cents: limitCents
            )
        )
    }
    
    func getBudgets(periodStart: String? = nil, periodEnd: String? = nil) async throws -> BudgetsResponse {
        var endpoint = "/budgets"
        if let start = periodStart, let end = periodEnd {
            endpoint += "?period_start=\(start)&period_end=\(end)"
        }
        
        return try await makeRequest(endpoint: endpoint)
    }
    
    // MARK: - Savings Goals
    
    func createSavingsGoal(
        name: String,
        category: String?,
        targetCents: Int,
        startDate: String?,
        targetDate: String?
    ) async throws -> SavingsGoalResponse {
        struct SavingsGoalRequest: Codable {
            let name: String
            let category: String?
            let target_cents: Int
            let start_date: String?
            let target_date: String?
        }
        
        return try await makeRequest(
            endpoint: "/savings/goals",
            method: "POST",
            body: SavingsGoalRequest(
                name: name,
                category: category,
                target_cents: targetCents,
                start_date: startDate,
                target_date: targetDate
            )
        )
    }
    
    func getSavingsGoals(status: String? = nil) async throws -> SavingsGoalsResponse {
        var endpoint = "/savings/goals"
        if let status = status {
            endpoint += "?status=\(status)"
        }
        
        return try await makeRequest(endpoint: endpoint)
    }
    
    func addContribution(goalId: String, amountCents: Int, note: String?) async throws -> ContributionResponse {
        struct ContributionRequest: Codable {
            let amount_cents: Int
            let note: String?
        }
        
        return try await makeRequest(
            endpoint: "/savings/goals/\(goalId)/contributions",
            method: "POST",
            body: ContributionRequest(amount_cents: amountCents, note: note)
        )
    }
    
    // MARK: - Badges
    
    func getBadges() async throws -> BadgesResponse {
        return try await makeRequest(endpoint: "/badges")
    }
    
    func getUserBadges() async throws -> UserBadgesResponse {
        return try await makeRequest(endpoint: "/user/badges")
    }
    
    // MARK: - Usage
    
    func getUsage() async throws -> UsageResponse {
        return try await makeRequest(endpoint: "/usage")
    }
    
    // MARK: - Budget Alerts
    
    func getAlerts(status: String? = nil) async throws -> AlertsResponse {
        var endpoint = "/alerts"
        if let status = status {
            endpoint += "?status=\(status)"
        }
        return try await makeRequest(endpoint: endpoint)
    }
    
    func updateAlert(alertId: String, status: String) async throws {
        struct AlertUpdateRequest: Codable {
            let status: String
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/alerts/\(alertId)",
            method: "PATCH",
            body: AlertUpdateRequest(status: status)
        )
    }
    
    // MARK: - Analytics
    
    func getSpendingTrends(months: Int = 6) async throws -> SpendingTrendsResponse {
        return try await makeRequest(endpoint: "/analytics/trends?months=\(months)")
    }
    
    func getSpendingForecast(monthsAhead: Int = 1) async throws -> SpendingForecastResponse {
        return try await makeRequest(endpoint: "/analytics/forecast?months_ahead=\(monthsAhead)")
    }
    
    func getSpendingInsights() async throws -> SpendingInsightsResponse {
        return try await makeRequest(endpoint: "/analytics/insights")
    }
    
    func getRecurringTransactions() async throws -> RecurringTransactionsResponse {
        return try await makeRequest(endpoint: "/analytics/recurring")
    } 
    
    func getCategoryComparison(
        period1Start: String,
        period1End: String,
        period2Start: String,
        period2End: String
    ) async throws -> CategoryComparisonResponse {
        var endpoint = "/analytics/compare"
        endpoint += "?period1_start=\(period1Start)&period1_end=\(period1End)"
        endpoint += "&period2_start=\(period2Start)&period2_end=\(period2End)"
        return try await makeRequest(endpoint: endpoint)
    }
    
    // MARK: - Profile
    
    func updateProfile(
        displayName: String? = nil,
        currencyCode: String? = nil,
        timezone: String? = nil,
        notificationBudgetAlerts: Bool? = nil,
        notificationGoalAchieved: Bool? = nil,
        notificationStreakReminders: Bool? = nil,
        notificationWeeklySummary: Bool? = nil
    ) async throws {
        struct ProfileUpdateRequest: Codable {
            let display_name: String?
            let currency_code: String?
            let timezone: String?
            let notification_budget_alerts: Bool?
            let notification_goal_achieved: Bool?
            let notification_streak_reminders: Bool?
            let notification_weekly_summary: Bool?
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/profile",
            method: "PATCH",
            body: ProfileUpdateRequest(
                display_name: displayName,
                currency_code: currencyCode,
                timezone: timezone,
                notification_budget_alerts: notificationBudgetAlerts,
                notification_goal_achieved: notificationGoalAchieved,
                notification_streak_reminders: notificationStreakReminders,
                notification_weekly_summary: notificationWeeklySummary
            )
        )
    }
    
    // MARK: - Transactions Management
    
    func createManualTransaction(
        merchant: String,
        txnDate: String,
        totalCents: Int,
        taxCents: Int? = nil,
        tipCents: Int? = nil,
        currencyCode: String = "USD",
        category: String? = nil,
        subcategory: String? = nil
    ) async throws -> ManualTransactionResponse {
        struct ManualTransactionRequest: Codable {
            let merchant: String
            let txn_date: String
            let total_cents: Int
            let tax_cents: Int?
            let tip_cents: Int?
            let currency_code: String
            let category: String?
            let subcategory: String?
        }
        
        return try await makeRequest(
            endpoint: "/transactions/manual",
            method: "POST",
            body: ManualTransactionRequest(
                merchant: merchant,
                txn_date: txnDate,
                total_cents: totalCents,
                tax_cents: taxCents,
                tip_cents: tipCents,
                currency_code: currencyCode,
                category: category,
                subcategory: subcategory
            )
        )
    }
    
    func updateTransaction(
        id: String,
        merchant: String? = nil,
        txnDate: String? = nil,
        totalCents: Int? = nil,
        taxCents: Int? = nil,
        tipCents: Int? = nil,
        category: String? = nil,
        subcategory: String? = nil
    ) async throws {
        struct TransactionUpdateRequest: Codable {
            let merchant: String?
            let txn_date: String?
            let total_cents: Int?
            let tax_cents: Int?
            let tip_cents: Int?
            let category: String?
            let subcategory: String?
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/transactions/\(id)",
            method: "PATCH",
            body: TransactionUpdateRequest(
                merchant: merchant,
                txn_date: txnDate,
                total_cents: totalCents,
                tax_cents: taxCents,
                tip_cents: tipCents,
                category: category,
                subcategory: subcategory
            )
        )
    }
    
    func deleteTransaction(id: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/transactions/\(id)",
            method: "DELETE"
        )
    }
    
    func getTransactionItems(id: String) async throws -> TransactionItemsResponse {
        return try await makeRequest(endpoint: "/transactions/\(id)/items")
    }
    
    // MARK: - Savings Goals Management
    
    func getSavingsGoal(id: String) async throws -> SavingsGoal {
        return try await makeRequest(endpoint: "/savings/goals/\(id)")
    }
    
    func updateSavingsGoal(
        id: String,
        name: String? = nil,
        category: String? = nil,
        targetCents: Int? = nil,
        targetDate: String? = nil,
        status: String? = nil
    ) async throws {
        struct SavingsGoalUpdateRequest: Codable {
            let name: String?
            let category: String?
            let target_cents: Int?
            let target_date: String?
            let status: String?
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/savings/goals/\(id)",
            method: "PATCH",
            body: SavingsGoalUpdateRequest(
                name: name,
                category: category,
                target_cents: targetCents,
                target_date: targetDate,
                status: status
            )
        )
    }
    
    func deleteSavingsGoal(id: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/savings/goals/\(id)",
            method: "DELETE"
        )
    }
    
    // MARK: - Export
    
    func exportCSV(
        fromDate: String,
        toDate: String,
        wait: Bool = false,
        timeoutSeconds: Int? = nil
    ) async throws -> ExportCSVResponse {
        struct ExportRequest: Codable {
            let from_date: String
            let to_date: String
            let wait: Bool?
            let timeout_seconds: Int?
        }
        
        return try await makeRequest(
            endpoint: "/export/csv",
            method: "POST",
            body: ExportRequest(
                from_date: fromDate,
                to_date: toDate,
                wait: wait,
                timeout_seconds: timeoutSeconds
            )
        )
    }
    
    func getExportStatus(jobId: String) async throws -> ExportCSVResponse {
        return try await makeRequest(endpoint: "/export/csv/\(jobId)")
    }
    
    // MARK: - Subscription
    
    func getSubscription() async throws -> SubscriptionResponse {
        return try await makeRequest(endpoint: "/subscription")
    }
    
    func getSubscriptionCheckout() async throws -> SubscriptionCheckoutResponse {
        struct EmptyBody: Codable {}
        return try await makeRequest(
            endpoint: "/subscription/checkout",
            method: "POST",
            body: EmptyBody()
        )
    }
    
    // MARK: - Push Notifications
    
    func registerPushDevice(platform: String, token: String) async throws {
        struct PushDeviceRegisterRequest: Codable {
            let platform: String
            let token: String
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/push/devices",
            method: "POST",
            body: PushDeviceRegisterRequest(platform: platform, token: token)
        )
    }
    
    func getPushDevices() async throws -> PushDevicesResponse {
        return try await makeRequest(endpoint: "/push/devices")
    }
    
    func deletePushDevice(deviceId: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/push/devices/\(deviceId)",
            method: "DELETE"
        )
    }
    
    // MARK: - Account
    
    func deleteAccount() async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/account",
            method: "DELETE"
        )
    }
    
    // MARK: - Tags
    
    func createTag(name: String, color: String? = nil) async throws -> TagResponse {
        struct TagCreateRequest: Codable {
            let name: String
            let color: String?
        }
        
        return try await makeRequest(
            endpoint: "/tags",
            method: "POST",
            body: TagCreateRequest(name: name, color: color)
        )
    }
    
    func getTags() async throws -> TagsResponse {
        return try await makeRequest(endpoint: "/tags")
    }
    
    func addTagToTransaction(transactionId: String, tagId: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/transactions/\(transactionId)/tags/\(tagId)",
            method: "POST"
        )
    }
    
    func removeTagFromTransaction(transactionId: String, tagId: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/transactions/\(transactionId)/tags/\(tagId)",
            method: "DELETE"
        )
    }
    
    func deleteTag(tagId: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/tags/\(tagId)",
            method: "DELETE"
        )
    }
    
    // MARK: - Linked Accounts
    
    func createLinkedAccount(
        provider: String,
        providerAccountId: String,
        institutionName: String,
        accountMask: String?,
        accountName: String,
        accountType: String,
        accountSubtype: String?
    ) async throws -> LinkedAccountResponse {
        struct LinkedAccountCreateRequest: Codable {
            let provider: String
            let provider_account_id: String
            let institution_name: String
            let account_mask: String?
            let account_name: String
            let account_type: String
            let account_subtype: String?
        }
        
        return try await makeRequest(
            endpoint: "/linked-accounts",
            method: "POST",
            body: LinkedAccountCreateRequest(
                provider: provider,
                provider_account_id: providerAccountId,
                institution_name: institutionName,
                account_mask: accountMask,
                account_name: accountName,
                account_type: accountType,
                account_subtype: accountSubtype
            )
        )
    }
    
    func getLinkedAccounts(status: String? = nil) async throws -> LinkedAccountsResponse {
        var endpoint = "/linked-accounts"
        if let status = status {
            endpoint += "?status=\(status)"
        }
        return try await makeRequest(endpoint: endpoint)
    }
    
    func getLinkedAccount(id: String) async throws -> LinkedAccount {
        return try await makeRequest(endpoint: "/linked-accounts/\(id)")
    }
    
    func updateLinkedAccountBalance(
        accountId: String,
        currentCents: Int?,
        availableCents: Int?,
        currencyCode: String = "USD"
    ) async throws {
        struct BalanceUpdateRequest: Codable {
            let current_cents: Int?
            let available_cents: Int?
            let currency_code: String
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/linked-accounts/\(accountId)/balances",
            method: "POST",
            body: BalanceUpdateRequest(
                current_cents: currentCents,
                available_cents: availableCents,
                currency_code: currencyCode
            )
        )
    }
    
    func deleteLinkedAccount(id: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/linked-accounts/\(id)",
            method: "DELETE"
        )
    }
}

// MARK: - Error Types

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case decodingError
}

struct APIErrorResponse: Codable {
    let error: ErrorDetail
}

struct ErrorDetail: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

// MARK: - Response Models

struct SignupResponse: Codable {
    let id: String
}

struct LoginResponse: Codable {
    let token: String
}

struct UserResponse: Codable {
    let user: User
    let subscription: Subscription?
    let profile: Profile?
}

struct User: Codable {
    let id: String
    let email: String
    let auth_provider: String
    let created_at: String
}

struct Subscription: Codable {
    let plan: String
    let status: String
}

struct Profile: Codable {
    let user_id: String
    let display_name: String?
    let currency_code: String
    let timezone: String
    let marketing_opt_in: Bool
    let notification_budget_alerts: Bool?
    let notification_goal_achieved: Bool?
    let notification_streak_reminders: Bool?
    let notification_weekly_summary: Bool?
}

struct ReceiptUploadResponse: Codable {
    let receipt_id: String
    let upload_url: String
    let object_key: String
}

struct Receipt: Codable {
    let id: String
    let user_id: String
    let storage_uri: String
    let ocr_status: String
    let uploaded_at: String?
    let processed_at: String?
    let image_url: String? // Presigned URL for viewing the receipt image
}

struct TransactionsResponse: Codable {
    let items: [Transaction]
    let next_cursor: String?
}

struct Transaction: Codable {
    let id: String
    let user_id: String
    let receipt_id: String?
    let merchant: String?
    let txn_date: String
    let total_cents: Int
    let tax_cents: Int?
    let tip_cents: Int?
    let currency_code: String
    let category: String
    let subcategory: String?
    let source: String
    let created_at: String
    let items: [TransactionItem]?
}

struct TransactionItem: Codable {
    let id: String
    let transaction_id: String
    let line_index: Int
    let description: String?
    let quantity: Double?
    let unit_price_cents: Int?
    let total_cents: Int?
    let category: String?
}

struct DashboardSummary: Codable {
    let total_spend_cents: Int
    let txn_count: Int
    let avg_txn_cents: Double
    let start_date: String
    let end_date: String
}

struct DashboardCategoriesResponse: Codable {
    let items: [CategorySpending]
}

struct CategorySpending: Codable {
    let category: String
    let total_spend_cents: Int
    let txn_count: Int
}

struct BudgetsResponse: Codable {
    let items: [Budget]
}

struct Budget: Codable {
    let id: String
    let user_id: String
    let period_start: String
    let period_end: String
    let category: String
    let limit_cents: Int
    let created_at: String
}

struct SavingsGoalsResponse: Codable {
    let items: [SavingsGoal]
}

struct SavingsGoal: Codable {
    let id: String
    let user_id: String
    let name: String
    let category: String?
    let target_cents: Int
    let start_date: String
    let target_date: String?
    let status: String
    let created_at: String
    let contributed_cents: Int?
    let progress_percent: Int?
}

struct SavingsGoalResponse: Codable {
    let id: String
}

struct ContributionResponse: Codable {
    let id: String
}

struct BadgesResponse: Codable {
    let items: [Badge]
}

struct Badge: Codable {
    let code: String
    let name: String
    let description: String
}

struct UserBadgesResponse: Codable {
    let items: [UserBadge]
}

struct UserBadge: Codable {
    let code: String
    let name: String
    let description: String
    let awarded_at: String
}

struct UsageResponse: Codable {
    let month_key: String
    let scans_used: Int
    let scans_remaining: Int?
}

struct SpendingTrendsResponse: Codable {
    let months: [String: MonthData]
    let trend: String
    let period_months: Int
}

struct MonthData: Codable {
    let total_cents: Int
    let txn_count: Int
    let avg_txn_cents: Double
}

struct SpendingForecastResponse: Codable {
    let forecast_cents: Int
    let forecast_per_month_cents: Int
    let confidence: String
    let method: String
    let months_ahead: Int
    let based_on_months: Int
}

struct SpendingInsightsResponse: Codable {
    let insights: [Insight]
    let current_month_total_cents: Int
    let last_month_total_cents: Int
    let generated_at: String
}

struct Insight: Codable {
    let type: String
    let severity: String
    let message: String
    let recommendation: String
}

struct RecurringTransactionsResponse: Codable {
    let recurring: [RecurringTransaction]
}

struct RecurringTransaction: Codable {
    let merchant: String
    let category: String
    let amount_cents: Int
    let frequency: Int
    let first_seen: String?
    let last_seen: String?
    let estimated_interval_days: Int?
}

struct AlertsResponse: Codable {
    let items: [BudgetAlert]
}

struct BudgetAlert: Codable {
    let id: String
    let alert_type: String
    let budget_id: String?
    let category: String?
    let message: String
    let status: String
    let threshold_cents: Int?
    let current_cents: Int?
    let created_at: String
}

struct SubscriptionCheckoutResponse: Codable {
    let checkout_url: String
}

struct ExportCSVResponse: Codable {
    let job_id: String?
    let download_url: String?
}

struct ManualTransactionResponse: Codable {
    let id: String
}

struct TransactionItemsResponse: Codable {
    let items: [TransactionItem]
}

struct CategoryComparisonResponse: Codable {
    let comparison: [CategoryComparisonItem]
}

struct CategoryComparisonItem: Codable {
    let category: String
    let period1_total_cents: Int
    let period1_txn_count: Int
    let period2_total_cents: Int
    let period2_txn_count: Int
    let change_cents: Int
    let change_percent: Double?
}

struct SubscriptionResponse: Codable {
    let plan: String
    let status: String
    let current_period_end: String?
    let cancel_at_period_end: Bool?
}

struct TagResponse: Codable {
    let id: String
}

struct TagsResponse: Codable {
    let items: [Tag]
}

struct Tag: Codable {
    let id: String
    let user_id: String
    let name: String
    let color: String?
    let created_at: String
}

struct LinkedAccountResponse: Codable {
    let id: String
}

struct LinkedAccountsResponse: Codable {
    let items: [LinkedAccount]
}

struct LinkedAccount: Codable {
    let id: String
    let user_id: String
    let provider: String
    let provider_account_id: String
    let institution_name: String
    let account_mask: String?
    let account_name: String
    let account_type: String
    let account_subtype: String?
    let status: String
    let created_at: String
    let last_synced_at: String?
    let balance: AccountBalance?
}

struct AccountBalance: Codable {
    let current_cents: Int?
    let available_cents: Int?
    let currency_code: String
    let as_of: String
}

struct PushDevicesResponse: Codable {
    let items: [PushDevice]
}

struct PushDevice: Codable {
    let id: String
    let platform: String
    let token: String
    let is_active: Bool
    let created_at: String
    let last_seen_at: String?
}

