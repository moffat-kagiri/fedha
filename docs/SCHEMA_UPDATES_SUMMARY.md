# Fedha Database Schema - Analytics Enhancement Summary

## Overview
Comprehensive enhancement of the PostgreSQL schema to support advanced analytics, behavioral tracking, and data-driven insights for financial management across individual users and cohorts.

## Date of Updates
2025 - Analytics Enhancement Phase

---

## 1. Enhanced Core Tables

### profiles Table - 12 New Analytics Columns
```sql
-- Individual User Analytics
total_transactions INT                    -- Lifetime transaction count
average_transaction_amount DECIMAL        -- Average transaction value
total_spending DECIMAL(18,2)              -- Total expenses lifetime
total_income DECIMAL(18,2)                -- Total income lifetime
days_active INT                           -- Days since first transaction
last_transaction_date TIMESTAMPTZ         -- Most recent transaction date
financial_health_score INT (0-100)        -- Calculated financial health metric
spending_vs_income_ratio DECIMAL(5,2)     -- Spending divided by income
savings_rate DECIMAL(5,2)                 -- Percentage of income saved
signup_source VARCHAR(100)                -- User acquisition channel
country VARCHAR(2)                        -- Country code for locale insights
subscription_tier VARCHAR(50)             -- Premium/free/pro tier tracking
```

**Purpose**: Provides user-level financial metrics for personalized insights and engagement tracking.

---

### transactions Table - 11 New Analytics Columns
```sql
-- Enhanced Transaction Data
merchant_name VARCHAR(255)                -- Extracted merchant identifier
merchant_category VARCHAR(100)            -- Merchant category classification
tags VARCHAR[] (ARRAY)                    -- Flexible tagging system
recurring_pattern VARCHAR(50)             -- 'daily', 'weekly', 'monthly', 'irregular'
parent_transaction_id UUID                -- Links to recurring parent transaction
location VARCHAR(255)                     -- Geographic location of transaction
latitude DECIMAL(9,6)                     -- GPS latitude coordinate
longitude DECIMAL(9,6)                    -- GPS longitude coordinate
is_flagged BOOLEAN                        -- User-flagged for review
anomaly_score DECIMAL(5,2) (0-1)         -- Statistical anomaly detection score
budget_id UUID                            -- Reference to parent budget
```

**Purpose**: Captures detailed transaction context for merchant analysis, location-based insights, and anomaly detection.

---

### goals Table - 8 New Analytics Columns
```sql
-- Goal Progress Tracking
last_contribution_date TIMESTAMPTZ        -- Most recent contribution date
contribution_count INT                    -- Total contributions to goal
average_contribution DECIMAL(15,2)        -- Average contribution amount
linked_category_id UUID                   -- Primary expense category for goal
projected_completion_date DATE            -- AI-predicted completion date
days_ahead_behind INT                     -- Days ahead or behind target
goal_group VARCHAR(100)                   -- Grouping for related goals
```

**Purpose**: Enables goal progress analytics and predictive forecasting.

---

### budgets Table - 7 New Analytics Columns
```sql
-- Budget Performance Tracking
variance_amount DECIMAL(15,2)             -- (Spent - Planned) amount
variance_percentage DECIMAL(5,2)          -- Variance as percentage
budget_status VARCHAR(50)                 -- 'ok', 'warning', 'critical'
last_updated_at TIMESTAMPTZ               -- Last recalculation timestamp
previous_period_spent DECIMAL(15,2)       -- Prior period spending for comparison
threshold_warning_percentage DECIMAL(5,2) -- Alert threshold (e.g., 80%)
threshold_critical_percentage DECIMAL(5,2)-- Critical threshold (e.g., 100%)
```

**Purpose**: Provides budget health metrics and historical comparison analysis.

---

## 2. New Analytics Tables

### spending_patterns Table
Behavioral analytics for time-based and category-based spending patterns.

```sql
CREATE TABLE spending_patterns (
    id UUID PRIMARY KEY,
    profile_id UUID NOT NULL REFERENCES profiles(id),
    day_of_week INT (0-6),                -- Sunday=0 to Saturday=6
    hour_of_day INT (0-23),               -- Hour in 24-hour format
    month_of_year INT (1-12),             -- Month for seasonal analysis
    category_id UUID,                     -- Transaction category
    merchant_name VARCHAR(255),           -- Specific merchant
    average_amount DECIMAL(15,2),         -- Average amount in this pattern
    transaction_count BIGINT,              -- Number of transactions
    last_updated TIMESTAMPTZ,
    
    -- Indexes for query optimization
    INDEX profile_day_hour (profile_id, day_of_week, hour_of_day)
    INDEX profile_category (profile_id, category_id)
    INDEX merchant_analysis (profile_id, merchant_name)
);
```

