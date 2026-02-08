# budgets/migrations/0003_budget_soft_delete_fields.py
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('budgets', '0002_budget_currency_budget_valid_currency'),
    ]

    operations = [
        migrations.AddField(
            model_name='budget',
            name='is_deleted',
            field=models.BooleanField(db_index=True, default=False),
        ),
        migrations.AddField(
            model_name='budget',
            name='deleted_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]