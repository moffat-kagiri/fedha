-- Fedha Financial Management System - PostgreSQL Schema
-- PostgreSQL 17 Compatible
-- Complete schema with analytics enhancements

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== ENUMS ====================

CREATE TYPE profile_type AS ENUM ('personal', 'business', 'family', 'student');
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'savings');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled', 'refunded');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'bank', 'mobile', 'online', 'cheque');
CREATE TYPE goal_type AS ENUM ('savings', 'debtReduction', 'insurance', 'emergencyFund', 'investment', 'other');
CREATE TYPE goal_status AS ENUM ('active', 'completed', 'paused', 'cancelled');
CREATE TYPE goal_priority AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE budget_period AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'yearly');
CREATE TYPE invoice_status AS ENUM ('draft', 'sent', 'paid', 'overdue', 'cancelled');
CREATE TYPE interest_model AS ENUM ('simple', 'compound', 'reducingBalance');

-- ==================== CORE TABLES ====================

-- Profiles (Users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(150),
    last_name VARCHAR(150),
    phone_number VARCHAR(20),
    profile_type profile_type DEFAULT 'personal',
    bio TEXT,
    profile_picture_url VARCHAR(500),
    country VARCHAR(2),
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Analytics metadata
    total_transactions INTEGER DEFAULT 0,
    average_transaction_amount DECIMAL(15, 2) DEFAULT 0,
    total_spending DECIMAL(18, 2) DEFAULT 0,
    total_income DECIMAL(18, 2) DEFAULT 0,
    days_active INTEGER DEFAULT 0,
    last_transaction_date TIMESTAMPTZ,
    sync_frequency VARCHAR(50),
    financial_health_score INTEGER CHECK (financial_health_score IS NULL OR (financial_health_score >= 0 AND financial_health_score <= 100)),
    spending_vs_income_ratio DECIMAL(5, 2) DEFAULT 0,
    savings_rate DECIMAL(5, 2) DEFAULT 0,
    signup_source VARCHAR(100),
    subscription_tier VARCHAR(50) DEFAULT 'free',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sessions for authentication
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    session_token VARCHAR(500) UNIQUE NOT NULL,
    last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Categories
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    color VARCHAR(7),
    icon_name VARCHAR(100),
    is_default BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    goal_id UUID,
    
    amount DECIMAL(15, 2) NOT NULL,
    type transaction_type NOT NULL,
    status transaction_status DEFAULT 'completed',
    currency VARCHAR(3) DEFAULT 'KES',
    payment_method payment_method,
    description TEXT,
    
    transaction_date TIMESTAMPTZ NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_pattern VARCHAR(50),
    parent_transaction_id UUID REFERENCES transactions(id),
    
    -- Analytics fields
    merchant_name VARCHAR(255),
    merchant_category VARCHAR(100),
    tags TEXT[],
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_flagged BOOLEAN DEFAULT FALSE,
    anomaly_score DECIMAL(5, 2) CHECK (anomaly_score IS NULL OR (anomaly_score >= 0 AND anomaly_score <= 1)),
    budget_period VARCHAR(50),
    budget_id UUID,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Pending Transactions (SMS candidates)
CREATE TABLE pending_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    raw_text TEXT NOT NULL,
    confidence DECIMAL(3, 2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    extracted_amount DECIMAL(15, 2),
    extracted_date TIMESTAMPTZ,
    extracted_description TEXT,
    merchant_name VARCHAR(255),
    
    status VARCHAR(50) DEFAULT 'pending',
    matched_transaction_id UUID REFERENCES transactions(id),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Goals
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    goal_type goal_type NOT NULL,
    goal_status goal_status DEFAULT 'active',
    priority goal_priority DEFAULT 'medium',
    
    target_amount DECIMAL(15, 2) NOT NULL,
    current_amount DECIMAL(15, 2) DEFAULT 0 CHECK (current_amount <= target_amount OR goal_status = 'completed'),
    currency VARCHAR(3) DEFAULT 'KES',
    
    target_date TIMESTAMPTZ,
    
    -- Analytics fields
    last_contribution_date TIMESTAMPTZ,
    contribution_count INTEGER DEFAULT 0,
    average_contribution DECIMAL(15, 2),
    linked_category_id UUID REFERENCES categories(id),
    projected_completion_date TIMESTAMPTZ,
    days_ahead_behind INTEGER,
    goal_group VARCHAR(100),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Budgets
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL CHECK (end_date > start_date),
    period budget_period DEFAULT 'monthly',
    
    budgeted_amount DECIMAL(15, 2) NOT NULL,
    spent_amount DECIMAL(15, 2) DEFAULT 0,
    remaining_amount DECIMAL(15, 2),
    
    -- Analytics fields
    variance_amount DECIMAL(15, 2),
    variance_percentage DECIMAL(5, 2),
    budget_status VARCHAR(20),
    last_updated_at TIMESTAMPTZ,
    previous_period_spent DECIMAL(15, 2),
    threshold_warning_percentage DECIMAL(3, 2) DEFAULT 0.80,
    threshold_critical_percentage DECIMAL(3, 2) DEFAULT 0.95,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Clients (for invoicing)
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(2),
    tax_id VARCHAR(50),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Invoices
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    status invoice_status DEFAULT 'draft',
    
    total_amount DECIMAL(15, 2) NOT NULL,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    net_amount DECIMAL(15, 2) NOT NULL,
    
    issue_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date TIMESTAMPTZ,
    paid_date TIMESTAMPTZ,
    
    description TEXT,
    notes TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Loans
CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    lender_name VARCHAR(255) NOT NULL,
    borrower_name VARCHAR(255),
    
    principal_amount DECIMAL(15, 2) NOT NULL,
    remaining_amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KES',
    
    annual_interest_rate DECIMAL(5, 2),
    interest_model interest_model DEFAULT 'simple',
    
    start_date TIMESTAMPTZ NOT NULL,
    maturity_date TIMESTAMPTZ NOT NULL,
    
    status VARCHAR(50) DEFAULT 'active',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sync Queue
CREATE TABLE sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL,
    
    payload JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    error_message TEXT,
    
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== ANALYTICS TABLES ====================

-- Spending Patterns Table
CREATE TABLE spending_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
    hour_of_day INTEGER CHECK (hour_of_day >= 0 AND hour_of_day <= 23),
    month_of_year INTEGER CHECK (month_of_year >= 1 AND month_of_year <= 12),
    
    average_amount DECIMAL(15, 2),
    transaction_count INTEGER DEFAULT 0,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    merchant_name VARCHAR(255),
    
    standard_deviation DECIMAL(15, 2),
    percentile_90 DECIMAL(15, 2),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User Cohort Metrics Table
CREATE TABLE user_cohort_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_date DATE NOT NULL,
    cohort_size INTEGER DEFAULT 0,
    month_number INTEGER,
    
    average_monthly_spending DECIMAL(15, 2),
    median_transaction_amount DECIMAL(15, 2),
    average_transactions_per_user DECIMAL,
    
    active_users INTEGER DEFAULT 0,
    retention_rate DECIMAL(5, 2),
    churn_rate DECIMAL(5, 2),
    
    top_category VARCHAR(100),
    average_goal_completion_rate DECIMAL(5, 2),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== ANALYTICS VIEWS ====================

CREATE OR REPLACE VIEW user_financial_summary AS
SELECT 
    p.id as profile_id,
    p.email,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT t.id) as total_transactions,
    SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) as total_expenses,
    AVG(t.amount) as average_transaction,
    MAX(t.transaction_date) as last_transaction_date,
    COUNT(DISTINCT g.id) as active_goals,
    COUNT(DISTINCT CASE WHEN g.goal_status = 'completed' THEN g.id END) as completed_goals,
    COUNT(DISTINCT b.id) as active_budgets,
    p.financial_health_score,
    p.savings_rate