**Purpose**: 
- Identify when users typically spend money (time patterns)
- Track merchant preferences and categories by time
- Enable predictive spending forecasts
- Detect behavioral changes

---

### user_cohort_metrics Table
Collective analytics across all users for benchmarking and trends.

```sql
CREATE TABLE user_cohort_metrics (
    id UUID PRIMARY KEY,
    cohort_month DATE,                    -- Cohort signup month
    cohort_size INT,                      -- Total users in cohort
    active_users INT,                     -- Active in last 30 days
    total_transactions BIGINT,            -- Lifetime transactions
    total_spending DECIMAL(18,2),         -- Total cohort spending
    average_spending_per_user DECIMAL(15,2),
    retention_rate DECIMAL(5,2) (0-100),  -- % of users still active
    churn_rate DECIMAL(5,2) (0-100),     -- % of inactive users
    average_monthly_spending DECIMAL(15,2),
    updated_at TIMESTAMPTZ,
    
    INDEX cohort_month (cohort_month),
    INDEX updated_at (updated_at)
);
```

**Purpose**:
- Track user retention and churn by signup cohort
- Benchmark spending patterns across user segments
- Measure product adoption and engagement trends
- Support cohort analysis for business intelligence

---

## 3. Automated Analytics Maintenance

### Database Triggers (Auto-Update on Transaction Events)

#### Trigger 1: update_budget_spent_amount()
**Executes**: After any transaction INSERT or UPDATE
**Updates**: budgets.spent_amount by summing transaction amounts
```sql
-- Automatically recalculates budget spending when transactions change
AFTER INSERT OR UPDATE ON transactions
  FOR EACH ROW
    UPDATE budgets SET spent_amount = (SUM of transactions in budget)
```

#### Trigger 2: update_goal_current_amount()
**Executes**: After any transaction INSERT or UPDATE
**Updates**: goals with contribution tracking
```sql
-- Tracks goal progress and contribution metrics
AFTER INSERT OR UPDATE ON transactions  
  FOR EACH ROW
    UPDATE goals SET
      current_amount = (SUM of contributions),
      contribution_count = (COUNT of contributions),
      average_contribution = (AVG of contributions),
      last_contribution_date = NOW()
```

#### Trigger 3: update_profile_analytics()
**Executes**: After any transaction INSERT or UPDATE
**Updates**: profiles with user-level metrics
```sql
-- Maintains profile-level financial metrics
AFTER INSERT OR UPDATE ON transactions
  FOR EACH ROW
    UPDATE profiles SET
      total_transactions = COUNT(*),
      average_transaction_amount = AVG(amount),
      spending_vs_income_ratio = total_spending / total_income,
      last_transaction_date = transaction_date
```

**Benefit**: Analytics fields stay synchronized without application logic.

---

## 4. Analytics Views (Pre-Aggregated Queries)

### user_financial_summary
Real-time overview of user financial status with goal/budget counts.
```sql
SELECT profile_id, email, total_spending, average_transaction_amount,
       active_goals, completed_goals, active_budgets
FROM user_financial_summary
```

### transaction_monthly_summary
Spending trends by month and transaction type.
```sql
SELECT profile_id, month, type, transaction_count, total_amount,
       average_amount, min_amount, max_amount
FROM transaction_monthly_summary
```

### transaction_merchant_summary
Merchant and category-level spending analysis.
```sql
SELECT profile_id, merchant_name, merchant_category, transaction_count,
       total_amount, average_amount, last_transaction_date
FROM transaction_merchant_summary
```

### active_goals_progress
Goal tracking with progress percentages and days remaining.
```sql
SELECT goal_id, profile_id, name, progress_percentage, remaining_amount,
       days_remaining, contribution_count, average_contribution
FROM active_goals_progress
```

### budget_spending_summary
Budget health status with variance analysis.
```sql
SELECT budget_id, profile_id, name, budget_amount, spent_amount,
       spent_percentage, is_over_budget, budget_status, variance_amount
FROM budget_spending_summary
```

### category_spending_trends
Monthly spending by category with statistical analysis.
```sql
SELECT profile_id, category_name, month, transaction_count, total_amount,
       average_amount, standard_deviation
FROM category_spending_trends
```

