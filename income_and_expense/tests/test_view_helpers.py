"""views.py 内のヘルパー関数のテスト。"""
import datetime

from dateutil.relativedelta import relativedelta
from django.test import TestCase
from django.utils import timezone

from income_and_expense import views
from income_and_expense.models import Expense, Income, StateChoices
from income_and_expense.tests.factories import (
    current_year_month, make_default_expense, make_default_expense_month,
    make_default_income, make_default_income_month, make_expense,
    make_income, make_loan, make_method, shift_month,
)


class CanAddDefaultInexTests(TestCase):
    def test_current_month_allowed(self):
        y, m = current_year_month()
        self.assertTrue(views.can_add_default_inex(y, m))

    def test_past_month_not_allowed(self):
        y, m = shift_month(*current_year_month(), delta=-1)
        self.assertFalse(views.can_add_default_inex(y, m))

    def test_future_month_allowed(self):
        y, m = shift_month(*current_year_month(), delta=1)
        self.assertTrue(views.can_add_default_inex(y, m))


class CanUpdateOrDeleteInexTests(TestCase):
    def test_current_month_allowed(self):
        y, m = current_year_month()
        self.assertTrue(views.can_update_or_delete_inex(y, m))

    def test_last_month_allowed(self):
        y, m = shift_month(*current_year_month(), delta=-1)
        self.assertTrue(views.can_update_or_delete_inex(y, m))

    def test_two_months_ago_not_allowed(self):
        y, m = shift_month(*current_year_month(), delta=-2)
        self.assertFalse(views.can_update_or_delete_inex(y, m))

    def test_future_allowed(self):
        y, m = shift_month(*current_year_month(), delta=5)
        self.assertTrue(views.can_update_or_delete_inex(y, m))


class AddIncsFromDefaultTests(TestCase):
    def test_adds_new_income(self):
        now = timezone.now()
        year, month = now.year, now.month
        method = make_method()
        di = make_default_income(
            name='給料', pay_day=15, method=method, amount=1000,
        )
        make_default_income_month(month, di)

        added = views.add_incs_from_default(year, month)
        self.assertEqual(added, 1)
        self.assertTrue(Income.objects.filter(
            name='給料', pay_date=datetime.date(year, month, 15)
        ).exists())

    def test_skips_if_same_name_exists(self):
        now = timezone.now()
        year, month = now.year, now.month
        method = make_method()
        di = make_default_income(
            name='給料', pay_day=15, method=method, amount=1000,
        )
        make_default_income_month(month, di)
        make_income(
            name='給料', method=method,
            pay_date=datetime.date(year, month, 1),
            amount=999,
        )

        added = views.add_incs_from_default(year, month)
        self.assertEqual(added, 0)
        self.assertEqual(Income.objects.filter(name='給料').count(), 1)

    def test_no_default_for_month(self):
        now = timezone.now()
        year, month = now.year, now.month
        # 別月にしか登録されていない
        other_month = (month % 12) + 1
        di = make_default_income(name='x', method=make_method())
        make_default_income_month(other_month, di)

        self.assertEqual(views.add_incs_from_default(year, month), 0)


class AddExpsFromDefaultAndLoanTests(TestCase):
    def test_adds_default_expense(self):
        now = timezone.now()
        year, month = now.year, now.month
        method = make_method()
        de = make_default_expense(
            name='家賃', pay_day=10, method=method, amount=80000,
        )
        make_default_expense_month(month, de)

        added = views.add_exps_from_default_and_loan(year, month)
        self.assertEqual(added, 1)
        self.assertTrue(Expense.objects.filter(name='家賃').exists())

    def test_skips_default_expense_if_name_exists(self):
        now = timezone.now()
        year, month = now.year, now.month
        method = make_method()
        de = make_default_expense(
            name='家賃', pay_day=10, method=method, amount=80000,
        )
        make_default_expense_month(month, de)
        make_expense(
            name='家賃', method=method,
            pay_date=datetime.date(year, month, 1),
        )

        added = views.add_exps_from_default_and_loan(year, month)
        self.assertEqual(added, 0)

    def test_loan_first_month_uses_first_amount(self):
        now = timezone.now()
        year, month = now.year, now.month
        method = make_method()
        # 先月〜来年まで実行中で今月が first_year/first_month に一致
        make_loan(
            name='住宅', pay_day=10, method=method,
            first_year=year, first_month=month,
            last_year=year + 1, last_month=month,
            amount_first=99999, amount_from_second=1000,
        )

        added = views.add_exps_from_default_and_loan(year, month)
        self.assertEqual(added, 1)
        exp = Expense.objects.get(name='住宅')
        self.assertEqual(exp.amount, 99999)

    def test_loan_uses_from_second_amount(self):
        now = timezone.now()
        year, month = now.year, now.month
        prev_year, prev_month = shift_month(year, month, -1)
        method = make_method()
        make_loan(
            name='住宅', pay_day=10, method=method,
            first_year=prev_year, first_month=prev_month,
            last_year=year + 1, last_month=month,
            amount_first=99999, amount_from_second=1000,
        )

        added = views.add_exps_from_default_and_loan(year, month)
        self.assertEqual(added, 1)
        exp = Expense.objects.get(name='住宅')
        self.assertEqual(exp.amount, 1000)

    def test_loan_out_of_range_not_added(self):
        now = timezone.now()
        year, month = now.year, now.month
        # 過去に終了済みのローン
        past_year = year - 5
        make_loan(
            name='終了済', pay_day=10,
            first_year=past_year, first_month=1,
            last_year=past_year, last_month=12,
            amount_first=1, amount_from_second=1,
            method=make_method(),
        )

        added = views.add_exps_from_default_and_loan(year, month)
        self.assertEqual(added, 0)

    def test_loan_skipped_if_name_exists(self):
        now = timezone.now()
        year, month = now.year, now.month
        method = make_method()
        make_loan(
            name='住宅', pay_day=10, method=method,
            first_year=year, first_month=month,
            last_year=year + 1, last_month=month,
            amount_first=99999, amount_from_second=1000,
        )
        make_expense(
            name='住宅', method=method,
            pay_date=datetime.date(year, month, 1),
        )

        added = views.add_exps_from_default_and_loan(year, month)
        self.assertEqual(added, 0)


class GetBalanceTests(TestCase):
    def test_empty_returns_zero(self):
        self.assertEqual(views.get_balance(2025, 6), 0)
        self.assertEqual(views.get_balance_done(2025, 6), 0)

    def test_get_balance_sums_all(self):
        method = make_method()
        make_income(
            name='i1', method=method, amount=1000,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 1, 15),
        )
        make_expense(
            name='e1', method=method, amount=300,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 1, 20),
        )
        self.assertEqual(views.get_balance(2025, 1), 700)

    def test_get_balance_done_only_sums_done(self):
        method = make_method()
        make_income(
            name='i1', method=method, amount=1000,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 1, 15),
        )
        make_income(
            name='i2', method=method, amount=500,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 1, 15),
        )
        make_expense(
            name='e1', method=method, amount=200,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 1, 20),
        )
        self.assertEqual(views.get_balance_done(2025, 1), 300)

    def test_future_months_excluded(self):
        method = make_method()
        make_income(
            name='i', method=method, amount=999,
            state=StateChoices.DONE,
            pay_date=datetime.date(2099, 5, 1),
        )
        self.assertEqual(views.get_balance_done(2025, 1), 0)