FROM profiles p
LEFT JOIN transactions t ON p.id = t.profile_id
LEFT JOIN goals g ON p.id = g.profile_id
LEFT JOIN budgets b ON p.id = b.profile_id
GROUP BY p.id, p.email, p.first_name, p.last_name, p.financial_health_score, p.savings_rate;

CREATE OR REPLACE VIEW transaction_monthly_summary AS
SELECT 
    p.id as profile_id,
    DATE_TRUNC('month', t.transaction_date)::DATE as month,
    t.type,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as average_amount,
    MIN(t.amount) as min_amount,
    MAX(t.amount) as max_amount
FROM profiles p
LEFT JOIN transactions t ON p.id = t.profile_id
GROUP BY p.id, DATE_TRUNC('month', t.transaction_date), t.type
ORDER BY p.id, month DESC;

CREATE OR REPLACE VIEW transaction_merchant_summary AS
SELECT 
    t.profile_id,
    t.merchant_name,
    t.merchant_category,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as average_amount,
    MAX(t.transaction_date) as last_transaction_date,
    STRING_AGG(DISTINCT t.category_id::text, ',') as category_ids
FROM transactions t
WHERE t.merchant_name IS NOT NULL
GROUP BY t.profile_id, t.merchant_name, t.merchant_category;

