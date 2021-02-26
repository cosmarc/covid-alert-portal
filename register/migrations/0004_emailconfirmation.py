# Generated by Django 3.1.6 on 2021-02-11 18:08

from django.db import migrations, models
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('register', '0003_auto_20210204_1508'),
    ]

    operations = [
        migrations.CreateModel(
            name='EmailConfirmation',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('email', models.EmailField(max_length=255, verbose_name='email')),
                ('created', models.DateTimeField(auto_now_add=True)),
            ],
        ),
    ]