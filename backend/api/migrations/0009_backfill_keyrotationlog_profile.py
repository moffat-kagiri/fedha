# Backfill KeyRotationLog.profile and make field non-nullable
from django.db import migrations, models
import django.db.models.deletion


def forwards(apps, schema_editor):
    Profile = apps.get_model('api', 'Profile')
    EKV = apps.get_model('api', 'EncryptionKeyVersion')
    KRL = apps.get_model('api', 'KeyRotationLog')

    # Create or reuse a system profile to attach orphan logs when no mapping found
    system_profile = Profile.objects.filter(name='__system_key_rotation__').first()
    if not system_profile:
        # Use Django's password hasher to satisfy pin_hash non-null requirement
        try:
            from django.contrib.auth.hashers import make_password
            ph = make_password('!')
        except Exception:
            ph = '!'  # fallback if hasher unavailable
        system_profile = Profile.objects.create(name='__system_key_rotation__', email='system@localhost', pin_hash=ph, is_active=False)

    # Backfill logs: try to map by finding a key version with same old/new version
    orphan_logs = KRL.objects.filter(profile__isnull=True)
    for log in orphan_logs:
        matched = EKV.objects.filter(version=log.old_version).exclude(profile__isnull=True).first()
        if not matched:
            matched = EKV.objects.filter(version=log.new_version).exclude(profile__isnull=True).first()
        if matched and matched.profile:
            log.profile = matched.profile
        else:
            # fallback to any existing non-system profile
            fallback = Profile.objects.exclude(id=system_profile.id).first()
            log.profile = fallback if fallback else system_profile
        log.save()


def reverse(apps, schema_editor):
    # We won't reverse data backfill (making nullable again is a schema operation)
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0008_alter_encryptionkeyversion_options_and_more'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse),
        migrations.AlterField(
            model_name='keyrotationlog',
            name='profile',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.profile'),
        ),
    ]