CREATE OR REPLACE VIEW active_goals_progress AS
SELECT 
    g.id,
    g.profile_id,
    g.name,
    g.goal_type,
    g.goal_status,
    g.target_amount,
    g.current_amount,
    ROUND(100.0 * g.current_amount / g.target_amount, 2) as progress_percentage,
    (g.target_amount - g.current_amount) as remaining_amount,
    g.target_date,
    g.projected_completion_date,
    g.contribution_count,
    g.average_contribution,
    g.days_ahead_behind
FROM goals g
WHERE g.goal_status IN ('active', 'paused');

CREATE OR REPLACE VIEW budget_spending_summary AS
SELECT 
    b.id,
    b.profile_id,
    b.name,
    b.period,
    b.start_date,
    b.end_date,
    b.budgeted_amount,
    b.spent_amount,
    (b.budgeted_amount - b.spent_amount) as remaining_amount,
    ROUND(100.0 * b.spent_amount / b.budgeted_amount, 2) as spent_percentage,
    b.variance_amount,
    b.variance_percentage,
    CASE 
        WHEN b.spent_amount >= (b.budgeted_amount * b.threshold_critical_percentage) THEN 'critical'
        WHEN b.spent_amount >= (b.budgeted_amount * b.threshold_warning_percentage) THEN 'warning'
        ELSE 'on_track'
    END as budget_status,
    c.name as category_name
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.id
ORDER BY b.start_date DESC;

CREATE OR REPLACE VIEW category_spending_trends AS
SELECT 
    t.profile_id,
    c.id as category_id,
    c.name as category_name,
    t.type,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as average_amount,
    STDDEV(t.amount) as standard_deviation,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY t.amount) as percentile_90
FROM transactions t
LEFT JOIN categories c ON t.category_id = c.id
GROUP BY t.profile_id, c.id, c.name, t.type;

CREATE OR REPLACE VIEW user_engagement_metrics AS
SELECT 
    p.id as profile_id,
    p.email,
    p.total_transactions,
    p.days_active,
    p.last_transaction_date,
    p.sync_frequency,
    CASE 
        WHEN p.last_transaction_date > NOW() - INTERVAL '7 days' THEN 'active'
        WHEN p.last_transaction_date > NOW() - INTERVAL '30 days' THEN 'inactive'
        ELSE 'dormant'
    END as engagement_status,
    p.created_at,
    AGE(NOW(), p.created_at) as account_age,
    p.subscription_tier
FROM profiles p;

-- ==================== TRIGGERS ====================

