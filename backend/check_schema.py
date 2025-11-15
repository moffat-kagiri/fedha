#!/usr/bin/env python
"""Check database schema for encryption tables."""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
tables = [row[0] for row in cursor.fetchall()]

print("\nDatabase tables:")
for table in sorted(tables):
    if 'api' in table:
        cursor.execute(f"PRAGMA table_info({table})")
        cols = cursor.fetchall()
        print(f"\n  {table}:")
        for col in cols[:5]:  # Show first 5 columns
            print(f"    - {col[1]} ({col[2]})")
        if len(cols) > 5:
            print(f"    ... and {len(cols)-5} more columns")

print("\n")
