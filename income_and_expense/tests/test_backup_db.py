"""backup_db 管理コマンドのテスト。

R2 には実際に接続せず、put/list/delete を記録する偽クライアントに差し替えて検証する。
"""
import gzip
import json
import os
import tempfile
from io import StringIO
from unittest import mock

from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase, override_settings

from income_and_expense.management.commands.backup_db import Command as BackupCommand
from income_and_expense.tests.factories import make_expense

R2_SETTINGS = {
    'BACKUP_R2_BUCKET_NAME': 'backups',
    'BACKUP_R2_ACCESS_KEY_ID': 'ak',
    'BACKUP_R2_SECRET_ACCESS_KEY': 'sk',
    'BACKUP_R2_ENDPOINT_URL': 'https://acc.r2.cloudflarestorage.com',
    'BACKUP_PREFIX': 'income-and-expense/db-backups/',
    'BACKUP_RETENTION': 30,
}


class FakeR2:
    """list_objects_v2 / put_object / delete_objects だけを持つ偽 S3 クライアント。"""

    def __init__(self, existing_keys=None):
        self.store = {k: b'' for k in (existing_keys or [])}
        self.put_calls = []
        self.deleted = []

    def put_object(self, Bucket, Key, Body, **kwargs):
        self.store[Key] = Body
        self.put_calls.append((Bucket, Key, Body))

    def list_objects_v2(self, Bucket, Prefix='', **kwargs):
        contents = [{'Key': k} for k in self.store if k.startswith(Prefix)]
        return {'Contents': contents, 'IsTruncated': False}

    def delete_objects(self, Bucket, Delete):
        for obj in Delete['Objects']:
            self.store.pop(obj['Key'], None)
            self.deleted.append(obj['Key'])


def _key(day):
    return f'income-and-expense/db-backups/income-and-expense-202601{day:02d}T000000Z.json.gz'


@override_settings(**R2_SETTINGS)
class BackupDbCommandTests(TestCase):
    def setUp(self):
        make_expense()

    def _run(self, fake, *args):
        with mock.patch.object(BackupCommand, '_r2_client', return_value=fake):
            call_command('backup_db', *args, stdout=StringIO())

    def test_local_only_writes_valid_gzip_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = os.getcwd()
            os.chdir(tmp)
            try:
                call_command('backup_db', '--local-only', stdout=StringIO())
            finally:
                os.chdir(cwd)
            files = [f for f in os.listdir(tmp) if f.endswith('.json.gz')]
            self.assertEqual(len(files), 1)
            self.assertTrue(files[0].startswith('income-and-expense-'))
            with gzip.open(os.path.join(tmp, files[0]), 'rt', encoding='utf-8') as f:
                data = json.load(f)

        models = {row['model'] for row in data}
        # 業務データは含まれ、migrate で再生成されるものは含まれない
        self.assertIn('income_and_expense.expense', models)
        self.assertIn('income_and_expense.method', models)
        self.assertNotIn('contenttypes.contenttype', models)
        self.assertNotIn('auth.permission', models)

    def test_upload_puts_gzip_json_to_r2(self):
        fake = FakeR2()
        self._run(fake)

        self.assertEqual(len(fake.put_calls), 1)
        bucket, key, body = fake.put_calls[0]
        self.assertEqual(bucket, 'backups')
        self.assertTrue(key.startswith('income-and-expense/db-backups/income-and-expense-'))
        self.assertTrue(key.endswith('.json.gz'))
        json.loads(gzip.decompress(body).decode('utf-8'))

    @override_settings(BACKUP_R2_BUCKET_NAME='')
    def test_missing_bucket_raises(self):
        with self.assertRaisesMessage(CommandError, 'BACKUP_R2_BUCKET_NAME'):
            call_command('backup_db', stdout=StringIO())

    @override_settings(BACKUP_R2_SECRET_ACCESS_KEY=None)
    def test_missing_credentials_raises(self):
        with self.assertRaisesMessage(CommandError, 'BACKUP_R2_SECRET_ACCESS_KEY'):
            call_command('backup_db', stdout=StringIO())

    @override_settings(BACKUP_RETENTION=3)
    def test_prune_keeps_newest_generations(self):
        other_app = 'rentalist/db-backups/rentalist-20250101T000000Z.json.gz'
        fake = FakeR2(existing_keys=[_key(d) for d in range(1, 6)] + [other_app])
        self._run(fake)

        # アップロード後の6世代のうち新しい3世代だけ残り、最古の3世代が消える
        ours = [k for k in fake.store if k.startswith('income-and-expense/')]
        self.assertEqual(len(ours), 3)
        self.assertEqual(sorted(fake.deleted), [_key(1), _key(2), _key(3)])
        # 接頭辞の違う他アプリのダンプには触れない
        self.assertIn(other_app, fake.store)

    @override_settings(BACKUP_RETENTION=1)
    def test_no_prune_skips_deletion(self):
        fake = FakeR2(existing_keys=[_key(1)])
        self._run(fake, '--no-prune')
        self.assertEqual(fake.deleted, [])

    def test_keep_option_overrides_retention(self):
        fake = FakeR2(existing_keys=[_key(d) for d in range(1, 4)])
        self._run(fake, '--keep', '1')
        self.assertEqual(len(fake.store), 1)