-- Function to update budget spent_amount
CREATE OR REPLACE FUNCTION update_budget_spent_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND NEW.budget_id IS NOT NULL THEN
        UPDATE budgets 
        SET 
            spent_amount = (
                SELECT COALESCE(SUM(amount), 0) 
                FROM transactions 
                WHERE budget_id = NEW.budget_id 
                    AND status = 'completed'
            ),
            variance_amount = (
                budgeted_amount - (
                    SELECT COALESCE(SUM(amount), 0) 
                    FROM transactions 
                    WHERE budget_id = NEW.budget_id 
                        AND status = 'completed'
                )
            ),
            last_updated_at = NOW()
        WHERE id = NEW.budget_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_budget_on_transaction_insert
AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION update_budget_spent_amount();

-- Function to update goal current_amount
CREATE OR REPLACE FUNCTION update_goal_current_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.goal_id IS NOT NULL AND NEW.status = 'completed' THEN
        UPDATE goals 
        SET 
            current_amount = (
                SELECT COALESCE(SUM(amount), 0) 
                FROM transactions 
                WHERE goal_id = NEW.goal_id
                    AND status = 'completed'
            ),
            last_contribution_date = NOW(),
            contribution_count = contribution_count + 1,
            average_contribution = (
                SELECT COALESCE(SUM(amount), 0) / NULLIF(COUNT(*), 0)
                FROM transactions 
                WHERE goal_id = NEW.goal_id
                    AND status = 'completed'
            ),
            updated_at = NOW()
        WHERE id = NEW.goal_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_goal_on_transaction_insert
AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW WHEN (NEW.goal_id IS NOT NULL)
EXECUTE FUNCTION update_goal_current_amount();

-- Function to update profile analytics
CREATE OR REPLACE FUNCTION update_profile_analytics()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles 
    SET 
        total_transactions = (
            SELECT COUNT(*) FROM transactions WHERE profile_id = NEW.profile_id
        ),
        total_spending = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM transactions 
            WHERE profile_id = NEW.profile_id AND type = 'expense' AND status = 'completed'
        ),
        total_income = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM transactions 
            WHERE profile_id = NEW.profile_id AND type = 'income' AND status = 'completed'
        ),
        average_transaction_amount = (
            SELECT AVG(amount) 
            FROM transactions 
            WHERE profile_id = NEW.profile_id AND status = 'completed'
        ),
        last_transaction_date = NEW.transaction_date,
        spending_vs_income_ratio = (
            SELECT 
                CASE 
                    WHEN COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) > 0
                    THEN ROUND(100.0 * COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) / 
                               COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0), 2)
                    ELSE 0
                END
            FROM transactions 
            WHERE profile_id = NEW.profile_id AND status = 'completed'
        ),
        savings_rate = (
            SELECT 
                CASE 
                    WHEN COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) > 0
                    THEN ROUND(100.0 * COALESCE(SUM(CASE WHEN type = 'savings' THEN amount ELSE 0 END), 0) / 
                               COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0), 2)
                    ELSE 0
                END
            FROM transactions 
            WHERE profile_id = NEW.profile_id AND status = 'completed'
        ),
        updated_at = NOW()
    WHERE id = NEW.profile_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profile_analytics_trigger
AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION update_profile_analytics();

-- ==================== STORED PROCEDURES ====================

-- Calculate spending patterns
CREATE OR REPLACE FUNCTION calculate_spending_patterns()
RETURNS TABLE (
    profile_id UUID,
    day_of_week INTEGER,
    hour_of_day INTEGER,
    month_of_year INTEGER,
    average_amount DECIMAL,
    transaction_count BIGINT,
    standard_deviation DECIMAL,
    percentile_90 DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.profile_id,
        EXTRACT(DOW FROM t.transaction_date)::INTEGER,
        EXTRACT(HOUR FROM t.transaction_date)::INTEGER,
        EXTRACT(MONTH FROM t.transaction_date)::INTEGER,
        AVG(t.amount)::DECIMAL(15,2),
        COUNT(*)::BIGINT,
        STDDEV(t.amount)::DECIMAL(15,2),
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY t.amount)::DECIMAL(15,2)
    FROM transactions t
    WHERE t.status = 'completed'
    GROUP BY 
        t.profile_id,
        EXTRACT(DOW FROM t.transaction_date),
        EXTRACT(HOUR FROM t.transaction_date),
        EXTRACT(MONTH FROM t.transaction_date);
