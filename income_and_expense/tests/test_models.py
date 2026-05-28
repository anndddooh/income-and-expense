"""モデル層のユニットテスト。"""
import datetime

from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.test import TestCase

from income_and_expense.models import (
    Account, Bank, DefaultExpense, DefaultExpenseMonth, DefaultIncome,
    DefaultIncomeMonth, Expense, Income, Loan, Method, StateChoices,
    TemplateExpense, User,
)
from income_and_expense.tests.factories import (
    make_account, make_bank, make_default_expense, make_default_expense_month,
    make_default_income, make_default_income_month, make_expense,
    make_income, make_loan, make_method, make_template_expense, make_user,
)


class BankModelTests(TestCase):
    def test_str(self):
        self.assertEqual(str(make_bank('A銀行')), 'A銀行')

    def test_name_is_unique(self):
        make_bank('同名')
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                Bank.objects.create(name='同名')


class UserModelTests(TestCase):
    def test_str(self):
        self.assertEqual(str(make_user('Hanako')), 'Hanako')

    def test_name_is_unique(self):
        make_user('Same')
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                User.objects.create(name='Same')


class AccountModelTests(TestCase):
    def test_str_and_formed_balance(self):
        acc = make_account(
            bank=make_bank('UFJ'), user=make_user('Taro'), balance=12345,
        )
        self.assertEqual(str(acc), 'TaroUFJ')
        self.assertEqual(acc.formed_balance(), '¥12,345')

    def test_unique_together_bank_user(self):
        bank = make_bank('A')
        user = make_user('U')
        make_account(bank=bank, user=user)
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                Account.objects.create(bank=bank, user=user, balance=1)

    def test_balance_positive_field_validator(self):
        acc = make_account(balance=0)
        self.assertEqual(acc.balance, 0)
        acc.balance = 1
        # PositiveIntegerField は 0 以上を受け入れる
        acc.full_clean()


