"""DRF API エンドポイントのテスト。"""
import datetime

from dateutil.relativedelta import relativedelta
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from income_and_expense import api_views
from income_and_expense.models import (
    Account, Bank, DefaultExpense, DefaultExpenseMonth, DefaultIncome,
    DefaultIncomeMonth, Expense, Income, Loan, StateChoices, User,
)
from income_and_expense.tests.factories import (
    current_year_month, make_account, make_auth_user, make_bank,
    make_default_expense, make_default_expense_month, make_default_income,
    make_default_income_month, make_expense, make_income, make_loan,
    make_method, make_template_expense, make_user, shift_month,
)


def _today():
    now = timezone.now()
    return datetime.date(now.year, now.month, now.day)


class APITestCaseBase(TestCase):
    def setUp(self):
        self.client = APIClient()
        # マージで DRF が IsAuthenticated + JWT デフォルトになったため、
        # 既存テストおよび新規テストともにダミーユーザで認証済みにする。
        self.auth_user = make_auth_user()
        self.client.force_authenticate(user=self.auth_user)


class InternalHelperTests(TestCase):
    def test_month_range(self):
        first, last = api_views._month_range(2025, 2)
        self.assertEqual(first, datetime.date(2025, 2, 1))
        self.assertEqual(last, datetime.date(2025, 2, 28))
        # 31日月
        _, last = api_views._month_range(2024, 1)
        self.assertEqual(last, datetime.date(2024, 1, 31))

    def test_parse_year_month_success(self):
        factory_req = type('R', (), {'query_params': {'year': '2025', 'month': '4'}})()
        y, m = api_views._parse_year_month(factory_req)
        self.assertEqual((y, m), (2025, 4))

    def test_parse_year_month_missing(self):
        from rest_framework.exceptions import ValidationError
        factory_req = type('R', (), {'query_params': {}})()
        with self.assertRaises(ValidationError):
            api_views._parse_year_month(factory_req)

    def test_parse_year_month_non_integer(self):
        from rest_framework.exceptions import ValidationError
        factory_req = type('R', (), {'query_params': {'year': 'x', 'month': '4'}})()
        with self.assertRaises(ValidationError):
            api_views._parse_year_month(factory_req)

    def test_can_delete_boundaries(self):
        # マージで `_can_update_or_delete` は `_can_delete` に改名され、
        # update 側のガードは外れた(削除のみ古い月をブロック)。
        y, m = shift_month(*current_year_month(), delta=-1)
        self.assertTrue(api_views._can_delete(y, m))
        y, m = shift_month(*current_year_month(), delta=-2)
        self.assertFalse(api_views._can_delete(y, m))

    def test_can_add_default_boundaries(self):
        y, m = current_year_month()
        self.assertTrue(api_views._can_add_default(y, m))
        y, m = shift_month(*current_year_month(), delta=-1)
        self.assertFalse(api_views._can_add_default(y, m))

    def test_get_balance_done(self):
        method = make_method()
        make_income(
            name='i', method=method, amount=1000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 2, 1),
        )
        make_expense(
            name='e', method=method, amount=400,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 2, 1),
        )
        make_income(
            name='i2', method=method, amount=999,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 2, 1),
        )
        self.assertEqual(api_views._get_balance_done(2025, 2), 600)

    def test_get_balance_all_states(self):
        # 新規追加された `_get_balance` は state を問わず合算する。
        method = make_method()
        make_income(
            name='i', method=method, amount=1000,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 2, 1),
        )
        make_expense(
            name='e', method=method, amount=400,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 2, 1),
        )
        # 翌月は集計対象外
        make_income(
            name='next', method=method, amount=9999,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 3, 1),
        )
        self.assertEqual(api_views._get_balance(2025, 2), 600)


