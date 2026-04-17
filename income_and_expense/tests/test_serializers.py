"""シリアライザ層のテスト。"""
import datetime

from dateutil.relativedelta import relativedelta
from django.test import TestCase
from django.utils import timezone

from income_and_expense.models import StateChoices
from income_and_expense.serializers import (
    AccountSerializer, ExpenseSerializer, IncomeSerializer, LoanSerializer,
    MethodSerializer, is_valid_pay_date,
)
from income_and_expense.tests.factories import (
    make_account, make_bank, make_expense, make_income, make_loan,
    make_method, make_user,
)


def _today():
    now = timezone.now()
    return datetime.date(now.year, now.month, now.day)


class IsValidPayDateSerializerTests(TestCase):
    def test_boundaries(self):
        self.assertTrue(is_valid_pay_date(_today()))
        self.assertTrue(is_valid_pay_date(_today() - relativedelta(months=1)))
        self.assertFalse(
            is_valid_pay_date(
                _today() - relativedelta(months=1) - datetime.timedelta(days=1)
            )
        )


class MethodSerializerTests(TestCase):
    def test_fields_and_display_name_plain(self):
        m = make_method(name='クレジット')
        data = MethodSerializer(m).data
        self.assertEqual(data['name'], 'クレジット')
        self.assertEqual(data['display_name'], 'クレジット')
        self.assertEqual(set(data.keys()), {'id', 'name', 'display_name'})

    def test_display_name_with_account_suffix(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        m = make_method(name='現金引き落とし', account=acc)
        data = MethodSerializer(m).data
        self.assertIn('UA', data['display_name'])


class IncomeSerializerTests(TestCase):
    def setUp(self):
        self.acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        self.method = make_method(name='クレ', account=self.acc)

    def test_serialize_fields(self):
        inc = make_income(
            name='給料', method=self.method, amount=12345,
            state=StateChoices.DECIDED,
        )
        data = IncomeSerializer(inc).data
        self.assertEqual(data['name'], '給料')
        self.assertEqual(data['amount'], 12345)
        self.assertEqual(data['formed_amount'], '¥12,345')
        self.assertEqual(data['state'], StateChoices.DECIDED)
        self.assertEqual(data['state_label'], '確定')
        self.assertEqual(data['method_name'], 'クレ')
        self.assertEqual(data['account'], {
            'id': self.acc.id, 'user': 'U', 'bank': 'A',
        })

    def test_validate_pay_date_rejects_old(self):
        old = _today() - relativedelta(months=2)
        s = IncomeSerializer(data={
            'name': 'x', 'pay_date': old.isoformat(),
            'method': self.method.pk, 'amount': 10,
            'state': StateChoices.UNDECIDED, 'memo': '',
        })
        self.assertFalse(s.is_valid())
        self.assertIn('pay_date', s.errors)

    def test_validate_pay_date_accepts_today(self):
        s = IncomeSerializer(data={
            'name': 'x', 'pay_date': _today().isoformat(),
            'method': self.method.pk, 'amount': 10,
            'state': StateChoices.UNDECIDED, 'memo': '',
        })
        self.assertTrue(s.is_valid(), s.errors)


class ExpenseSerializerTests(TestCase):
    def setUp(self):
        self.acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        self.method = make_method(name='クレ', account=self.acc)

    def test_serialize_fields(self):
        exp = make_expense(
            name='食費', method=self.method, amount=500,
            state=StateChoices.DONE,
        )
        data = ExpenseSerializer(exp).data
        self.assertEqual(data['formed_amount'], '¥500')
        self.assertEqual(data['state_label'], '完了')
        self.assertEqual(data['method_name'], 'クレ')

    def test_validate_pay_date_rejects_old(self):
        old = _today() - relativedelta(months=2)
        s = ExpenseSerializer(data={
            'name': 'x', 'pay_date': old.isoformat(),
            'method': self.method.pk, 'amount': 10,
            'state': StateChoices.UNDECIDED, 'memo': '',
        })
        self.assertFalse(s.is_valid())


class LoanSerializerTests(TestCase):
    def test_serialize_fields(self):
        loan = make_loan(
            name='住宅', amount_first=100000, amount_from_second=50000,
            state=StateChoices.DECIDED,
        )
        data = LoanSerializer(loan).data
        self.assertEqual(data['name'], '住宅')
        self.assertEqual(data['formed_amount_first'], '¥100,000')
        self.assertEqual(data['formed_amount_from_second'], '¥50,000')
        self.assertEqual(data['state_label'], '確定')
        self.assertEqual(data['account']['user'], loan.method.account.user.name)


class AccountSerializerTests(TestCase):
    def test_serialize_fields(self):
        acc = make_account(
            bank=make_bank('UFJ'), user=make_user('Taro'), balance=12345,
        )
        data = AccountSerializer(acc).data
        self.assertEqual(data['balance'], 12345)
        self.assertEqual(data['formed_balance'], '¥12,345')
        self.assertEqual(data['user_name'], 'Taro')
        self.assertEqual(data['bank_name'], 'UFJ')
