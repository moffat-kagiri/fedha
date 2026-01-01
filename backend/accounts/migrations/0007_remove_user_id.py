# Migration to remove user_id column that's not part of the Profile model

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0006_add_missing_profile_columns"),
    ]

    operations = [
        # Drop user_id column if it exists (not part of our Profile model)
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='user_id'
                ) THEN
                    ALTER TABLE profiles DROP COLUMN user_id;
                END IF;
            END $$;
            """,
        ),
    ]
