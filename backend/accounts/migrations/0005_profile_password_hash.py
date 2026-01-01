# Generated migration to add the password_hash column

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0004_alter_profile_password"),
    ]

    operations = [
        # Add password_hash column if it doesn't exist
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='password_hash'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT '';
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
                    ALTER TABLE profiles DROP COLUMN password_hash;
                END IF;
            END $$;
            """,
        ),
    ]
