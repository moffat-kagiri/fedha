# Generated migration to map Django's password field to database's password_hash column

import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0003_alter_profile_email_alter_profile_first_name_and_more"),
    ]

    operations = [
        # Rename password column to password_hash if it exists
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='password'
                ) THEN
                    ALTER TABLE profiles RENAME COLUMN password TO password_hash;
                END IF;
            END $$;
            """,
            reverse_sql="""
            DO $$
            BEGIN
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='password_hash'
                ) THEN
                    ALTER TABLE profiles RENAME COLUMN password_hash TO password;
                END IF;
            END $$;
            """,
        ),
        # Alter the field definition to use db_column mapping
        migrations.AlterField(
            model_name="profile",
            name="password",
            field=models.CharField(db_column='password_hash', max_length=255),
        ),
    ]
