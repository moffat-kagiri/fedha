-- Fedha Financial Management System - PostgreSQL Schema
-- PostgreSQL 17 Compatible

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
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    profile_type profile_type NOT NULL DEFAULT 'personal',
    base_currency VARCHAR(3) NOT NULL DEFAULT 'KES',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Africa/Nairobi',
    photo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    last_synced TIMESTAMPTZ,
    preferences JSONB DEFAULT '{}',

    CONSTRAINT email_or_phone_required CHECK (email IS NOT NULL OR phone_number IS NOT NULL)
);

-- Sessions for authentication
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    auth_token VARCHAR(255) UNIQUE,
    device_id VARCHAR(255),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Categories
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) NOT NULL DEFAULT '#2196F3',
    icon VARCHAR(50) NOT NULL DEFAULT 'category',
    type VARCHAR(20) NOT NULL DEFAULT 'expense',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT categories_type_check CHECK (type IN ('income', 'expense'))
);

-- Transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL,
    type transaction_type NOT NULL,
    status transaction_status NOT NULL DEFAULT 'completed',
    payment_method payment_method,
    description TEXT,
    notes TEXT,
    reference VARCHAR(100),
    recipient VARCHAR(255),
    sms_source TEXT,
    is_expense BOOLEAN NOT NULL DEFAULT TRUE,
    is_pending BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT amount_positive CHECK (amount > 0)
);

-- Pending Transactions (SMS candidates)
CREATE TABLE pending_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    raw_text TEXT,
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    type transaction_type NOT NULL DEFAULT 'expense',
    status transaction_status NOT NULL DEFAULT 'pending',
    confidence DECIMAL(3, 2) DEFAULT 0.5,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT confidence_range CHECK (confidence >= 0 AND confidence <= 1)
);

-- Goals
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_amount DECIMAL(15, 2) NOT NULL,
    current_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    target_date TIMESTAMPTZ NOT NULL,
    completed_date TIMESTAMPTZ,
    goal_type goal_type NOT NULL,
    status goal_status NOT NULL DEFAULT 'active',
    priority goal_priority NOT NULL DEFAULT 'medium',
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT amounts_positive CHECK (target_amount > 0 AND current_amount >= 0),
    CONSTRAINT current_lte_target CHECK (current_amount <= target_amount OR status = 'completed')
);

-- Budgets
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    budget_amount DECIMAL(15, 2) NOT NULL,
    spent_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    period budget_period NOT NULL DEFAULT 'monthly',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT budget_amount_positive CHECK (budget_amount > 0),
    CONSTRAINT spent_amount_non_negative CHECK (spent_amount >= 0),
    CONSTRAINT end_after_start CHECK (end_date > start_date)
);

-- Clients (for invoicing)
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Invoices
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'KES',
    issue_date TIMESTAMPTZ NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    status invoice_status NOT NULL DEFAULT 'draft',
    description TEXT,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT amount_positive CHECK (amount > 0)
);

-- Loans
CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    principal_amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'KES',
    interest_rate DECIMAL(5, 2) NOT NULL,
    interest_model interest_model NOT NULL DEFAULT 'simple',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT principal_positive CHECK (principal_amount > 0),
    CONSTRAINT interest_rate_valid CHECK (interest_rate >= 0 AND interest_rate <= 100),
    CONSTRAINT end_after_start CHECK (end_date > start_date)
);

-- Sync Queue
CREATE TABLE sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action VARCHAR(20) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    data JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retries INTEGER NOT NULL DEFAULT 3,
    error_message TEXT,
    priority INTEGER NOT NULL DEFAULT 0,
    next_retry_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT action_check CHECK (action IN ('create', 'update', 'delete')),
    CONSTRAINT status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

-- Risk Assessments
CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    goal VARCHAR(255),
    income_ratio DECIMAL(5, 2) DEFAULT 50,
    desired_return_ratio DECIMAL(5, 2) DEFAULT 50,
    time_horizon INTEGER DEFAULT 5,
    loss_tolerance_index INTEGER,
    experience_index INTEGER,
    volatility_reaction_index INTEGER,
    liquidity_need_index INTEGER,
    emergency_fund_months INTEGER DEFAULT 3,
    risk_score DECIMAL(5, 2) NOT NULL,
    profile_name VARCHAR(50) NOT NULL,
    allocation_json JSONB,
    answers_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT risk_score_range CHECK (risk_score >= 0 AND risk_score <= 100),
    CONSTRAINT profile_name_check CHECK (profile_name IN ('Conservative', 'Moderate', 'Aggressive'))
);

-- ==================== INDEXES ====================

-- Profiles
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_phone ON profiles(phone_number);
CREATE INDEX idx_profiles_active ON profiles(is_active);

-- Sessions
CREATE INDEX idx_sessions_profile_id ON sessions(profile_id);
CREATE INDEX idx_sessions_token ON sessions(session_token);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);

-- Categories
CREATE INDEX idx_categories_profile_id ON categories(profile_id);
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_active ON categories(is_active);

