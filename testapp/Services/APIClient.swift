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