END;
$$ LANGUAGE plpgsql;

-- Detect spending anomalies using z-score
CREATE OR REPLACE FUNCTION detect_spending_anomalies(
    p_profile_id UUID,
    p_z_score_threshold DECIMAL DEFAULT 2.5
)
RETURNS TABLE (
    transaction_id UUID,
    amount DECIMAL,
    calculated_z_score DECIMAL,
    anomaly_score DECIMAL,
    is_anomaly BOOLEAN
) AS $$
DECLARE
    v_avg_amount DECIMAL;
    v_stddev DECIMAL;
BEGIN
    SELECT AVG(amount), STDDEV(amount)
    INTO v_avg_amount, v_stddev
    FROM transactions
    WHERE profile_id = p_profile_id AND status = 'completed';
    
    IF v_stddev IS NULL OR v_stddev = 0 THEN
        v_stddev := 1;
    END IF;
    
    RETURN QUERY
    SELECT 
        t.id,
        t.amount,
        ROUND(CAST((t.amount - v_avg_amount) / v_stddev AS NUMERIC), 2)::DECIMAL,
        ROUND(CAST((1.0 / (1.0 + EXP(-((t.amount - v_avg_amount) / v_stddev)))) AS NUMERIC), 3)::DECIMAL,
        ABS((t.amount - v_avg_amount) / v_stddev) > p_z_score_threshold
    FROM transactions t
    WHERE t.profile_id = p_profile_id AND t.status = 'completed'
    ORDER BY ABS((t.amount - v_avg_amount) / v_stddev) DESC;
END;
$$ LANGUAGE plpgsql;

-- Forecast spending
CREATE OR REPLACE FUNCTION forecast_spending(
    p_profile_id UUID,
    p_months_ahead INTEGER DEFAULT 3,
    p_lookback_months INTEGER DEFAULT 6
)
RETURNS TABLE (
    forecast_month DATE,
    forecasted_spending DECIMAL,
    confidence_interval_lower DECIMAL,
    confidence_interval_upper DECIMAL
) AS $$
DECLARE
    v_avg_monthly DECIMAL;
    v_stddev_monthly DECIMAL;
    v_current_month DATE;
    i INTEGER;
BEGIN
    SELECT AVG(monthly_spending), STDDEV(monthly_spending)
    INTO v_avg_monthly, v_stddev_monthly
    FROM (
        SELECT 
            DATE_TRUNC('month', transaction_date)::DATE as month,
            SUM(amount) as monthly_spending
        FROM transactions
        WHERE profile_id = p_profile_id 
            AND status = 'completed'
            AND transaction_date > NOW() - (p_lookback_months || ' months')::INTERVAL
        GROUP BY DATE_TRUNC('month', transaction_date)
    ) monthly_data;
    
    IF v_stddev_monthly IS NULL THEN
        v_stddev_monthly := v_avg_monthly * 0.2;
    END IF;
    
    v_current_month := DATE_TRUNC('month', NOW())::DATE;
    
    FOR i IN 1..p_months_ahead LOOP
        RETURN QUERY SELECT 
            (v_current_month + (i || ' months')::INTERVAL)::DATE,
            v_avg_monthly,
            (v_avg_monthly - (1.96 * v_stddev_monthly))::DECIMAL(15,2),
            (v_avg_monthly + (1.96 * v_stddev_monthly))::DECIMAL(15,2);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Update cohort metrics
