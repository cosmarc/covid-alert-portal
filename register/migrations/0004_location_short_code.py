# Generated by Django 3.1.6 on 2021-02-08 16:46

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('register', '0003_auto_20210204_1508'),
    ]

    operations = [
        migrations.AddField(
            model_name='location',
            name='short_code',
            field=models.CharField(default='123456', max_length=8, unique=True, verbose_name='Short code'),
            preserve_default=False,
        ),
    ]