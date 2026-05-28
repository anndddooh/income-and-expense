"""テストデータ生成用のヘルパ関数群。"""
import datetime
import itertools

from dateutil.relativedelta import relativedelta
from django.contrib.auth import get_user_model
from django.utils import timezone

from income_and_expense.models import (
    Account, Bank, DefaultExpense, DefaultExpenseMonth, DefaultIncome,
    DefaultIncomeMonth, Expense, Income, Loan, Method, StateChoices,
    TemplateExpense, User,
)

_bank_counter = itertools.count(1)
_user_counter = itertools.count(1)


def make_bank(name=None):
    if name is None:
        name = 'Bank-{}'.format(next(_bank_counter))
    return Bank.objects.create(name=name)


def make_user(name=None):
    if name is None:
        name = 'User-{}'.format(next(_user_counter))
    return User.objects.create(name=name)


def make_account(bank=None, user=None, balance=100000):
    bank = bank or make_bank()
    user = user or make_user()
    return Account.objects.create(bank=bank, user=user, balance=balance)


def make_method(name='クレジット', account=None):
    account = account or make_account()
    return Method.objects.create(name=name, account=account)


def make_income(name='給料', pay_date=None, method=None, amount=30000,
                state=StateChoices.UNDECIDED, memo=None):
    method = method or make_method()
    pay_date = pay_date or datetime.date.today()
    return Income.objects.create(
        name=name, pay_date=pay_date, method=method,
        amount=amount, state=state, memo=memo,
    )


def make_expense(name='家賃', pay_date=None, method=None, amount=10000,
                 state=StateChoices.UNDECIDED, memo=None):
    method = method or make_method()
    pay_date = pay_date or datetime.date.today()
    return Expense.objects.create(
        name=name, pay_date=pay_date, method=method,
        amount=amount, state=state, memo=memo,
    )


def make_default_income(name='給料', pay_day=25, method=None, amount=300000,
                        state=StateChoices.DECIDED):
    method = method or make_method()
    return DefaultIncome.objects.create(
        name=name, pay_day=pay_day, method=method,
        amount=amount, state=state,
    )


def make_default_expense(name='家賃', pay_day=10, method=None, amount=80000,
                         state=StateChoices.DECIDED):
    method = method or make_method()
    return DefaultExpense.objects.create(
        name=name, pay_day=pay_day, method=method,
        amount=amount, state=state,
    )


def make_default_income_month(month, def_inc):
    return DefaultIncomeMonth.objects.create(month=month, def_inc=def_inc)


def make_default_expense_month(month, def_exp):
    return DefaultExpenseMonth.objects.create(month=month, def_exp=def_exp)


def make_loan(name='住宅ローン', pay_day=15, first_year=None, first_month=1,
              last_year=None, last_month=12, method=None,
              amount_first=100000, amount_from_second=50000,
              state=StateChoices.DECIDED):
    method = method or make_method()
    now = timezone.now()
    first_year = first_year if first_year is not None else now.year
    last_year = last_year if last_year is not None else now.year + 1
    return Loan.objects.create(
        name=name, pay_day=pay_day,
        first_year=first_year, first_month=first_month,
        last_year=last_year, last_month=last_month,
        method=method,
        amount_first=amount_first, amount_from_second=amount_from_second,
        state=state,
    )


def make_template_expense(template_name='日々の食費', name='食費',
                          date_type='today', pay_day=None,
                          limit_day_of_this_month=None, method=None,
                          state=StateChoices.UNDECIDED):
    method = method or make_method()
    return TemplateExpense.objects.create(
        template_name=template_name, name=name,
        date_type=date_type, pay_day=pay_day,
        limit_day_of_this_month=limit_day_of_this_month,
        method=method, state=state,
    )


def make_auth_user(username='tester', password='pass12345'):
    UserModel = get_user_model()
    return UserModel.objects.create_user(username=username, password=password)


def current_year_month():
    now = timezone.now()
    return now.year, now.month


def shift_month(year, month, delta):
    """(year, month) を delta か月ずらした (year, month) を返す。"""
    d = datetime.date(year, month, 1) + relativedelta(months=delta)
    return d.year, d.month