CREATE OR REPLACE FUNCTION update_cohort_metrics()
RETURNS TABLE (
    cohort_date DATE,
    cohort_size BIGINT,
    month_number INTEGER,
    average_monthly_spending DECIMAL,
    median_transaction_amount DECIMAL,
    average_transactions_per_user DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC('month', p.created_at)::DATE,
        COUNT(DISTINCT p.id)::BIGINT,
        (EXTRACT(MONTH FROM NOW()) - EXTRACT(MONTH FROM p.created_at))::INTEGER,
        AVG(t.amount)::DECIMAL(15,2),
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.amount)::DECIMAL(15,2),
        COUNT(DISTINCT t.id)::DECIMAL(15,2) / NULLIF(COUNT(DISTINCT p.id), 0)
    FROM profiles p
    LEFT JOIN transactions t ON p.id = t.profile_id AND t.status = 'completed'
    GROUP BY DATE_TRUNC('month', p.created_at);
END;
$$ LANGUAGE plpgsql;

-- ==================== INDEXES ====================

-- Profiles indexes
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);
CREATE INDEX idx_profiles_country ON profiles(country);

-- Sessions indexes
CREATE INDEX idx_sessions_profile_id ON sessions(profile_id);
CREATE INDEX idx_sessions_token ON sessions(session_token);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

-- Categories indexes
CREATE INDEX idx_categories_profile_id ON categories(profile_id);
CREATE INDEX idx_categories_type ON categories(type);

-- Transactions indexes
CREATE INDEX idx_transactions_profile_id ON transactions(profile_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_goal_id ON transactions(goal_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_merchant ON transactions(merchant_name);
CREATE INDEX idx_transactions_location ON transactions(location);
CREATE INDEX idx_transactions_anomaly ON transactions(anomaly_score);
CREATE INDEX idx_transactions_budget_id ON transactions(budget_id);
CREATE INDEX idx_transactions_profile_date ON transactions(profile_id, transaction_date DESC);

-- Pending transactions indexes
CREATE INDEX idx_pending_transactions_profile_id ON pending_transactions(profile_id);
CREATE INDEX idx_pending_transactions_status ON pending_transactions(status);

-- Goals indexes
CREATE INDEX idx_goals_profile_id ON goals(profile_id);
CREATE INDEX idx_goals_status ON goals(goal_status);
CREATE INDEX idx_goals_target_date ON goals(target_date);
CREATE INDEX idx_goals_category ON goals(linked_category_id);

-- Budgets indexes
CREATE INDEX idx_budgets_profile_id ON budgets(profile_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_budgets_period ON budgets(period);
CREATE INDEX idx_budgets_dates ON budgets(start_date, end_date);

-- Clients indexes
CREATE INDEX idx_clients_profile_id ON clients(profile_id);

-- Invoices indexes
CREATE INDEX idx_invoices_profile_id ON invoices(profile_id);
CREATE INDEX idx_invoices_client_id ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_dates ON invoices(issue_date, due_date);

-- Loans indexes
CREATE INDEX idx_loans_profile_id ON loans(profile_id);
CREATE INDEX idx_loans_status ON loans(status);

-- Sync queue indexes
CREATE INDEX idx_sync_queue_profile_id ON sync_queue(profile_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id);

-- Spending patterns indexes
CREATE INDEX idx_spending_patterns_profile_id ON spending_patterns(profile_id);
CREATE INDEX idx_spending_patterns_dow ON spending_patterns(day_of_week);
CREATE INDEX idx_spending_patterns_hour ON spending_patterns(hour_of_day);
CREATE INDEX idx_spending_patterns_merchant ON spending_patterns(merchant_name);

-- User cohort metrics indexes
CREATE INDEX idx_cohort_metrics_date ON user_cohort_metrics(cohort_date);
CREATE INDEX idx_cohort_metrics_month ON user_cohort_metrics(month_number);
