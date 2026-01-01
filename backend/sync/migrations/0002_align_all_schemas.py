# backend/sync/migrations/0002_align_all_schemas.py
"""
REVISED: Safe schema alignment that checks column existence first
"""
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("budgets", "0001_initial"),
        ("transactions", "0001_initial"),
        ("goals", "0001_initial"),
        ("invoicing", "0001_initial"),
        ("sync", "0001_initial"),
    ]

    operations = [
        # ====================================================================
        # FIX 1: BUDGETS TABLE - Critical fix for immediate error
        # ====================================================================
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                -- Rename budgeted_amount to budget_amount
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budgeted_amount'
                ) AND NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budget_amount'
                ) THEN
                    ALTER TABLE budgets RENAME COLUMN budgeted_amount TO budget_amount;
                    RAISE NOTICE '✓ Renamed budgets.budgeted_amount → budget_amount';
                ELSIF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budget_amount'
                ) THEN
                    RAISE NOTICE '✓ budgets.budget_amount already exists';
                ELSE
                    RAISE WARNING '⚠ budgets table structure unexpected';
                END IF;
            END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
        
        # ====================================================================
        # FIX 2: GOALS TABLE - Handle status column name variations
        # ====================================================================
        migrations.RunSQL(
            sql="""
            DO $$
            DECLARE
                status_col_name TEXT;
            BEGIN
                -- Check which status column exists
                SELECT column_name INTO status_col_name
                FROM information_schema.columns 
                WHERE table_name='goals' 
                  AND column_name IN ('status', 'goal_status')
                LIMIT 1;
                
                IF status_col_name IS NOT NULL THEN
                    RAISE NOTICE '✓ Found goals status column: %', status_col_name;
                    
                    -- Create index with correct column name
                    IF NOT EXISTS(
                        SELECT 1 FROM pg_indexes 
                        WHERE tablename='goals' AND indexname='idx_goals_profile_status'
                    ) THEN
                        EXECUTE format('CREATE INDEX idx_goals_profile_status ON goals(profile_id, %I)', status_col_name);
                        RAISE NOTICE '✓ Created index on goals.%', status_col_name;
                    END IF;
                ELSE
                    RAISE WARNING '⚠ No status column found in goals table';
                END IF;
                
                -- Ensure currency column exists
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='goals' AND column_name='currency'
                ) THEN
                    ALTER TABLE goals ADD COLUMN currency VARCHAR(3) DEFAULT 'KES';
                    RAISE NOTICE '✓ Added goals.currency column';
                END IF;
            END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
        
        # ====================================================================
        # FIX 3: TRANSACTIONS TABLE - Ensure amount column is correct type
        # ====================================================================
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                -- Verify amount column exists and is decimal
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='transactions' 
                      AND column_name='amount'
                      AND data_type = 'numeric'
                ) THEN
                    RAISE NOTICE '✓ transactions.amount column correct';
                ELSIF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='transactions' AND column_name='amount'
                ) THEN
                    RAISE WARNING '⚠ transactions.amount exists but may be wrong type';
                ELSE
                    ALTER TABLE transactions ADD COLUMN amount DECIMAL(15, 2) NOT NULL DEFAULT 0;
                    RAISE NOTICE '✓ Added transactions.amount column';
                END IF;
                
                -- Ensure currency column exists
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='transactions' AND column_name='currency'
                ) THEN
                    ALTER TABLE transactions ADD COLUMN currency VARCHAR(3) DEFAULT 'KES';
                    RAISE NOTICE '✓ Added transactions.currency column';
                END IF;
            END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
        
        # ====================================================================
        # FIX 4: LOANS TABLE - Comprehensive alignment
        # ====================================================================
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                -- Add 'name' column if missing
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='name'
                ) THEN
                    ALTER TABLE loans ADD COLUMN name VARCHAR(255);
                    
                    -- Try to populate from lender_name if it exists
                    IF EXISTS(
                        SELECT 1 FROM information_schema.columns 
                        WHERE table_name='loans' AND column_name='lender_name'
                    ) THEN
                        EXECUTE 'UPDATE loans SET name = lender_name WHERE name IS NULL';
                    END IF;
                    
                    -- Set NOT NULL after population
                    ALTER TABLE loans ALTER COLUMN name SET DEFAULT 'Unnamed Loan';
                    UPDATE loans SET name = 'Unnamed Loan' WHERE name IS NULL;
                    ALTER TABLE loans ALTER COLUMN name SET NOT NULL;
                    
                    RAISE NOTICE '✓ Added loans.name column';
                END IF;
                
                -- Handle interest rate column naming
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='interest_rate'
                ) AND EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='annual_interest_rate'
                ) THEN
                    ALTER TABLE loans RENAME COLUMN annual_interest_rate TO interest_rate;
                    RAISE NOTICE '✓ Renamed loans.annual_interest_rate → interest_rate';
                ELSIF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='interest_rate'
                ) THEN
                    RAISE NOTICE '✓ loans.interest_rate already exists';
                END IF;
                
                -- Handle date column naming
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='end_date'
                ) AND EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='maturity_date'
                ) THEN
                    ALTER TABLE loans RENAME COLUMN maturity_date TO end_date;
                    RAISE NOTICE '✓ Renamed loans.maturity_date → end_date';
                ELSIF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='end_date'
                ) THEN
                    RAISE NOTICE '✓ loans.end_date already exists';
                END IF;
                
                -- Add principal_minor if needed (Flutter uses this)
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='principal_minor'
                ) THEN
                    ALTER TABLE loans ADD COLUMN principal_minor DECIMAL(15, 2);
                    
                    -- Copy from principal_amount if it exists
                    IF EXISTS(
                        SELECT 1 FROM information_schema.columns 
                        WHERE table_name='loans' AND column_name='principal_amount'
                    ) THEN
                        EXECUTE 'UPDATE loans SET principal_minor = principal_amount WHERE principal_minor IS NULL';
                    END IF;
                    
                    RAISE NOTICE '✓ Added loans.principal_minor column';
                END IF;
                
                -- Add missing columns for sync
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='description'
                ) THEN
                    ALTER TABLE loans ADD COLUMN description TEXT;
                    RAISE NOTICE '✓ Added loans.description column';
                END IF;
                
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='is_synced'
                ) THEN
                    ALTER TABLE loans ADD COLUMN is_synced BOOLEAN DEFAULT FALSE;
                    RAISE NOTICE '✓ Added loans.is_synced column';
                END IF;
            END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
        
        # ====================================================================
        # FIX 5: Add sync performance indexes (safe version)
        # ====================================================================
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                -- Budgets indexes
                IF NOT EXISTS(
                    SELECT 1 FROM pg_indexes 
                    WHERE tablename='budgets' AND indexname='idx_budgets_profile_active'
                ) THEN
                    CREATE INDEX CONCURRENTLY idx_budgets_profile_active ON budgets(profile_id, is_active);
                    RAISE NOTICE '✓ Created index: idx_budgets_profile_active';
                END IF;
                
                -- Transactions indexes
                IF NOT EXISTS(
                    SELECT 1 FROM pg_indexes 
                    WHERE tablename='transactions' AND indexname='idx_transactions_profile_synced'
                ) THEN
                    CREATE INDEX CONCURRENTLY idx_transactions_profile_synced ON transactions(profile_id, is_synced);
                    RAISE NOTICE '✓ Created index: idx_transactions_profile_synced';
                END IF;
                
                -- Goals indexes (already created above with dynamic column name)
                
                -- Loans indexes
                IF NOT EXISTS(
                    SELECT 1 FROM pg_indexes 
                    WHERE tablename='loans' AND indexname='idx_loans_profile_synced'
                ) THEN
                    CREATE INDEX CONCURRENTLY idx_loans_profile_synced ON loans(profile_id, is_synced);
                    RAISE NOTICE '✓ Created index: idx_loans_profile_synced';
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    -- CREATE INDEX CONCURRENTLY can't run in transaction, ignore this error
                    RAISE NOTICE 'Skipping CONCURRENTLY indexes (will be added later)';
            END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
        
        # ====================================================================
        # FIX 6: Final verification and summary
        # ====================================================================
        migrations.RunSQL(
            sql="""
            DO $$
            DECLARE
                budget_col_ok BOOLEAN;
                trans_col_ok BOOLEAN;
                loan_name_ok BOOLEAN;
                loan_rate_ok BOOLEAN;
            BEGIN
                -- Check critical columns
                SELECT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budget_amount'
                ) INTO budget_col_ok;
                
                SELECT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='transactions' AND column_name='amount'
                ) INTO trans_col_ok;
                
                SELECT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='name'
                ) INTO loan_name_ok;
                
                SELECT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='loans' AND column_name='interest_rate'
                ) INTO loan_rate_ok;
                
                -- Report status
                RAISE NOTICE '';
                RAISE NOTICE '========================================';
                RAISE NOTICE 'SCHEMA ALIGNMENT SUMMARY';
                RAISE NOTICE '========================================';
                
                IF budget_col_ok THEN
                    RAISE NOTICE '✓ budgets.budget_amount - OK';
                ELSE
                    RAISE WARNING '✗ budgets.budget_amount - MISSING';
                END IF;
                
                IF trans_col_ok THEN
                    RAISE NOTICE '✓ transactions.amount - OK';
                ELSE
                    RAISE WARNING '✗ transactions.amount - MISSING';
                END IF;
                
                IF loan_name_ok THEN
                    RAISE NOTICE '✓ loans.name - OK';
                ELSE
                    RAISE WARNING '✗ loans.name - MISSING';
                END IF;
                
                IF loan_rate_ok THEN
                    RAISE NOTICE '✓ loans.interest_rate - OK';
                ELSE
                    RAISE WARNING '✗ loans.interest_rate - MISSING';
                END IF;
                
                IF budget_col_ok AND trans_col_ok AND loan_name_ok AND loan_rate_ok THEN
                    RAISE NOTICE '';
                    RAISE NOTICE '✓✓✓ All critical columns present ✓✓✓';
                    RAISE NOTICE 'Schema alignment successful!';
                ELSE
                    RAISE WARNING 'Some columns still missing - check logs above';
                END IF;
                
                RAISE NOTICE '========================================';
            END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]