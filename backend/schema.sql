-- Fedha Financial Management System - PostgreSQL Schema
-- PostgreSQL 17 Compatible
-- Updated with string-based category and goal_id fields

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== ENUMS ====================

CREATE TYPE profile_type AS ENUM ('personal', 'business', 'family', 'student');
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'savings', 'transfer');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled', 'refunded');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'bank', 'mobile', 'online', 'cheque', 'mpesa', 'bank_transfer', 'other');
CREATE TYPE goal_type AS ENUM ('savings', 'debtReduction', 'insurance', 'emergencyFund', 'investment', 'other');
CREATE TYPE goal_status AS ENUM ('active', 'completed', 'paused', 'cancelled');
CREATE TYPE budget_period AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'yearly');
CREATE TYPE invoice_status AS ENUM ('draft', 'sent', 'paid', 'overdue', 'cancelled');
CREATE TYPE interest_model AS ENUM ('simple', 'compound', 'reducingBalance');
CREATE TYPE category_type AS ENUM ('income', 'expense', 'savings');

-- ==================== CORE TABLES ====================

-- Profiles (Users) - Custom User Model
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    profile_type profile_type DEFAULT 'personal',
    base_currency VARCHAR(3) DEFAULT 'KES',
    user_timezone VARCHAR(50) DEFAULT 'Africa/Nairobi',
    photo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_staff BOOLEAN DEFAULT FALSE,
    is_superuser BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    last_synced TIMESTAMPTZ,
    preferences JSONB DEFAULT '{}'::jsonb,
    
    CONSTRAINT email_or_phone_required CHECK (email IS NOT NULL OR phone_number IS NOT NULL)
);

-- Sessions for authentication
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    session_token VARCHAR(500) UNIQUE NOT NULL,
    auth_token VARCHAR(255) UNIQUE,
    device_id VARCHAR(255),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Categories - Updated with is_active and is_synced
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(7),
    icon_name VARCHAR(100),
    type category_type DEFAULT 'expense',
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_synced BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_profile_category_name UNIQUE (profile_id, name)
);

-- Default Categories Template
CREATE TABLE default_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(7) NOT NULL,
    icon_name VARCHAR(100) NOT NULL,
    type category_type NOT NULL
);

-- Goals
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    goal_type goal_type NOT NULL,
    goal_status goal_status DEFAULT 'active',
    target_amount DECIMAL(15, 2) NOT NULL CHECK (target_amount > 0),
    current_amount DECIMAL(15, 2) DEFAULT 0 CHECK (current_amount >= 0),
    currency VARCHAR(3) DEFAULT 'KES',
    target_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    last_contribution_date TIMESTAMPTZ,
    contribution_count INTEGER DEFAULT 0,
    average_contribution DECIMAL(15, 2),
    linked_category VARCHAR(255),  -- Changed from linked_category_id UUID to VARCHAR
    projected_completion_date TIMESTAMPTZ,
    days_ahead_behind INTEGER,
    goal_group VARCHAR(100),
    remote_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT goal_current_amount_check CHECK (
        current_amount <= target_amount OR goal_status = 'completed'
    )
);

-- ==================== TRANSACTIONS TABLE - UPDATED WITH STRING FIELDS ====================