### user_engagement_metrics
User activity and engagement status tracking.
```sql
SELECT profile_id, email, engagement_status, total_transactions_lifetime,
       transactions_30d, total_goals, goals_completed, days_since_signup
FROM user_engagement_metrics
```

---

## 5. Stored Procedures (Advanced Analytics)

### calculate_spending_patterns(user_profile_id UUID)
Computes behavioral patterns for a user across time dimensions and merchants.
```sql
SELECT * FROM calculate_spending_patterns('user-uuid')
-- Returns: day_of_week, hour_of_day, month_of_year, category_id,
--          merchant_name, avg_amount, transaction_count, last_transaction
```

**Use Case**: Personalized insights like "You typically spend X on groceries on Sundays"

---

### detect_spending_anomalies(user_profile_id UUID)
Statistical anomaly detection using z-score method.
```sql
SELECT * FROM detect_spending_anomalies('user-uuid')
-- Returns: transaction_id, amount, average_amount, zscore, is_anomaly
-- Flags transactions > 2 standard deviations from mean
```

**Use Case**: Fraud detection, unusual spending alerts

---

### forecast_spending(user_profile_id UUID, forecast_days INT DEFAULT 30)
Simple linear regression-based spending forecast.
```sql
SELECT * FROM forecast_spending('user-uuid', 30)
-- Returns: forecast_date, forecasted_amount, confidence_level
```

**Use Case**: Budget planning, "projected spending next month"

---

### update_cohort_metrics()
Batch process to recalculate all cohort metrics.
```sql
CALL update_cohort_metrics()
-- Truncates and repopulates user_cohort_metrics table
```

**Use Case**: Nightly batch job for aggregate analytics

---

## 6. Performance Indexes

### Transaction Indexes
```sql
CREATE INDEX idx_transactions_profile_date 
  ON transactions(profile_id, transaction_date DESC);

CREATE INDEX idx_transactions_merchant_category 
  ON transactions(merchant_name, merchant_category);

CREATE INDEX idx_transactions_location 
  ON transactions(latitude, longitude);

CREATE INDEX idx_transactions_flags 
  ON transactions(is_flagged, anomaly_score DESC);
```

### Goal Indexes
```sql
CREATE INDEX idx_goals_status_profile 
  ON goals(profile_id, status);

CREATE INDEX idx_goals_target_date 
  ON goals(target_date DESC);
```

### Budget Indexes
```sql
CREATE INDEX idx_budgets_period_status 
  ON budgets(profile_id, period, is_active);

CREATE INDEX idx_budgets_variance 
  ON budgets(variance_percentage DESC);
```

### Analytics Indexes
```sql
CREATE INDEX idx_spending_patterns_profile 
  ON spending_patterns(profile_id, day_of_week, hour_of_day);

CREATE INDEX idx_cohort_metrics_month 
  ON user_cohort_metrics(cohort_month);
```

---

## 7. Analytics Capabilities Enabled

### Individual User Analytics
- ✅ Spending patterns by day/time/merchant
- ✅ Budget variance and performance tracking
- ✅ Goal progress forecasting
- ✅ Anomaly detection and fraud alerts
- ✅ Engagement and activity metrics
- ✅ Financial health scoring

### Collective/Cohort Analytics
- ✅ Retention and churn rates by signup cohort
- ✅ Average spending trends across user segments
- ✅ Benchmark metrics for comparison
- ✅ Product adoption metrics
- ✅ User lifecycle analysis

### Advanced Capabilities
- ✅ Behavioral pattern analysis
- ✅ Spending forecasting with confidence intervals
- ✅ Statistical anomaly detection (z-score)
- ✅ Seasonal trend analysis
- ✅ Geographic spending analysis (latitude/longitude)
- ✅ Category and merchant preferences

---

## 8. Security Considerations

### Row-Level Security
- All tables have `profile_id` foreign key to enable isolation
- Views automatically filter by `profile_id`
- Backend ViewSets validate ownership before returning data

### Data Privacy
- Location data (latitude/longitude) can be anonymized if needed
- Merchant names stored but can be tokenized
- All analytics respect user profile boundaries

### Constraint Validation
```sql
-- Scores must be between 0-100
CHECK (financial_health_score >= 0 AND financial_health_score <= 100)

-- Percentages must be between 0-100
CHECK (spending_vs_income_ratio >= 0 AND spending_vs_income_ratio <= 100)

-- Dates must be logical
CHECK (target_date > created_at)
```

---

## 9. Migration Instructions

### Step 1: Backup Current Database
```bash
pg_dump fedha_db > backup_before_analytics.sql
```

