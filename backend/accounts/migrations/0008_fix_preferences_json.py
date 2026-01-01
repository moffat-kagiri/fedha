# Migration to fix preferences JSONField data corruption

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0007_remove_user_id"),
    ]

    operations = [
        # Ensure preferences column exists and is proper JSONB type with correct data
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                -- Drop the old preferences column if it exists
                IF EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='preferences'
                ) THEN
                    ALTER TABLE profiles DROP COLUMN preferences;
                END IF;
                
                -- Create preferences as JSONB with proper default
                ALTER TABLE profiles ADD COLUMN preferences JSONB DEFAULT '{}'::jsonb;
            END $$;
            """,
        ),
        # Update field definition
        migrations.AlterField(
            model_name='profile',
            name='preferences',
            field=models.JSONField(default=dict, blank=True),
        ),
    ]