-- Transactions - Updated with string category and goal_id
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- CHANGED: String fields instead of UUID foreign keys
    category VARCHAR(255),  -- Changed from category_id UUID
    goal_id VARCHAR(255),   -- Changed from goal_id UUID (stores goal name or ID as string)
    
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    type transaction_type NOT NULL,
    status transaction_status DEFAULT 'completed',
    currency VARCHAR(3) DEFAULT 'KES',
    payment_method payment_method,
    description TEXT,
    notes TEXT,
    reference VARCHAR(255),
    recipient VARCHAR(255),
    sms_source TEXT,
    
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- CORRECTED: Make is_expense nullable to match Django model
    is_expense BOOLEAN,
    is_pending BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    is_synced BOOLEAN DEFAULT FALSE,
    
    recurring_pattern VARCHAR(50),
    parent_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    
    -- Analytics fields
    merchant_name VARCHAR(255),
    merchant_category VARCHAR(100),
    tags VARCHAR(500) DEFAULT '',
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_flagged BOOLEAN DEFAULT FALSE,
    anomaly_score DECIMAL(5, 2) CHECK (anomaly_score IS NULL OR (anomaly_score >= 0 AND anomaly_score <= 1)),
    budget_period VARCHAR(50),
    budget_id UUID,
    budget_category_id VARCHAR(255),
    remote_id VARCHAR(255),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Pending Transactions (SMS candidates)
CREATE TABLE pending_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category VARCHAR(255),  -- Changed from category_id UUID
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    
    raw_text TEXT,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    type transaction_type DEFAULT 'expense',
    status transaction_status DEFAULT 'pending',
    
    confidence DECIMAL(3, 2) DEFAULT 0.5 CHECK (confidence >= 0 AND confidence <= 1),
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Budgets
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category VARCHAR(255),  -- Changed from category_id UUID
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    budget_amount DECIMAL(15, 2) NOT NULL CHECK (budget_amount > 0),
    spent_amount DECIMAL(15, 2) DEFAULT 0 CHECK (spent_amount >= 0),
    
    period budget_period DEFAULT 'monthly',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL CHECK (end_date > start_date),
    
    is_active BOOLEAN DEFAULT TRUE,
    is_synced BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
    
    is_active BOOLEAN DEFAULT TRUE,
    is_synced BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Invoices
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'KES',
    
    issue_date TIMESTAMPTZ NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    
    status invoice_status DEFAULT 'draft',
    
    description TEXT,
    notes TEXT,
    
    is_active BOOLEAN DEFAULT TRUE,
    is_synced BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Loans
CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    name VARCHAR(255) NOT NULL,
    principal_minor DECIMAL(15, 2) NOT NULL CHECK (principal_minor > 0),
    currency VARCHAR(3) DEFAULT 'KES',
    interest_rate DECIMAL(5, 2) NOT NULL CHECK (interest_rate >= 0 AND interest_rate <= 100),
    interest_model interest_model DEFAULT 'simple',
    
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL CHECK (end_date > start_date),
    
    status VARCHAR(50) DEFAULT 'active',
    description TEXT,
    remote_id VARCHAR(255),
    
    is_synced BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sync Queue
CREATE TABLE sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    action VARCHAR(20) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    data JSONB NOT NULL,
    
    status VARCHAR(20) DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    priority INTEGER DEFAULT 0,
    
    next_retry_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== INDEXES ====================

-- Profiles indexes
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_phone_number ON profiles(phone_number);
CREATE INDEX idx_profiles_is_active ON profiles(is_active);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);

-- Sessions indexes
CREATE INDEX idx_sessions_profile_id ON sessions(profile_id);
CREATE INDEX idx_sessions_session_token ON sessions(session_token);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

-- Categories indexes
CREATE INDEX idx_categories_profile_id ON categories(profile_id);
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_is_active ON categories(is_active);
CREATE INDEX idx_categories_name ON categories(name);

-- Goals indexes
CREATE INDEX idx_goals_profile_id ON goals(profile_id);
CREATE INDEX idx_goals_profile_status ON goals(profile_id, goal_status);
CREATE INDEX idx_goals_status ON goals(goal_status);
CREATE INDEX idx_goals_goal_type ON goals(goal_type);
CREATE INDEX idx_goals_target_date ON goals(target_date);
CREATE INDEX idx_goals_linked_category ON goals(linked_category_id);

