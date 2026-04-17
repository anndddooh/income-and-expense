"""フォーム層のテスト。"""
import datetime

from dateutil.relativedelta import relativedelta
from django.test import TestCase
from django.utils import timezone

from income_and_expense.forms import (
    BalanceForm, ExpenseForm, IncomeForm, LoanForm, LoginForm,
    is_valid_pay_date,
)
from income_and_expense.models import StateChoices
from income_and_expense.tests.factories import (
    make_account, make_bank, make_method, make_user,
)


def _today():
    now = timezone.now()
    return datetime.date(now.year, now.month, now.day)


class IsValidPayDateTests(TestCase):
    def test_today_is_valid(self):
        self.assertTrue(is_valid_pay_date(_today()))

    def test_exactly_one_month_ago_is_valid(self):
        self.assertTrue(is_valid_pay_date(_today() - relativedelta(months=1)))

    def test_more_than_one_month_ago_is_invalid(self):
        old = _today() - relativedelta(months=1) - datetime.timedelta(days=1)
        self.assertFalse(is_valid_pay_date(old))

    def test_future_is_valid(self):
        self.assertTrue(is_valid_pay_date(_today() + datetime.timedelta(days=365)))


class LoginFormTests(TestCase):
    def test_widgets_have_bootstrap_class(self):
        f = LoginForm()
        for field in f.fields.values():
            self.assertEqual(field.widget.attrs.get('class'), 'form-control')
            self.assertEqual(field.widget.attrs.get('placeholder'), field.label)


class ExpenseIncomeFormTests(TestCase):
    def setUp(self):
        self.method = make_method(
            account=make_account(
                bank=make_bank('A'), user=make_user('U'), balance=0,
            )
        )

    def _data(self, pay_date):
        return {
            'name': 'test',
            'pay_date': pay_date.strftime('%Y-%m-%d'),
            'method': self.method.pk,
            'amount': 1000,
            'state': StateChoices.UNDECIDED,
            'memo': '',
        }

    def test_expense_form_valid(self):
        form = ExpenseForm(data=self._data(_today()))
        self.assertTrue(form.is_valid(), form.errors)

    def test_expense_form_rejects_old_date(self):
        old = _today() - relativedelta(months=2)
        form = ExpenseForm(data=self._data(old))
        self.assertFalse(form.is_valid())
        self.assertIn('pay_date', form.errors)

    def test_income_form_valid(self):
        form = IncomeForm(data=self._data(_today()))
        self.assertTrue(form.is_valid(), form.errors)

    def test_income_form_rejects_old_date(self):
        old = _today() - relativedelta(months=2)
        form = IncomeForm(data=self._data(old))
        self.assertFalse(form.is_valid())
        self.assertIn('pay_date', form.errors)

    def test_expense_form_missing_required(self):
        form = ExpenseForm(data={})
        self.assertFalse(form.is_valid())
        for key in ['name', 'pay_date', 'method', 'amount']:
            self.assertIn(key, form.errors)


class BalanceFormTests(TestCase):
    def test_valid(self):
        bank = make_bank('B')
        user = make_user('UU')
        form = BalanceForm(data={
            'bank': bank.pk, 'user': user.pk, 'balance': 1000,
        })
        self.assertTrue(form.is_valid(), form.errors)


class LoanFormTests(TestCase):
    def setUp(self):
        self.method = make_method()

    def test_valid(self):
        form = LoanForm(data={
            'name': '住宅',
            'pay_day': 15,
            'first_year': 2025, 'first_month': 1,
            'last_year': 2030, 'last_month': 12,
            'method': self.method.pk,
            'amount_first': 100000,
            'amount_from_second': 50000,
            'state': StateChoices.DECIDED,
        })
        self.assertTrue(form.is_valid(), form.errors)

    def test_invalid_pay_day(self):
        form = LoanForm(data={
            'name': '住宅',
            'pay_day': 30,
            'first_year': 2025, 'first_month': 1,
            'last_year': 2030, 'last_month': 12,
            'method': self.method.pk,
            'amount_first': 100000,
            'amount_from_second': 50000,
            'state': StateChoices.DECIDED,
        })
        self.assertFalse(form.is_valid())
        self.assertIn('pay_day', form.errors)
