# Generated corrective migration: add profile FK to EncryptionKeyVersion and KeyRotationLog
from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0006_add_encrypted_pii_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='encryptionkeyversion',
            name='profile',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='api.profile'),
        ),
        migrations.AddField(
            model_name='keyrotationlog',
            name='profile',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='api.profile'),
        ),
    ]
