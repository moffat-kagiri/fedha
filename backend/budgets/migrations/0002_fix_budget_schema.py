# backend/budgets/migrations/0002_fix_budget_schema.py
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("budgets", "0001_initial"),
    ]

    operations = [
        # Rename budgeted_amount to budget_amount to match Django model
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                -- Check if budgeted_amount exists and budget_amount doesn't
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budgeted_amount'
                ) AND NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budget_amount'
                ) THEN
                    ALTER TABLE budgets RENAME COLUMN budgeted_amount TO budget_amount;
                END IF;
            END $$;
            """,
            reverse_sql="""
            DO $$
            BEGIN
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='budgets' AND column_name='budget_amount'
                ) THEN
                    ALTER TABLE budgets RENAME COLUMN budget_amount TO budgeted_amount;
                END IF;
            END $$;
            """,
        ),
    ]