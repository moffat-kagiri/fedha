# Migration to add missing columns to align with Profile model

from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0005_profile_password_hash"),
    ]

    operations = [
        # Add display_name column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='display_name'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN display_name VARCHAR(255);
                END IF;
            END $$;
            """,
        ),
        # Add base_currency column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='base_currency'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN base_currency VARCHAR(3) DEFAULT 'KES';
                END IF;
            END $$;
            """,
        ),
        # Add user_timezone column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='user_timezone'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN user_timezone VARCHAR(50) DEFAULT 'Africa/Nairobi';
                END IF;
            END $$;
            """,
        ),
        # Add photo_url column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='photo_url'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN photo_url TEXT;
                END IF;
            END $$;
            """,
        ),
        # Add is_active column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='is_active'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
                END IF;
            END $$;
            """,
        ),
        # Add is_staff column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='is_staff'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN is_staff BOOLEAN DEFAULT false;
                END IF;
            END $$;
            """,
        ),
        # Add is_superuser column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='is_superuser'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN is_superuser BOOLEAN DEFAULT false;
                END IF;
            END $$;
            """,
        ),
        # Add last_login column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='last_login'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN last_login TIMESTAMP;
                END IF;
            END $$;
            """,
        ),
        # Add last_synced column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='last_synced'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN last_synced TIMESTAMP;
                END IF;
            END $$;
            """,
        ),
        # Add preferences column
        migrations.RunSQL(
            sql="""
            DO $$
            BEGIN
                IF NOT EXISTS(
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name='profiles' AND column_name='preferences'
                ) THEN
                    ALTER TABLE profiles ADD COLUMN preferences JSON DEFAULT '{}';
                END IF;
            END $$;
            """,
        ),
    ]
