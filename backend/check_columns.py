import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fedha_backend.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()
cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name='profiles' ORDER BY column_name;")
columns = cursor.fetchall()

print("Columns in profiles table:")
for col in columns:
    print(f"  - {col[0]}")