class IncomeViewSetTests(APITestCaseBase):
    def setUp(self):
        super().setUp()
        self.method = make_method()

    def test_list_requires_year_month(self):
        res = self.client.get('/api/incomes/')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_filters_by_month(self):
        make_income(
            name='in-range', method=self.method, amount=10,
            pay_date=datetime.date(2025, 4, 15),
        )
        make_income(
            name='out', method=self.method, amount=20,
            pay_date=datetime.date(2025, 5, 1),
        )
        res = self.client.get('/api/incomes/?year=2025&month=4')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # マージで list レスポンスは `{results, prev_balance}` 形式に変化。
        names = [item['name'] for item in res.data['results']]
        self.assertEqual(names, ['in-range'])
        self.assertIn('prev_balance', res.data)

    def test_list_includes_prev_balance(self):
        # 2025/02 を要求すると `prev_balance` は 2025/01 末までの累計収支。
        make_income(
            name='salary', method=self.method, amount=1000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 1, 15),
        )
        make_expense(
            name='rent', method=self.method, amount=200,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 1, 20),
        )
        # 当月(2/x)の収入は prev_balance には含まれない。
        make_income(
            name='this-month', method=self.method, amount=99999,
            pay_date=datetime.date(2025, 2, 1),
        )
        res = self.client.get('/api/incomes/?year=2025&month=2')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['prev_balance'], 800)

    def test_retrieve_does_not_require_year_month(self):
        inc = make_income(
            name='x', method=self.method, amount=1,
            pay_date=_today(),
        )
        res = self.client.get(f'/api/incomes/{inc.pk}/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['id'], inc.pk)

    def test_create(self):
        res = self.client.post('/api/incomes/', data={
            'name': 'new',
            'pay_date': _today().isoformat(),
            'method': self.method.pk,
            'amount': 100,
            'state': StateChoices.UNDECIDED,
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        self.assertTrue(Income.objects.filter(name='new').exists())

    def test_update_allowed_for_old(self):
        # マージで update 側の月境界ガードが撤廃された。
        # 古い月でも pay_date を変えない更新は通る (削除のみブロック)。
        old = _today() - relativedelta(months=3)
        inc = make_income(name='x', method=self.method, amount=1, pay_date=old)
        res = self.client.patch(
            f'/api/incomes/{inc.pk}/', data={'amount': 2}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        inc.refresh_from_db()
        self.assertEqual(inc.amount, 2)

    def test_destroy_rejected_for_old(self):
        old = _today() - relativedelta(months=3)
        inc = make_income(name='x', method=self.method, amount=1, pay_date=old)
        res = self.client.delete(f'/api/incomes/{inc.pk}/')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(Income.objects.filter(pk=inc.pk).exists())

    def test_destroy_recent_ok(self):
        inc = make_income(name='x', method=self.method, amount=1, pay_date=_today())
        res = self.client.delete(f'/api/incomes/{inc.pk}/')
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_full_update_recent_ok(self):
        inc = make_income(name='x', method=self.method, amount=1, pay_date=_today())
        res = self.client.put(f'/api/incomes/{inc.pk}/', data={
            'name': 'y',
            'pay_date': _today().isoformat(),
            'method': self.method.pk,
            'amount': 2,
            'state': StateChoices.UNDECIDED,
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        inc.refresh_from_db()
        self.assertEqual(inc.name, 'y')

    def test_partial_update_recent_ok(self):
        inc = make_income(name='x', method=self.method, amount=1, pay_date=_today())
        res = self.client.patch(
            f'/api/incomes/{inc.pk}/', data={'amount': 5}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        inc.refresh_from_db()
        self.assertEqual(inc.amount, 5)

    def test_full_update_old_allowed(self):
        # update ガード撤廃 + validate_pay_date は同一日なら免除されるので、
        # 古い月のレコードでも PUT でフル更新できる。
        old = _today() - relativedelta(months=3)
        inc = make_income(name='x', method=self.method, amount=1, pay_date=old)
        res = self.client.put(f'/api/incomes/{inc.pk}/', data={
            'name': 'y',
            'pay_date': old.isoformat(),
            'method': self.method.pk,
            'amount': 2,
            'state': StateChoices.UNDECIDED,
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        inc.refresh_from_db()
        self.assertEqual(inc.name, 'y')

    def test_add_defaults_rejected_for_past(self):
        y, m = shift_month(*current_year_month(), delta=-1)
        res = self.client.post(
            f'/api/incomes/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_add_defaults_creates_incomes(self):
        y, m = current_year_month()
        di = make_default_income(name='給料', pay_day=5, method=self.method)
        make_default_income_month(m, di)

        res = self.client.post(
            f'/api/incomes/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data, {'added': 1})
        self.assertTrue(Income.objects.filter(name='給料').exists())

    def test_add_defaults_skips_existing(self):
        y, m = current_year_month()
        di = make_default_income(name='給料', pay_day=5, method=self.method)
        make_default_income_month(m, di)
        make_income(
            name='給料', method=self.method,
            pay_date=datetime.date(y, m, 1),
        )

        res = self.client.post(
            f'/api/incomes/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.data, {'added': 0})


class ExpenseViewSetTests(APITestCaseBase):
    def setUp(self):
        super().setUp()
        self.method = make_method()

    def test_list_filters(self):
        make_expense(
            name='a', method=self.method, amount=10,
            pay_date=datetime.date(2025, 3, 1),
        )
        res = self.client.get('/api/expenses/?year=2025&month=3')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # マージで list レスポンスは `{results, balance}` 形式に変化。
        self.assertEqual(len(res.data['results']), 1)
        self.assertIn('balance', res.data)

    def test_list_includes_balance(self):
        # 2025/04 を要求すると `balance` は 2025/04 末までの累計収支。
        make_income(
            name='salary', method=self.method, amount=1000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 4, 1),
        )
        make_expense(
            name='in-this-month', method=self.method, amount=300,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 10),
        )
        # 翌月分は含まれない
        make_expense(
            name='next-month', method=self.method, amount=9999,
            pay_date=datetime.date(2025, 5, 1),
        )
        res = self.client.get('/api/expenses/?year=2025&month=4')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['balance'], 700)

    def test_add_defaults_with_loan_first_month(self):
        y, m = current_year_month()
        # DefaultExpense 側
        de = make_default_expense(name='家賃', pay_day=10, method=self.method)
        make_default_expense_month(m, de)
        # Loan 側 (今月が初回)
        make_loan(
            name='住宅', pay_day=15, method=self.method,
            first_year=y, first_month=m,
            last_year=y + 1, last_month=m,
            amount_first=99999, amount_from_second=1000,
        )

        res = self.client.post(
            f'/api/expenses/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data, {'added': 2})
        self.assertEqual(
            Expense.objects.get(name='住宅').amount, 99999
        )

    def test_add_defaults_loan_second_month(self):
        y, m = current_year_month()
        prev_y, prev_m = shift_month(y, m, -1)
        make_loan(
            name='住宅', pay_day=15, method=self.method,
            first_year=prev_y, first_month=prev_m,
            last_year=y + 1, last_month=m,
            amount_first=99999, amount_from_second=1000,
        )

        res = self.client.post(
            f'/api/expenses/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.data, {'added': 1})
        self.assertEqual(Expense.objects.get(name='住宅').amount, 1000)

    def test_add_defaults_rejects_past(self):
        y, m = shift_month(*current_year_month(), delta=-1)
        res = self.client.post(
            f'/api/expenses/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_add_defaults_skips_existing_default(self):
        y, m = current_year_month()
        de = make_default_expense(name='家賃', pay_day=10, method=self.method)
        make_default_expense_month(m, de)
        make_expense(
            name='家賃', method=self.method,
            pay_date=datetime.date(y, m, 5),
        )
        res = self.client.post(
            f'/api/expenses/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.data, {'added': 0})

    def test_add_defaults_skips_existing_loan(self):
        y, m = current_year_month()
        make_loan(
            name='住宅', pay_day=15, method=self.method,
            first_year=y, first_month=m,
            last_year=y + 1, last_month=m,
            amount_first=1, amount_from_second=1,
        )
        make_expense(
            name='住宅', method=self.method,
            pay_date=datetime.date(y, m, 1),
        )
        res = self.client.post(
            f'/api/expenses/add_defaults/?year={y}&month={m}'
        )
        self.assertEqual(res.data, {'added': 0})

    def test_update_allowed_for_old(self):
        # update ガード撤廃により、古い月でも patch は通る。
        old = _today() - relativedelta(months=3)
        exp = make_expense(
            name='x', method=self.method, amount=1, pay_date=old,
        )
        res = self.client.patch(
            f'/api/expenses/{exp.pk}/', data={'amount': 2}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        exp.refresh_from_db()
        self.assertEqual(exp.amount, 2)


class MethodListAPIViewTests(APITestCaseBase):
    def test_list(self):
        make_method(name='クレ')
        make_method(name='現金')
        res = self.client.get('/api/methods/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 2)
        self.assertIn('display_name', res.data[0])


class LoanViewSetTests(APITestCaseBase):
    def test_list_and_create(self):
        method = make_method()
        res = self.client.post('/api/loans/', data={
            'name': '住宅',
            'pay_day': 10,
            'first_year': 2025, 'first_month': 1,
            'last_year': 2030, 'last_month': 12,
            'method': method.pk,
            'amount_first': 100000,
            'amount_from_second': 50000,
            'state': StateChoices.DECIDED,
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)

        res = self.client.get('/api/loans/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)

    def test_destroy(self):
        loan = make_loan(name='住宅')
        res = self.client.delete(f'/api/loans/{loan.pk}/')
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Loan.objects.filter(pk=loan.pk).exists())


class AccountViewSetTests(APITestCaseBase):
    def test_list_and_update(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=1000,
        )
        res = self.client.get('/api/accounts/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data[0]['formed_balance'], '¥1,000')

        res = self.client.patch(
            f'/api/accounts/{acc.pk}/', data={'balance': 5000}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        acc.refresh_from_db()
        self.assertEqual(acc.balance, 5000)


class AccountRequireAPIViewTests(APITestCaseBase):
    def test_sufficient_and_insufficient(self):
        bank = make_bank('A'); user = make_user('U')
        acc = make_account(bank=bank, user=user, balance=1000)
        method = make_method(account=acc)
        make_expense(
            name='x', method=method, amount=300,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        make_expense(
            name='done', method=method, amount=9999,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 4, 5),
        )
        res = self.client.get('/api/account_require/?year=2025&month=4')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['require_sum'], 300)
        self.assertEqual(res.data['insufficient_sum'], 0)

        # 不足パターン
        make_expense(
            name='big', method=method, amount=5000,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 4, 20),
        )
        res = self.client.get('/api/account_require/?year=2025&month=4')
        self.assertEqual(res.data['require_sum'], 5300)
        self.assertEqual(res.data['insufficient_sum'], 4300)
        self.assertTrue(res.data['accounts'][0]['is_insufficient'])


class MethodRequireAPIViewTests(APITestCaseBase):
    def test_require(self):
        method = make_method()
        make_expense(
            name='x', method=method, amount=777,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        make_expense(
            name='done', method=method, amount=10000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 4, 2),
        )
        res = self.client.get('/api/method_require/?year=2025&month=4')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['require_sum'], 777)


class MethodDoneAPIViewTests(APITestCaseBase):
    def test_update(self):
        method = make_method()
        make_expense(
            name='a', method=method, amount=1,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        make_expense(
            name='b', method=method, amount=1,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 4, 2),
        )
        # 他月は変わらない
        make_expense(
            name='c', method=method, amount=1,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 5, 1),
        )
        res = self.client.post(
            f'/api/methods/{method.pk}/done/?year=2025&month=4'
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data, {'updated': 2})
        self.assertEqual(
            Expense.objects.filter(state=StateChoices.DONE).count(), 2
        )


class TrendAPIViewTests(APITestCaseBase):
    def test_default_months_with_explicit_end(self):
        method = make_method()
        make_income(
            name='i', method=method, amount=1000,
            pay_date=datetime.date(2025, 3, 1),
        )
        make_expense(
            name='e', method=method, amount=300,
            pay_date=datetime.date(2025, 3, 2),
        )
        res = self.client.get(
            '/api/trends/?months=3&end_year=2025&end_month=3'
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        months = res.data['months']
        self.assertEqual(len(months), 3)
        self.assertEqual(months[-1]['year'], 2025)
        self.assertEqual(months[-1]['month'], 3)
        self.assertEqual(months[-1]['income'], 1000)
        self.assertEqual(months[-1]['expense'], 300)

    def test_months_clamped(self):
        res = self.client.get(
            '/api/trends/?months=999&end_year=2025&end_month=3'
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertLessEqual(len(res.data['months']), 36)

    def test_months_invalid(self):
        res = self.client.get('/api/trends/?months=abc')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_end_year_month_invalid(self):
        res = self.client.get('/api/trends/?end_year=x&end_month=y')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_no_params_uses_current(self):
        res = self.client.get('/api/trends/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data['months']), 12)


class BalanceAPIViewTests(APITestCaseBase):
    def test_balance_summary(self):
        acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=5000,
        )
        method = make_method(account=acc)
        make_income(
            name='i', method=method, amount=2000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 3, 1),
        )
        res = self.client.get('/api/balance/?year=2025&month=4')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['balance_sum'], 5000)
        self.assertEqual(res.data['balance_on_db'], 2000)
        self.assertEqual(res.data['balance_diff'], 3000)
        self.assertEqual(res.data['accounts'][0]['formed_balance'], '¥5,000')

    def test_requires_year_month(self):
        res = self.client.get('/api/balance/')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)


class DefaultIncomeViewSetTests(APITestCaseBase):
    def setUp(self):
        super().setUp()
        self.method = make_method()

    def test_list_includes_months_sorted(self):
        di = make_default_income(name='給料', method=self.method)
        make_default_income_month(9, di)
        make_default_income_month(3, di)
        res = self.client.get('/api/default_incomes/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]['name'], '給料')
        self.assertEqual(res.data[0]['months'], [3, 9])

    def test_create_with_months(self):
        res = self.client.post('/api/default_incomes/', data={
            'name': 'ボーナス',
            'pay_day': 5,
            'method': self.method.pk,
            'amount': 100000,
            'state': StateChoices.DECIDED,
            'months': [6, 12],
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        di = DefaultIncome.objects.get(name='ボーナス')
        self.assertEqual(
            sorted(
                DefaultIncomeMonth.objects
                .filter(def_inc=di).values_list('month', flat=True)
            ),
            [6, 12],
        )

    def test_create_without_months(self):
        res = self.client.post('/api/default_incomes/', data={
            'name': '給料',
            'pay_day': 25,
            'method': self.method.pk,
            'amount': 300000,
            'state': StateChoices.DECIDED,
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        di = DefaultIncome.objects.get(name='給料')
        self.assertFalse(
            DefaultIncomeMonth.objects.filter(def_inc=di).exists()
        )

    def test_create_rejects_duplicate_months(self):
        res = self.client.post('/api/default_incomes/', data={
            'name': 'ボーナス',
            'pay_day': 5,
            'method': self.method.pk,
            'amount': 100000,
            'state': StateChoices.DECIDED,
            'months': [6, 6, 12],
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('months', res.data)

    def test_partial_update_syncs_months(self):
        di = make_default_income(name='給料', method=self.method)
        make_default_income_month(3, di)
        make_default_income_month(6, di)
        res = self.client.patch(
            f'/api/default_incomes/{di.pk}/',
            data={'months': [6, 9]}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertEqual(
            sorted(
                DefaultIncomeMonth.objects
                .filter(def_inc=di).values_list('month', flat=True)
            ),
            [6, 9],
        )

    def test_partial_update_without_months_preserves(self):
        di = make_default_income(name='給料', method=self.method)
        make_default_income_month(3, di)
        res = self.client.patch(
            f'/api/default_incomes/{di.pk}/',
            data={'amount': 999}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertEqual(
            list(
                DefaultIncomeMonth.objects
                .filter(def_inc=di).values_list('month', flat=True)
            ),
            [3],
        )

    def test_destroy(self):
        di = make_default_income(name='delete-me', method=self.method)
        res = self.client.delete(f'/api/default_incomes/{di.pk}/')
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(DefaultIncome.objects.filter(pk=di.pk).exists())


class DefaultExpenseViewSetTests(APITestCaseBase):
    def setUp(self):
        super().setUp()
        self.method = make_method()

    def test_list_includes_months_sorted(self):
        de = make_default_expense(name='家賃', method=self.method)
        make_default_expense_month(2, de)
        make_default_expense_month(11, de)
        res = self.client.get('/api/default_expenses/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]['name'], '家賃')
        self.assertEqual(res.data[0]['months'], [2, 11])

    def test_create_with_months(self):
        res = self.client.post('/api/default_expenses/', data={
            'name': '家賃',
            'pay_day': 10,
            'method': self.method.pk,
            'amount': 80000,
            'state': StateChoices.DECIDED,
            'months': [1, 7],
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        de = DefaultExpense.objects.get(name='家賃')
        self.assertEqual(
            sorted(
                DefaultExpenseMonth.objects
                .filter(def_exp=de).values_list('month', flat=True)
            ),
            [1, 7],
        )

    def test_partial_update_syncs_months(self):
        de = make_default_expense(name='家賃', method=self.method)
        make_default_expense_month(1, de)
        make_default_expense_month(4, de)
        res = self.client.patch(
            f'/api/default_expenses/{de.pk}/',
            data={'months': [4, 8]}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertEqual(
            sorted(
                DefaultExpenseMonth.objects
                .filter(def_exp=de).values_list('month', flat=True)
            ),
            [4, 8],
        )

    def test_destroy(self):
        de = make_default_expense(name='delete-me', method=self.method)
        res = self.client.delete(f'/api/default_expenses/{de.pk}/')
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(DefaultExpense.objects.filter(pk=de.pk).exists())


class TemplateExpenseListAPIViewTests(APITestCaseBase):
    def test_list_today_type(self):
        method = make_method(name='クレ')
        make_template_expense(
            template_name='ランチ', name='食費',
            date_type='today', method=method,
        )
        res = self.client.get('/api/template_expenses/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)
        item = res.data[0]
        self.assertEqual(item['template_name'], 'ランチ')
        self.assertEqual(item['name'], '食費')
        self.assertEqual(item['date_type'], 'today')
        # date_type='today' なら今日の日付になる。
        self.assertEqual(
            item['pay_date'],
            datetime.date.today().strftime('%Y-%m-%d'),
        )
        self.assertEqual(item['method_name'], str(method))


class AccountNegativeBalanceTests(APITestCaseBase):
    """0016 マイグレーション: balance を PositiveIntegerField → IntegerField に変更。"""

    def test_update_to_negative(self):
        acc = make_account(
            bank=make_bank('B'), user=make_user('U2'), balance=1000,
        )
        res = self.client.patch(
            f'/api/accounts/{acc.pk}/',
            data={'balance': -500}, format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        acc.refresh_from_db()
        self.assertEqual(acc.balance, -500)


class JWTAuthTests(TestCase):
    """マージで導入された SimpleJWT のログイン挙動。"""

    def setUp(self):
        self.client = APIClient()  # 認証なし
        make_auth_user(username='tester', password='pass12345')

    def test_login_returns_access_and_refresh(self):
        res = self.client.post('/api/auth/login/', data={
            'username': 'tester', 'password': 'pass12345',
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)

    def test_login_invalid_credentials(self):
        res = self.client.post('/api/auth/login/', data={
            'username': 'tester', 'password': 'wrong',
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_api_call_rejected(self):
        res = self.client.get('/api/methods/')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_access_token_grants_access(self):
        res = self.client.post('/api/auth/login/', data={
            'username': 'tester', 'password': 'pass12345',
        }, format='json')
        access = res.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
        res = self.client.get('/api/methods/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