class MethodModelTests(TestCase):
    def test_plain_name_returns_name(self):
        m = make_method(name='クレジット')
        self.assertEqual(str(m), 'クレジット')

    def test_special_name_includes_account(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        m = make_method(name='現金出金', account=acc)
        self.assertIn('UA', str(m))
        self.assertIn('現金出金', str(m))

    def test_all_patterns_include_account(self):
        acc = make_account(
            bank=make_bank('B'), user=make_user('V'), balance=0,
        )
        for pat in ['振込', '預入', '現金', '引き落とし']:
            m = Method.objects.create(name=pat, account=acc)
            self.assertIn('VB', str(m))


class StateChoicesTests(TestCase):
    def test_labels(self):
        self.assertEqual(StateChoices.UNDECIDED.label, '未定')
        self.assertEqual(StateChoices.DECIDED.label, '確定')
        self.assertEqual(StateChoices.DONE.label, '完了')


class ExpenseModelTests(TestCase):
    def test_helpers(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        m = make_method(account=acc)
        exp = make_expense(
            name='食費', method=m, amount=1234,
            state=StateChoices.DONE,
        )
        self.assertEqual(str(exp), '食費')
        self.assertEqual(exp.formed_amount(), '¥1,234')
        self.assertEqual(exp.account_info(), acc)
        self.assertEqual(exp.state_info(), '完了')

    def test_default_state_is_undecided(self):
        exp = Expense.objects.create(
            name='x', pay_date=datetime.date.today(),
            method=make_method(), amount=100,
        )
        self.assertEqual(exp.state, StateChoices.UNDECIDED)


class IncomeModelTests(TestCase):
    def test_helpers(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        m = make_method(account=acc)
        inc = make_income(
            name='給料', method=m, amount=200000,
            state=StateChoices.DECIDED,
        )
        self.assertEqual(str(inc), '給料')
        self.assertEqual(inc.formed_amount(), '¥200,000')
        self.assertEqual(inc.account_info(), acc)
        self.assertEqual(inc.state_info(), '確定')


class DefaultExpenseModelTests(TestCase):
    def test_helpers_and_str(self):
        d = make_default_expense(name='家賃', amount=80000)
        self.assertEqual(str(d), '家賃')
        self.assertEqual(d.formed_amount(), '¥80,000')
        self.assertEqual(d.state_info(), '確定')
        self.assertEqual(d.account_info(), d.method.account)

    def test_pay_day_validator_out_of_range(self):
        d = make_default_expense()
        d.pay_day = 0
        with self.assertRaises(ValidationError):
            d.full_clean()
        d.pay_day = 29
        with self.assertRaises(ValidationError):
            d.full_clean()

    def test_name_unique(self):
        make_default_expense(name='同名')
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                DefaultExpense.objects.create(
                    name='同名', pay_day=1, method=make_method(),
                    amount=1, state=StateChoices.UNDECIDED,
                )


class DefaultIncomeModelTests(TestCase):
    def test_helpers_and_str(self):
        d = make_default_income(name='給料', amount=300000)
        self.assertEqual(str(d), '給料')
        self.assertEqual(d.formed_amount(), '¥300,000')
        self.assertEqual(d.state_info(), '確定')
        self.assertEqual(d.account_info(), d.method.account)

    def test_pay_day_validator(self):
        d = make_default_income()
        d.pay_day = 30
        with self.assertRaises(ValidationError):
            d.full_clean()


class DefaultExpenseMonthTests(TestCase):
    def test_str_and_unique_together(self):
        d = make_default_expense(name='家賃')
        m = make_default_expense_month(4, d)
        self.assertEqual(str(m), '家賃(4月)')
        self.assertEqual(m.def_exp_name(), d)
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                DefaultExpenseMonth.objects.create(month=4, def_exp=d)

    def test_month_validator(self):
        d = make_default_expense()
        m = DefaultExpenseMonth(month=13, def_exp=d)
        with self.assertRaises(ValidationError):
            m.full_clean()


class DefaultIncomeMonthTests(TestCase):
    def test_str_and_unique_together(self):
        d = make_default_income(name='給料')
        m = make_default_income_month(5, d)
        self.assertEqual(str(m), '給料(5月)')
        self.assertEqual(m.def_inc_name(), d)
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                DefaultIncomeMonth.objects.create(month=5, def_inc=d)

    def test_month_validator_lower_bound(self):
        d = make_default_income()
        m = DefaultIncomeMonth(month=0, def_inc=d)
        with self.assertRaises(ValidationError):
            m.full_clean()


class TemplateExpenseTests(TestCase):
    def test_str_and_helpers(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        m = make_method(account=acc)
        t = make_template_expense(
            template_name='食費テンプレ', name='食費',
            date_type='today', method=m,
            state=StateChoices.DECIDED,
        )
        self.assertEqual(str(t), '食費テンプレ')
        self.assertEqual(t.account_info(), acc)
        self.assertEqual(t.state_info(), '確定')

    def test_template_name_unique(self):
        make_template_expense(template_name='X')
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                TemplateExpense.objects.create(
                    template_name='X', name='Y',
                    date_type='today', method=make_method(),
                )


class LoanModelTests(TestCase):
    def test_helpers_and_str(self):
        loan = make_loan(
            name='住宅', amount_first=150000, amount_from_second=80000,
            state=StateChoices.DECIDED,
        )
        self.assertEqual(str(loan), '住宅')
        self.assertEqual(loan.formed_amount_first(), '¥150,000')
        self.assertEqual(loan.formed_amount_from_second(), '¥80,000')
        self.assertEqual(loan.state_info(), '確定')
        self.assertEqual(loan.account_info(), loan.method.account)

    def test_last_month_validator(self):
        loan = make_loan()
        loan.last_month = 13
        with self.assertRaises(ValidationError):
            loan.full_clean()

    def test_pay_day_validator(self):
        loan = make_loan()
        loan.pay_day = 29
        with self.assertRaises(ValidationError):
            loan.full_clean()

    def test_name_is_unique(self):
        make_loan(name='同名')
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                Loan.objects.create(
                    name='同名', pay_day=1,
                    first_year=2025, first_month=1,
                    last_year=2025, last_month=12,
                    method=make_method(),
                    amount_first=1, amount_from_second=1,
                    state=StateChoices.UNDECIDED,
                )
