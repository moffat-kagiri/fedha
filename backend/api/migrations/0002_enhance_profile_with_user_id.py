# Generated by Django 4.2.21 on 2025-06-02 16:30

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        # Add user_id field for 8-digit user IDs
        migrations.AddField(
            model_name='profile',
            name='user_id',
            field=models.CharField(
                blank=True,
                help_text='8-digit user ID for cross-device login (e.g., 12345678)',
                max_length=8,
                null=True,
                unique=True
            ),
        ),
        # Add email field for user communication
        migrations.AddField(
            model_name='profile',
            name='email',
            field=models.EmailField(
                blank=True,
                help_text='Email address for notifications and account recovery',
                null=True
            ),
        ),
        # Change Profile ID from UUID to CharField for 8-digit IDs
        migrations.AlterField(
            model_name='profile',
            name='id',
            field=models.CharField(
                editable=False,
                help_text='Unique identifier with B/P prefix for business/personal accounts (9 chars: X-XXXXXXX)',
                max_length=9,
                primary_key=True,
                serialize=False,
                verbose_name='Profile ID'
            ),
        ),
        # Update default values for currency and timezone
        migrations.AlterField(
            model_name='profile',
            name='base_currency',
            field=models.CharField(
                default='KES',
                help_text='ISO 4217 currency code for primary calculations',
                max_length=3
            ),
        ),
        migrations.AlterField(
            model_name='profile',
            name='timezone',
            field=models.CharField(
                default='GMT+3',
                help_text='Timezone for date/time display',
                max_length=50
            ),
        ),
        # Add indexes for new fields
        migrations.AddIndex(
            model_name='profile',
            index=models.Index(fields=['user_id'], name='api_profile_user_id_idx'),
        ),
        migrations.AddIndex(
            model_name='profile',
            index=models.Index(fields=['email'], name='api_profile_email_idx'),
        ),
    ]
