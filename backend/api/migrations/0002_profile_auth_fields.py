# Generated migration for Profile model auth fields

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('api', '0001_initial'),  # Adjust based on your actual migration name
    ]

    operations = [
        # Add password_hash field for SHA-256 hashing
        migrations.AddField(
            model_name='profile',
            name='password_hash',
            field=models.CharField(
                blank=True,
                max_length=64,
                null=True,
                help_text='SHA-256 hash of password for frontend-compatible offline login'
            ),
        ),
        
        # Add phone field
        migrations.AddField(
            model_name='profile',
            name='phone',
            field=models.CharField(
                blank=True,
                max_length=20,
                null=True,
                help_text='Phone number for SMS notifications and recovery'
            ),
        ),
        
        # Make pin_hash nullable (it's now legacy)
        migrations.AlterField(
            model_name='profile',
            name='pin_hash',
            field=models.CharField(
                blank=True,
                max_length=128,
                null=True,
                help_text='SHA-256 hash of 4-digit PIN with application salt (legacy)'
            ),
        ),
        
        # Update timezone default
        migrations.AlterField(
            model_name='profile',
            name='timezone',
            field=models.CharField(
                default='Africa/Nairobi',
                max_length=50,
                help_text='Timezone for date/time display'
            ),
        ),
        
        # Add index for phone field only (user field already indexed via OneToOne relationship)
        migrations.AddIndex(
            model_name='profile',
            index=models.Index(fields=['phone'], name='api_profile_phone_idx'),
        ),
    ]
