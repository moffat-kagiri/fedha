#!/usr/bin/env python
"""
Script to verify database schema matches Django models
Run from backend directory: python check_schema.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fedha_backend.settings')
django.setup()

from django.db import connection

def check_table_columns(table_name, expected_columns):
    """Check if table has expected columns"""
    cursor = connection.cursor()
    cursor.execute(f"""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='{table_name}' 
        ORDER BY column_name;
    """)
    
    db_columns = {row[0] for row in cursor.fetchall()}
    
    print(f"\n{'='*60}")
    print(f"TABLE: {table_name}")
    print(f"{'='*60}")
    
    print(f"\n✓ Columns present in database:")
    for col in sorted(db_columns):
        status = "✓" if col in expected_columns else "⚠"
        print(f"  {status} {col}")
    
    print(f"\n✗ Expected columns missing from database:")
    for col in sorted(expected_columns - db_columns):
        print(f"  ✗ {col}")
    
    print(f"\n⚠ Extra columns in database (not in model):")
    for col in sorted(db_columns - expected_columns):
        print(f"  ⚠ {col}")

# Define expected columns for each table based on Django models
tables_to_check = {
    'budgets': {
        'id', 'profile_id', 'category_id', 'name', 'description',
        'budget_amount',  # ⚠ This is what Django expects
        'spent_amount', 'period', 'start_date', 'end_date',
        'is_active', 'is_synced', 'created_at', 'updated_at'
    },
    'transactions': {
        'id', 'profile_id', 'category_id', 'goal_id', 
        'amount',  # ⚠ Check if DB has 'amount' or 'amount_minor'
        'type', 'status', 'payment_method', 'description',
        'notes', 'reference', 'recipient', 'sms_source',
        'is_expense', 'is_pending', 'is_recurring', 'is_synced',
        'transaction_date', 'created_at', 'updated_at'
    },
    'goals': {
        'id', 'profile_id', 'name', 'description',
        'target_amount', 'current_amount', 'currency',
        'target_date', 'completed_date', 'goal_type', 'status', 'priority',
        'is_synced', 'created_at', 'updated_at'
    },
    'loans': {
        'id', 'profile_id', 'name',
        'principal_amount',  # ⚠ Check if DB has different name
        'remaining_amount', 'currency',
        'annual_interest_rate', 'interest_model',
        'start_date', 'maturity_date', 'status',
        'is_synced', 'created_at', 'updated_at'
    }
}

print("\n" + "="*60)
print("DATABASE SCHEMA VERIFICATION")
print("="*60)

for table_name, expected_cols in tables_to_check.items():
    check_table_columns(table_name, expected_cols)

print("\n" + "="*60)
print("VERIFICATION COMPLETE")
print("="*60)
print("\n⚠ Fix any schema mismatches before running sync operations")