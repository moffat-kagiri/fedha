# Generated migration for soft delete fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('goals', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='goal',
            name='is_deleted',
            field=models.BooleanField(db_index=True, default=False),
        ),
        migrations.AddField(
            model_name='goal',
            name='deleted_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