-- Transactions indexes
CREATE INDEX idx_transactions_profile_id ON transactions(profile_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_goal_id ON transactions(goal_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_profile_date ON transactions(profile_id, date DESC);
CREATE INDEX idx_transactions_merchant ON transactions(merchant_name);
CREATE INDEX idx_transactions_location ON transactions(location);
CREATE INDEX idx_transactions_anomaly ON transactions(anomaly_score);
CREATE INDEX idx_transactions_budget_id ON transactions(budget_id);

-- Pending transactions indexes
CREATE INDEX idx_pending_transactions_profile_id ON pending_transactions(profile_id);
CREATE INDEX idx_pending_transactions_status ON pending_transactions(status);
CREATE INDEX idx_pending_transactions_created_at ON pending_transactions(created_at DESC);

-- Budgets indexes
CREATE INDEX idx_budgets_profile_id ON budgets(profile_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_budgets_period ON budgets(period);
CREATE INDEX idx_budgets_dates ON budgets(start_date, end_date);
CREATE INDEX idx_budgets_is_active ON budgets(is_active);
CREATE INDEX idx_budgets_is_synced ON budgets(is_synced);
CREATE INDEX idx_budgets_profile_active ON budgets(profile_id, is_active);

-- Clients indexes
CREATE INDEX idx_clients_profile_id ON clients(profile_id);
CREATE INDEX idx_clients_is_active ON clients(is_active);

-- Invoices indexes
CREATE INDEX idx_invoices_profile_id ON invoices(profile_id);
CREATE INDEX idx_invoices_client_id ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_dates ON invoices(issue_date, due_date);

-- Loans indexes
CREATE INDEX idx_loans_profile_id ON loans(profile_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_loans_dates ON loans(start_date, end_date);
CREATE INDEX idx_loans_profile_synced ON loans(profile_id, is_synced);

-- Sync queue indexes
CREATE INDEX idx_sync_queue_profile_id ON sync_queue(profile_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_priority ON sync_queue(priority DESC);
CREATE INDEX idx_sync_queue_next_retry_at ON sync_queue(next_retry_at);
CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id);

-- ==================== DEFAULT DATA ====================

-- Insert default categories template
INSERT INTO default_categories (name, color, icon_name, type) VALUES
    -- Income categories
    ('Salary', '#4CAF50', 'attach_money', 'income'),
    ('Business', '#2196F3', 'business', 'income'),
    ('Investment', '#9C27B0', 'trending_up', 'income'),
    ('Gift', '#FF9800', 'card_giftcard', 'income'),
    ('Other Income', '#607D8B', 'add_circle', 'income'),
    
    -- Expense categories
    ('Food', '#FF5722', 'restaurant', 'expense'),
    ('Transport', '#00BCD4', 'directions_car', 'expense'),
    ('Utilities', '#FFC107', 'lightbulb', 'expense'),
    ('Entertainment', '#E91E63', 'movie', 'expense'),
    ('Healthcare', '#F44336', 'local_hospital', 'expense'),
    ('Groceries', '#8BC34A', 'shopping_cart', 'expense'),
    ('Dining Out', '#FF6F00', 'local_dining', 'expense'),
    ('Shopping', '#673AB7', 'shopping_bag', 'expense'),
    ('Education', '#3F51B5', 'school', 'expense'),
    ('Rent', '#795548', 'home', 'expense'),
    ('Other Expense', '#9E9E9E', 'remove_circle', 'expense');

-- ==================== FUNCTIONS & TRIGGERS ====================

-- Function to auto-create categories for new profiles
CREATE OR REPLACE FUNCTION create_default_categories_for_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO categories (profile_id, name, description, color, icon_name, type, is_default, is_active)
    SELECT 
        NEW.id,
        name,
        description,
        color,
        icon_name,
        type::category_type,
        TRUE,
        TRUE
    FROM default_categories;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create categories on new profile
CREATE TRIGGER trigger_create_default_categories
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_default_categories_for_profile();

-- Function to update transaction date on update
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON loans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==================== GRANTS ====================

-- Grant necessary permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;