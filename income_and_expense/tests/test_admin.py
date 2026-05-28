"""Admin 層のテスト。カスタム表示メソッドとアクションを動かす。"""
import datetime

from django.contrib.admin.sites import site
from django.test import RequestFactory, TestCase

from income_and_expense import admin as admin_module
from income_and_expense.models import (
    Account, DefaultExpense, DefaultExpenseMonth, DefaultIncome,
    DefaultIncomeMonth, Expense, Income, Loan, Method, StateChoices,
    TemplateExpense,
)
from income_and_expense.tests.factories import (
    make_account, make_bank, make_default_expense,
    make_default_expense_month, make_default_income,
    make_default_income_month, make_expense, make_income, make_loan,
    make_method, make_template_expense, make_user,
)


class AdminActionsTests(TestCase):
    def test_set_undecided(self):
        method = make_method()
        make_expense(
            name='x', method=method, amount=1,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        make_expense(
            name='y', method=method, amount=2,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 4, 1),
        )
        admin_module.set_undecided(None, None, Expense.objects.all())
        self.assertEqual(
            Expense.objects.filter(state=StateChoices.UNDECIDED).count(), 2
        )

    def test_set_decided(self):
        method = make_method()
        make_income(
            name='x', method=method, amount=1,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        admin_module.set_decided(None, None, Income.objects.all())
        self.assertEqual(
            Income.objects.filter(state=StateChoices.DECIDED).count(), 1
        )

    def test_set_done(self):
        method = make_method()
        make_expense(
            name='x', method=method, amount=1,
            pay_date=datetime.date(2025, 4, 1),
        )
        admin_module.set_done(None, None, Expense.objects.all())
        self.assertEqual(
            Expense.objects.filter(state=StateChoices.DONE).count(), 1
        )


class AdminDisplayMethodTests(TestCase):
    """Admin の *_custom 表示メソッドが登録オブジェクトを返すこと。"""

    def test_account_admin_displays(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        ma = site._registry[Account]
        self.assertEqual(ma.bank_custom(acc), acc.bank)
        self.assertEqual(ma.user_custom(acc), acc.user)

    def test_method_admin_displays(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        m = make_method(name='クレ', account=acc)
        ma = site._registry[Method]
        self.assertEqual(ma.name_custom(m), 'クレ')
        self.assertEqual(ma.account_custom(m), acc)

    def test_expense_admin_displays(self):
        method = make_method()
        exp = make_expense(
            name='食費', method=method,
            pay_date=datetime.date(2025, 4, 1),
        )
        ma = site._registry[Expense]
        self.assertEqual(ma.name_custom(exp), '食費')
        self.assertEqual(ma.method_custom(exp), method)
        self.assertEqual(ma.pay_date_custom(exp), datetime.date(2025, 4, 1))

    def test_income_admin_displays(self):
        method = make_method()
        inc = make_income(
            name='給与', method=method,
            pay_date=datetime.date(2025, 4, 1),
        )
        ma = site._registry[Income]
        self.assertEqual(ma.name_custom(inc), '給与')
        self.assertEqual(ma.method_custom(inc), method)
        self.assertEqual(ma.pay_date_custom(inc), datetime.date(2025, 4, 1))

    def test_default_expense_admin_displays(self):
        de = make_default_expense(name='家賃', pay_day=9)
        ma = site._registry[DefaultExpense]
        self.assertEqual(ma.name_custom(de), '家賃')
        self.assertEqual(ma.method_custom(de), de.method)
        self.assertEqual(ma.pay_day_custom(de), 9)

    def test_default_income_admin_displays(self):
        di = make_default_income(name='給料', pay_day=20)
        ma = site._registry[DefaultIncome]
        self.assertEqual(ma.name_custom(di), '給料')
        self.assertEqual(ma.method_custom(di), di.method)
        self.assertEqual(ma.pay_day_custom(di), 20)

    def test_default_expense_month_admin_display(self):
        de = make_default_expense(name='家賃')
        dem = make_default_expense_month(4, de)
        ma = site._registry[DefaultExpenseMonth]
        self.assertEqual(ma.month_custom(dem), 4)

    def test_default_income_month_admin_display(self):
        di = make_default_income(name='給料')
        dim = make_default_income_month(5, di)
        ma = site._registry[DefaultIncomeMonth]
        self.assertEqual(ma.month_custom(dim), 5)

    def test_template_expense_admin_displays(self):
        method = make_method()
        t = make_template_expense(
            template_name='T', name='食費',
            date_type='today',
            pay_day=3, limit_day_of_this_month=10,
            method=method,
        )
        ma = site._registry[TemplateExpense]
        self.assertEqual(ma.template_name_custom(t), 'T')
        self.assertEqual(ma.name_custom(t), '食費')
        self.assertEqual(ma.method_custom(t), method)
        self.assertEqual(ma.date_type_custom(t), 'today')
        self.assertEqual(ma.pay_day_custom(t), 3)
        self.assertEqual(ma.limit_day_of_this_month_custom(t), 10)

    def test_loan_admin_displays(self):
        loan = make_loan(
            name='住宅', pay_day=10,
            first_year=2025, first_month=1,
            last_year=2030, last_month=12,
        )
        ma = site._registry[Loan]
        self.assertEqual(ma.name_custom(loan), '住宅')
        self.assertEqual(ma.method_custom(loan), loan.method)
        self.assertEqual(ma.pay_day_custom(loan), 10)
        self.assertEqual(ma.first_year_custom(loan), 2025)
        self.assertEqual(ma.first_month_custom(loan), 1)
        self.assertEqual(ma.last_year_custom(loan), 2030)
        self.assertEqual(ma.last_month_custom(loan), 12)
