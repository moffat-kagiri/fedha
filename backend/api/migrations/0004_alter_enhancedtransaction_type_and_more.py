# Generated by Django 4.2.23 on 2025-07-23 17:47

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        (
            "api",
            "0003_rename_api_profile_user_id_idx_api_profile_user_id_bc09a5_idx_and_more",
        ),
    ]

    operations = [
        migrations.AlterField(
            model_name="enhancedtransaction",
            name="type",
            field=models.CharField(
                choices=[
                    ("IN", "Income"),
                    ("EX", "Expense"),
                    ("SAV", "Savings"),
                    ("TR", "Transfer"),
                    ("ADJ", "Adjustment"),
                ],
                help_text="Primary transaction classification",
                max_length=3,
            ),
        ),
        migrations.AlterField(
            model_name="recurringtransactiontemplate",
            name="type",
            field=models.CharField(
                choices=[
                    ("IN", "Income"),
                    ("EX", "Expense"),
                    ("SAV", "Savings"),
                    ("TR", "Transfer"),
                    ("ADJ", "Adjustment"),
                ],
                max_length=3,
            ),
        ),
    ]