-- Transactions
CREATE INDEX idx_transactions_profile_id ON transactions(profile_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_goal_id ON transactions(goal_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_synced ON transactions(is_synced);
CREATE INDEX idx_transactions_profile_date ON transactions(profile_id, transaction_date DESC);

-- Pending Transactions
CREATE INDEX idx_pending_profile_id ON pending_transactions(profile_id);
CREATE INDEX idx_pending_status ON pending_transactions(status);
CREATE INDEX idx_pending_date ON pending_transactions(created_at DESC);

-- Goals
CREATE INDEX idx_goals_profile_id ON goals(profile_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_goals_type ON goals(goal_type);
CREATE INDEX idx_goals_synced ON goals(is_synced);
CREATE INDEX idx_goals_target_date ON goals(target_date);

-- Budgets
CREATE INDEX idx_budgets_profile_id ON budgets(profile_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_budgets_active ON budgets(is_active);
CREATE INDEX idx_budgets_dates ON budgets(start_date, end_date);
CREATE INDEX idx_budgets_synced ON budgets(is_synced);

-- Clients
CREATE INDEX idx_clients_profile_id ON clients(profile_id);
CREATE INDEX idx_clients_active ON clients(is_active);

-- Invoices
CREATE INDEX idx_invoices_profile_id ON invoices(profile_id);
CREATE INDEX idx_invoices_client_id ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_dates ON invoices(issue_date, due_date);

-- Loans
CREATE INDEX idx_loans_profile_id ON loans(profile_id);
CREATE INDEX idx_loans_dates ON loans(start_date, end_date);

-- Sync Queue
CREATE INDEX idx_sync_queue_profile_id ON sync_queue(profile_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_priority ON sync_queue(priority DESC);
CREATE INDEX idx_sync_queue_next_retry ON sync_queue(next_retry_at);

-- Risk Assessments
CREATE INDEX idx_risk_assessments_profile_id ON risk_assessments(profile_id);
CREATE INDEX idx_risk_assessments_created ON risk_assessments(created_at DESC);

-- ==================== TRIGGERS ====================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;

$$
language 'plpgsql';

-- Apply to all relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pending_transactions_updated_at BEFORE UPDATE ON pending_transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON loans 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sync_queue_updated_at BEFORE UPDATE ON sync_queue 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==================== DEFAULT DATA ====================

-- Insert default categories (will be profile-specific when user signs up)
-- This is just a template that can be copied for each new user
CREATE TABLE default_categories (
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) NOT NULL,
    icon VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL
);

INSERT INTO default_categories (name, description, color, icon, type) VALUES
    ('Salary', 'Monthly salary and wages', '#4CAF50', 'attach_money', 'income'),
    ('Business', 'Business income', '#2196F3', 'business', 'income'),
    ('Investment', 'Investment returns', '#9C27B0', 'trending_up', 'income'),
    ('Gift', 'Gifts received', '#FF9800', 'card_giftcard', 'income'),
    ('Other Income', 'Other income sources', '#607D8B', 'account_balance_wallet', 'income'),
  
    ('Food & Dining', 'Restaurants, groceries', '#FF5722', 'restaurant', 'expense'),
    ('Transport', 'Transport and travel', '#3F51B5', 'directions_car', 'expense'),
    ('Utilities', 'Bills and utilities', '#FFC107', 'build', 'expense'),
    ('Entertainment', 'Entertainment and leisure', '#E91E63', 'movie', 'expense'),
    ('Healthcare', 'Medical expenses', '#F44336', 'local_hospital', 'expense'),
    ('Shopping', 'Shopping and retail', '#9E9E9E', 'shopping_cart', 'expense'),
    ('Education', 'Education expenses', '#00BCD4', 'school', 'expense'),
    ('Rent', 'Rent and housing', '#795548', 'home', 'expense'),
    ('Other Expense', 'Other expenses', '#607D8B', 'more_horiz', 'expense');

-- ==================== VIEWS ====================

-- Transaction summary by month
CREATE VIEW transaction_monthly_summary AS
SELECT 
    profile_id,
    DATE_TRUNC('month', transaction_date) AS month,
    type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
WHERE status = 'completed'
GROUP BY profile_id, DATE_TRUNC('month', transaction_date), type;

-- Active goals progress
CREATE VIEW active_goals_progress AS
SELECT 
    g.id,
    g.profile_id,
    g.name,
    g.target_amount,
    g.current_amount,
    g.target_date,
    ROUND((g.current_amount / g.target_amount) * 100, 2) AS progress_percentage,
    g.target_amount - g.current_amount AS remaining_amount,
    EXTRACT(DAY FROM g.target_date - NOW()) AS days_remaining
FROM goals g
WHERE g.status = 'active';

-- Budget vs spending
CREATE VIEW budget_spending_summary AS
SELECT 
    b.id,
    b.profile_id,
    b.name,
    b.budget_amount,
    b.spent_amount,
    b.budget_amount - b.spent_amount AS remaining_amount,
    ROUND((b.spent_amount / b.budget_amount) * 100, 2) AS spent_percentage,
    CASE 
        WHEN b.spent_amount > b.budget_amount THEN TRUE
        ELSE FALSE
    END AS is_over_budget,
    b.start_date,
    b.end_date
FROM budgets b
WHERE b.is_active = TRUE
    AND NOW() BETWEEN b.start_date AND b.end_date;

-- ==================== COMMENTS ====================

COMMENT ON TABLE profiles IS 'User profiles and account information';
COMMENT ON TABLE sessions IS 'Active user sessions for authentication';
COMMENT ON TABLE categories IS 'Transaction categories';
COMMENT ON TABLE transactions IS 'All financial transactions';
COMMENT ON TABLE pending_transactions IS 'SMS-detected transactions awaiting review';
COMMENT ON TABLE goals IS 'Financial goals and savings targets';
COMMENT ON TABLE budgets IS 'Budget plans and tracking';
COMMENT ON TABLE clients IS 'Clients for invoicing';
COMMENT ON TABLE invoices IS 'Invoices for business users';
COMMENT ON TABLE loans IS 'Loan tracking and management';
COMMENT ON TABLE sync_queue IS 'Queue for syncing local changes to server';
COMMENT ON TABLE risk_assessments IS 'User investment risk profile assessments';