### Step 2: Apply Schema Changes
```bash
# Using Django migrations:
python manage.py makemigrations
python manage.py migrate

# OR directly with psql:
psql fedha_db < schema.sql
```

### Step 3: Populate Analytics Tables (First Time)
```bash
# Triggers will auto-populate on future transactions
# For historical data, run:
CALL update_cohort_metrics();
```

### Step 4: Verify Installation
```bash
# Check all tables exist
\dt

# Check views created
\dv

# Check functions exist
\df

# Check indexes created
\di
```

---

## 10. Backend Integration (Django)

### Updated ViewSets
All ViewSet `get_queryset()` methods now use:
```python
def get_queryset(self):
    user_profile = self.request.user.profile
    profile_id = self.request.query_params.get('profile_id')
    
    # Validate ownership
    if str(user_profile.id) != str(profile_id):
        return self.queryset.none()
    
    return self.queryset.filter(profile_id=user_profile.id)
```

### New API Endpoints (Optional)
```
GET /api/analytics/profile/{profile_id}/summary/
GET /api/analytics/profile/{profile_id}/spending-patterns/
GET /api/analytics/profile/{profile_id}/anomalies/
GET /api/analytics/profile/{profile_id}/forecast/?days=30
GET /api/analytics/cohort-metrics/
```

---

## 11. Frontend Integration (Flutter)

### Models Updated
Transaction, Goal, Budget models now include:
```dart
class Transaction {
  String? merchantName;
  String? merchantCategory;
  List<String>? tags;
  String? location;
  double? latitude;
  double? longitude;
  bool? isFlagged;
  double? anomalyScore;
}
```

### Sync Service Updates
Unified sync service handles new fields automatically.

---

## 12. Analytics Queries Examples

### User Monthly Spending Trend
```sql
SELECT month, total_amount FROM transaction_monthly_summary
WHERE profile_id = 'user-uuid' AND type = 'expense'
ORDER BY month;
```

### Top Merchants by Spending
```sql
SELECT merchant_name, merchant_category, total_amount
FROM transaction_merchant_summary
WHERE profile_id = 'user-uuid'
ORDER BY total_amount DESC LIMIT 10;
```

### Goal Progress Overview
```sql
SELECT name, progress_percentage, days_remaining, contribution_count
FROM active_goals_progress
WHERE profile_id = 'user-uuid'
ORDER BY days_remaining;
```

### Budget Health Status
```sql
SELECT name, spent_percentage, budget_status, variance_amount
FROM budget_spending_summary
WHERE profile_id = 'user-uuid'
ORDER BY spent_percentage DESC;
```

### Spending Anomalies (Last 30 Days)
```sql
SELECT * FROM detect_spending_anomalies('user-uuid')
WHERE is_anomaly = TRUE;
```

### User Cohort Metrics
```sql
SELECT cohort_month, cohort_size, active_users, retention_rate, churn_rate
FROM user_cohort_metrics
ORDER BY cohort_month DESC;
```

---

## 13. Summary of Changes

| Category | Count | Items |
|----------|-------|-------|
| **New Columns** | 38 | profiles(12) + transactions(11) + goals(8) + budgets(7) |
| **New Tables** | 2 | spending_patterns, user_cohort_metrics |
| **New Views** | 6 | user_financial_summary, transaction_monthly_summary, etc. |
| **New Stored Procedures** | 4 | calculate_spending_patterns, detect_spending_anomalies, forecast_spending, update_cohort_metrics |
| **New Triggers** | 3 | update_budget_spent_amount, update_goal_current_amount, update_profile_analytics |
| **New Indexes** | 13+ | Performance optimization for analytics queries |
| **Backward Compatibility** | ✅ | All changes are additive; existing queries unaffected |

---

## 14. Next Steps

1. **Deploy**: Run schema updates to PostgreSQL database
2. **Test**: Verify triggers work with sample transaction inserts
3. **Backfill**: Run `update_cohort_metrics()` for historical data
4. **API**: Implement analytics endpoints in Django
5. **Frontend**: Update Flutter models and display analytics
6. **Monitoring**: Set up dashboards using views
7. **Batch Jobs**: Schedule `update_cohort_metrics()` nightly via cron or APScheduler

---

## Questions & Support

For issues or questions about schema updates:
- Review trigger logic in schema.sql
- Check index utilization with `EXPLAIN ANALYZE`
- Monitor automatic trigger execution with transaction audit logs
- Use views for fast analytics without manual aggregation
