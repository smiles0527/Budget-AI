# Mobile API Integration Status

## ✅ Fully Implemented Features

### Authentication
- ✅ Signup (email/password)
- ✅ Login (email/password)
- ✅ Google OAuth login
- ✅ Apple Sign-In
- ✅ Get current user (`/auth/me`)
- ✅ Logout
- ⚠️ Missing: `logout_all`, `rotate` session

### Receipts
- ✅ Upload receipt (presigned URL flow)
- ✅ Confirm receipt
- ✅ Get receipt by ID

### Transactions
- ✅ List transactions (with pagination, filters)
- ✅ Get transaction by ID
- ✅ Search transactions
- ❌ Missing: Create manual transaction (`POST /transactions/manual`)
- ❌ Missing: Update transaction (`PATCH /transactions/{id}`)
- ❌ Missing: Delete transaction (`DELETE /transactions/{id}`)
- ❌ Missing: Get transaction items (`GET /transactions/{id}/items`)

### Dashboard
- ✅ Dashboard summary
- ✅ Dashboard categories

### Budgets
- ✅ Create/Update budget (`PUT /budgets`)
- ✅ List budgets (`GET /budgets`)
- ✅ Budget alerts view
- ✅ Edit budget functionality

### Savings Goals
- ✅ Create savings goal
- ✅ List savings goals
- ✅ Add contribution
- ❌ Missing: Get goal by ID (`GET /savings/goals/{id}`)
- ❌ Missing: Update goal (`PATCH /savings/goals/{id}`)
- ❌ Missing: Delete goal (`DELETE /savings/goals/{id}`)

### Badges & Usage
- ✅ Get all badges
- ✅ Get user badges
- ✅ Get usage stats

### Alerts
- ✅ Get alerts
- ✅ Update alert status

### Analytics
- ✅ Spending trends
- ✅ Spending forecast
- ✅ Spending insights
- ✅ Recurring transactions
- ❌ Missing: Category comparison (`GET /analytics/compare`)

## ❌ Missing Features (Not Implemented)

### Profile Management
- ❌ Update profile (`PATCH /profile`) - **PARTIALLY**: SettingsView references it but uses manual URLRequest instead of APIClient method

### Subscription Management
- ❌ Get subscription status (`GET /subscription`)
- ❌ Create checkout session (`POST /subscription/checkout`) - **REFERENCED**: SettingsView calls `getSubscriptionCheckout()` but method doesn't exist in APIClient
- ⚠️ Note: Webhook endpoint is server-side only

### Data Export
- ❌ Export CSV (`POST /export/csv`) - **REFERENCED**: SettingsView calls `exportCSV()` but method doesn't exist in APIClient
- ❌ Get export status (`GET /export/csv/{job_id}`)

### Linked Accounts (Bank Integration)
- ❌ Create linked account (`POST /linked-accounts`)
- ❌ List linked accounts (`GET /linked-accounts`)
- ❌ Get account by ID (`GET /linked-accounts/{id}`)
- ❌ Update account balances (`POST /linked-accounts/{id}/balances`)
- ❌ Delete linked account (`DELETE /linked-accounts/{id}`)

### Push Notifications
- ❌ Register device (`POST /push/devices`)
- ❌ List devices (`GET /push/devices`)
- ❌ Delete device (`DELETE /push/devices/{id}`)

### Tags
- ❌ Create tag (`POST /tags`)
- ❌ List tags (`GET /tags`)
- ❌ Add tag to transaction (`POST /transactions/{id}/tags/{tag_id}`)
- ❌ Remove tag from transaction (`DELETE /transactions/{id}/tags/{tag_id}`)
- ❌ Delete tag (`DELETE /tags/{id}`)

### Account Management
- ❌ Delete account (`DELETE /account`)

### Categorization Rules (Admin)
- ⚠️ Admin-only endpoints - typically not needed in mobile app
- ❌ Merchant rules (`GET/POST /rules/merchant`)
- ❌ Keyword rules (`GET/POST /rules/keyword`)

## 🔧 Implementation Gaps

### API Client Methods Missing
1. `exportCSV(fromDate:toDate:wait:timeoutSeconds:)` - Referenced in SettingsView
2. `getSubscriptionCheckout()` - Referenced in SettingsView
3. `updateProfile(displayName:currencyCode:timezone:)` - Should use APIClient instead of manual URLRequest
4. `createManualTransaction(...)` - For premium users
5. `updateTransaction(id:...)` - Edit transaction details
6. `deleteTransaction(id:)` - Delete transactions
7. `getTransactionItems(id:)` - View transaction line items
8. `getSavingsGoal(id:)` - Get single goal details
9. `updateSavingsGoal(id:...)` - Edit goal
10. `deleteSavingsGoal(id:)` - Delete goal
11. `getCategoryComparison(...)` - Analytics comparison

### Views/Features Missing
1. **Manual Transaction Entry** - Create transaction form (premium feature)
2. **Transaction Detail View** - Full transaction details with items
3. **Transaction Edit/Delete** - Edit or delete transactions
4. **Savings Goal Detail View** - View single goal with contributions
5. **Savings Goal Edit/Delete** - Edit or delete goals
6. **Export Status View** - Check export job status and download
7. **Linked Accounts Management** - Connect/manage bank accounts
8. **Tags Management** - Create and manage tags
9. **Transaction Tags** - Add/remove tags from transactions
10. **Category Comparison View** - Compare spending across periods
11. **Account Deletion** - Delete account flow

### UI/UX Enhancements Needed
1. **Error Handling** - More comprehensive error display across all views
2. **Loading States** - Consistent loading indicators
3. **Empty States** - Better empty state designs
4. **Pull-to-Refresh** - Add to more views
5. **Offline Support** - Cache data for offline viewing
6. **Image Viewing** - View receipt images
7. **Transaction Filtering UI** - Better filter interface
8. **Date Range Pickers** - For analytics and exports

## 📊 Summary

### Completion Status
- **Core Features**: ~75% complete
- **Premium Features**: ~30% complete
- **Advanced Features**: ~10% complete

### Priority Missing Features
1. **High Priority** (Core functionality):
   - Manual transaction creation
   - Transaction edit/delete
   - Profile update via APIClient
   - Export CSV functionality
   - Subscription checkout

2. **Medium Priority** (Enhanced UX):
   - Transaction detail view with items
   - Savings goal edit/delete
   - Category comparison analytics
   - Better error handling

3. **Low Priority** (Advanced features):
   - Linked accounts
   - Tags management
   - Push notifications
   - Account deletion

### Next Steps
1. Implement missing APIClient methods
2. Create missing views for transaction management
3. Add premium feature gating
4. Implement export functionality
5. Add subscription management
6. Enhance error handling and loading states

