import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fedha_backend.settings')
django.setup()

from django.db import connection
from accounts.models import Profile

# Get model fields
model_fields = {f.name: (f.db_column or f.name) for f in Profile._meta.get_fields() if hasattr(f, 'db_column')}

# Get database columns
cursor = connection.cursor()
cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name='profiles' ORDER BY column_name;")
db_columns = {row[0] for row in cursor.fetchall()}

print("=== Model Fields (that require DB columns) ===")
for field_name, db_col in sorted(model_fields.items()):
    exists = "✓" if db_col in db_columns else "✗"
    print(f"{exists} {field_name} → {db_col}")

print("\n=== Missing Columns ===")
for field_name, db_col in sorted(model_fields.items()):
    if db_col not in db_columns:
        print(f"MISSING: {db_col}")

print("\n=== All Actual DB Columns ===")
for col in sorted(db_columns):
    print(f"  {col}")
