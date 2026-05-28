"""HTTP ビュー層のテスト。ログイン保護やリダイレクトを確認する。"""
import datetime

from dateutil.relativedelta import relativedelta
from django.contrib.messages import get_messages
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone

from income_and_expense.models import (
    Expense, Income, Loan, StateChoices,
)
from income_and_expense.tests.factories import (
    current_year_month, make_account, make_auth_user, make_bank,
    make_default_expense, make_default_expense_month, make_default_income,
    make_default_income_month, make_expense, make_income, make_loan,
    make_method, make_template_expense, make_user, shift_month,
)


@override_settings(LANGUAGE_CODE='en-us')
class AuthRequiredTests(TestCase):
    """未ログインだとログイン画面にリダイレクトされる。"""

    def test_index_redirects_to_login(self):
        res = self.client.get(reverse('income_and_expense:index'))
        self.assertEqual(res.status_code, 302)
        self.assertIn('/login', res.url)

    def test_income_requires_login(self):
        res = self.client.get(
            reverse('income_and_expense:income', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 302)


class LoggedInViewTestsBase(TestCase):
    def setUp(self):
        self.user = make_auth_user('tester', 'pass12345')
        self.assertTrue(self.client.login(
            username='tester', password='pass12345'
        ))


class IndexAndMoveAnotherPageTests(LoggedInViewTestsBase):
    def test_index_redirects_to_income_for_current_month(self):
        res = self.client.get(reverse('income_and_expense:index'))
        self.assertEqual(res.status_code, 302)
        now = timezone.now()
        self.assertIn(
            reverse(
                'income_and_expense:income', args=[now.year, now.month]
            ),
            res.url,
        )

    def test_move_another_page(self):
        res = self.client.get(
            reverse('income_and_expense:move_another_page')
            + '?path_name=income_and_expense:income&year=2025&month=7'
        )
        self.assertEqual(res.status_code, 302)
        self.assertIn('/income/2025/7', res.url)


class IncomeExpenseViewTests(LoggedInViewTestsBase):
    def setUp(self):
        super().setUp()
        self.method = make_method()

    def test_income_view_renders(self):
        make_income(
            name='給料', method=self.method,
            pay_date=datetime.date(2025, 4, 1),
            amount=1000, state=StateChoices.DECIDED,
        )
        res = self.client.get(
            reverse('income_and_expense:income', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.context['this_year'], 2025)
        self.assertEqual(res.context['this_mon'], 4)
        self.assertEqual(list(res.context['incs']), [Income.objects.get(name='給料')])

    def test_expense_view_renders(self):
        make_expense(
            name='家賃', method=self.method,
            pay_date=datetime.date(2025, 4, 1),
            amount=800, state=StateChoices.DECIDED,
        )
        res = self.client.get(
            reverse('income_and_expense:expense', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.context['exp_sum'], 800)


class AddDefaultIncomesViewTests(LoggedInViewTestsBase):
    def test_success(self):
        y, m = current_year_month()
        method = make_method()
        di = make_default_income(name='給料', pay_day=10, method=method)
        make_default_income_month(m, di)

        res = self.client.get(
            reverse('income_and_expense:add_default_incs', args=[y, m])
        )
        self.assertEqual(res.status_code, 302)
        msgs = [str(x) for x in get_messages(res.wsgi_request)]
        self.assertTrue(any('デフォルト収入が追加' in s for s in msgs))

    def test_no_default_shows_error(self):
        y, m = current_year_month()
        res = self.client.get(
            reverse('income_and_expense:add_default_incs', args=[y, m])
        )
        msgs = [str(x) for x in get_messages(res.wsgi_request)]
        self.assertTrue(any('追加できるデフォルト' in s for s in msgs))

    def test_past_month_rejected(self):
        y, m = shift_month(*current_year_month(), delta=-2)
        res = self.client.get(
            reverse('income_and_expense:add_default_incs', args=[y, m])
        )
        self.assertEqual(res.status_code, 302)
        msgs = [str(x) for x in get_messages(res.wsgi_request)]
        self.assertTrue(any('過去には' in s for s in msgs))


class AddDefaultExpensesViewTests(LoggedInViewTestsBase):
    def test_success_adds_default_expense(self):
        y, m = current_year_month()
        method = make_method()
        de = make_default_expense(name='家賃', pay_day=10, method=method)
        make_default_expense_month(m, de)

        res = self.client.get(
            reverse('income_and_expense:add_default_exps', args=[y, m])
        )
        self.assertEqual(res.status_code, 302)
        self.assertTrue(Expense.objects.filter(name='家賃').exists())

    def test_no_default_shows_error(self):
        y, m = current_year_month()
        res = self.client.get(
            reverse('income_and_expense:add_default_exps', args=[y, m])
        )
        msgs = [str(x) for x in get_messages(res.wsgi_request)]
        self.assertTrue(any('追加できるデフォルト' in s for s in msgs))

    def test_past_month_rejected(self):
        y, m = shift_month(*current_year_month(), delta=-3)
        res = self.client.get(
            reverse('income_and_expense:add_default_exps', args=[y, m])
        )
        msgs = [str(x) for x in get_messages(res.wsgi_request)]
        self.assertTrue(any('過去には' in s for s in msgs))


class BalanceAndRequireViewTests(LoggedInViewTestsBase):
    def setUp(self):
        super().setUp()
        self.acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=5000,
        )
        self.method = make_method(account=self.acc)

    def test_balance_view(self):
        make_income(
            name='i', method=self.method, amount=2000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 3, 1),
        )
        res = self.client.get(
            reverse('income_and_expense:balance', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.context['balance_sum'], 5000)
        self.assertEqual(res.context['balance_on_db'], 2000)
        self.assertEqual(res.context['balance_diff'], 3000)

    def test_account_require_sufficient(self):
        make_expense(
            name='x', method=self.method, amount=1000,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        res = self.client.get(
            reverse('income_and_expense:account_require', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        ctx = res.context
        self.assertEqual(ctx['require_sum'], '¥1,000')
        self.assertEqual(ctx['insufficient_sum'], '¥0')
        self.assertFalse(ctx['account_requires'][0]['is_insufficient'])

    def test_account_require_insufficient(self):
        make_expense(
            name='x', method=self.method, amount=9999,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        res = self.client.get(
            reverse('income_and_expense:account_require', args=[2025, 4])
        )
        ctx = res.context
        self.assertEqual(ctx['insufficient_sum'], '¥4,999')
        self.assertTrue(ctx['account_requires'][0]['is_insufficient'])

    def test_account_require_excludes_done(self):
        make_expense(
            name='x', method=self.method, amount=1000,
            state=StateChoices.DONE,
            pay_date=datetime.date(2025, 4, 1),
        )
        res = self.client.get(
            reverse('income_and_expense:account_require', args=[2025, 4])
        )
        self.assertEqual(res.context['require_sum'], '¥0')

    def test_method_require_view(self):
        make_expense(
            name='x', method=self.method, amount=300,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 4, 1),
        )
        res = self.client.get(
            reverse('income_and_expense:method_require', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.context['require_sum'], '¥300')

    def test_method_require_with_method_without_expenses(self):
        # method は存在するが 今月に expense が無い → require is None ブランチ
        make_method(name='empty-method')
        res = self.client.get(
            reverse('income_and_expense:method_require', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.context['require_sum'], '¥0')


class MethodDoneViewTests(LoggedInViewTestsBase):
    def test_method_done_updates_expenses(self):
        method = make_method()
        make_expense(
            name='a', method=method, amount=100,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 4, 3),
        )
        make_expense(
            name='b', method=method, amount=200,
            state=StateChoices.DECIDED,
            pay_date=datetime.date(2025, 4, 10),
        )
        # 別月の支出は更新されない
        make_expense(
            name='c', method=method, amount=500,
            state=StateChoices.UNDECIDED,
            pay_date=datetime.date(2025, 5, 1),
        )
        res = self.client.get(reverse(
            'income_and_expense:method_done', args=[2025, 4, method.pk],
        ))
        self.assertEqual(res.status_code, 302)
        self.assertEqual(
            Expense.objects.filter(state=StateChoices.DONE).count(), 2
        )


class LoanViewTests(LoggedInViewTestsBase):
    def test_loan_view_marks_complete(self):
        make_loan(
            name='old', pay_day=1,
            first_year=2020, first_month=1,
            last_year=2020, last_month=12,
            amount_first=1, amount_from_second=1,
            method=make_method(),
        )
        make_loan(
            name='active', pay_day=1,
            first_year=2024, first_month=1,
            last_year=2099, last_month=12,
            amount_first=1, amount_from_second=1,
            method=make_method(name='m2'),
        )
        res = self.client.get(
            reverse('income_and_expense:loan', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        results = {
            x['loan'].name: x['complete']
            for x in res.context['loans_and_completes']
        }
        self.assertTrue(results['old'])
        self.assertFalse(results['active'])

    def test_loan_complete_when_same_year_later_month(self):
        make_loan(
            name='border', pay_day=1,
            first_year=2024, first_month=1,
            last_year=2025, last_month=3,
            amount_first=1, amount_from_second=1,
            method=make_method(),
        )
        res = self.client.get(
            reverse('income_and_expense:loan', args=[2025, 4])
        )
        results = {
            x['loan'].name: x['complete']
            for x in res.context['loans_and_completes']
        }
        self.assertTrue(results['border'])


def _make_fake_datetime_module(today_value):
    """views.datetime を差し替えるための軽量モジュール代替。

    views 内で使われる ``datetime.date``/``datetime.timedelta`` を実装を保ったまま、
    ``date.today()`` だけを固定値にする。
    """
    import types

    class _FakeDate(datetime.date):
        @classmethod
        def today(cls):
            return today_value

    ns = types.SimpleNamespace()
    ns.date = _FakeDate
    ns.timedelta = datetime.timedelta
    return ns


class ExpenseCreateViewContextTests(LoggedInViewTestsBase):
    def test_context_today_template(self):
        method = make_method()
        make_template_expense(
            template_name='即日', name='食費',
            date_type='today', method=method,
        )
        res = self.client.get(
            reverse('income_and_expense:create_exp', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        templates = res.context['template_exps']
        self.assertEqual(len(templates), 1)
        today = datetime.date.today()
        self.assertEqual(
            templates[0]['pay_date'],
            '{}-{:02d}-{:02d}'.format(today.year, today.month, today.day),
        )

    def test_context_later_template_before_limit(self):
        method = make_method()
        # limit を大きく取り、pay_day は limit より大きい値 (=同月払い) にする
        make_template_expense(
            template_name='後日', name='カード',
            date_type='later', pay_day=28,
            limit_day_of_this_month=27,
            method=method,
        )
        res = self.client.get(
            reverse('income_and_expense:create_exp', args=[2025, 4])
        )
        self.assertEqual(res.status_code, 200)
        # 支払日文字列が YYYY-MM-DD 形式で返る
        self.assertRegex(
            res.context['template_exps'][0]['pay_date'],
            r'^\d{4}-\d{2}-\d{2}$',
        )

    def test_context_later_after_limit_adds_month(self):
        """today.day > limit_day_of_this_month → 翌月に繰越し (L424-426)。"""
        from unittest.mock import patch
        method = make_method()
        make_template_expense(
            template_name='後日1', name='カード',
            date_type='later', pay_day=5,
            limit_day_of_this_month=10,
            method=method,
        )
        fake = _make_fake_datetime_module(datetime.date(2025, 6, 20))
        with patch('income_and_expense.views.datetime', fake):
            res = self.client.get(
                reverse('income_and_expense:create_exp', args=[2025, 6])
            )
        self.assertEqual(res.status_code, 200)
        # today.day(20) > limit(10) → 翌月、pay_day(5) < limit(10) → さらに翌月 = 8 月
        self.assertEqual(
            res.context['template_exps'][0]['pay_date'], '2025-08-05'
        )

    def test_context_later_pay_day_less_than_limit_before_deadline(self):
        """today.day <= limit かつ pay_day < limit → +1 月 (L427-428)。"""
        from unittest.mock import patch
        method = make_method()
        make_template_expense(
            template_name='後日2', name='カード',
            date_type='later', pay_day=5,
            limit_day_of_this_month=10,
            method=method,
        )
        fake = _make_fake_datetime_module(datetime.date(2025, 6, 8))
        with patch('income_and_expense.views.datetime', fake):
            res = self.client.get(
                reverse('income_and_expense:create_exp', args=[2025, 6])
            )
        self.assertEqual(res.status_code, 200)
        # today.day(8) <= limit(10) → 同月 6 月、pay_day(5) < limit(10) → +1 月 = 7 月
        self.assertEqual(
            res.context['template_exps'][0]['pay_date'], '2025-07-05'
        )


class UpdateDeleteOldInexTests(LoggedInViewTestsBase):
    def test_income_update_old_date_is_rejected(self):
        method = make_method()
        today = datetime.date.today()
        old = today - relativedelta(months=3)
        inc = make_income(
            name='x', method=method, amount=10, pay_date=old,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:update_inc',
                args=[old.year, old.month, inc.pk],
            ),
            data={'name': 'y'},
        )
        self.assertEqual(res.status_code, 302)

    def test_income_delete_old_date_is_rejected(self):
        method = make_method()
        today = datetime.date.today()
        old = today - relativedelta(months=3)
        inc = make_income(
            name='x', method=method, amount=10, pay_date=old,
        )
        # URL の (year, month) は現在月だが実際の pay_date が古い
        res = self.client.post(
            reverse(
                'income_and_expense:delete_inc',
                args=[today.year, today.month, inc.pk],
            ),
        )
        self.assertEqual(res.status_code, 302)
        self.assertTrue(Income.objects.filter(pk=inc.pk).exists())

    def test_expense_update_old_date_is_rejected(self):
        method = make_method()
        today = datetime.date.today()
        old = today - relativedelta(months=3)
        exp = make_expense(
            name='x', method=method, amount=10, pay_date=old,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:update_exp',
                args=[old.year, old.month, exp.pk],
            ),
            data={'name': 'y'},
        )
        self.assertEqual(res.status_code, 302)

    def test_expense_delete_old_date_is_rejected(self):
        method = make_method()
        today = datetime.date.today()
        old = today - relativedelta(months=3)
        exp = make_expense(
            name='x', method=method, amount=10, pay_date=old,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:delete_exp',
                args=[today.year, today.month, exp.pk],
            ),
        )
        self.assertEqual(res.status_code, 302)
        self.assertTrue(Expense.objects.filter(pk=exp.pk).exists())


class LoanDeleteViewTests(LoggedInViewTestsBase):
    def test_delete_loan(self):
        loan = make_loan(name='住宅')
        res = self.client.post(
            reverse(
                'income_and_expense:delete_loan',
                args=[2025, 4, loan.pk],
            ),
        )
        self.assertEqual(res.status_code, 302)
        self.assertFalse(Loan.objects.filter(pk=loan.pk).exists())


class InexCrudSuccessPathTests(LoggedInViewTestsBase):
    """直近の日付であれば Create/Update/Delete が成功する。get_success_url も通る。"""

    def setUp(self):
        super().setUp()
        self.method = make_method()
        self.today = datetime.date.today()

    def _form_data(self, pay_date, name='test', amount=100):
        return {
            'name': name,
            'pay_date': pay_date.strftime('%Y-%m-%d'),
            'method': self.method.pk,
            'amount': amount,
            'state': StateChoices.UNDECIDED,
            'memo': '',
        }

    def test_create_income_redirects_to_income(self):
        res = self.client.post(
            reverse(
                'income_and_expense:create_inc',
                args=[self.today.year, self.today.month],
            ),
            data=self._form_data(self.today, name='給料'),
        )
        self.assertEqual(res.status_code, 302)
        self.assertIn(
            reverse(
                'income_and_expense:income',
                args=[self.today.year, self.today.month],
            ),
            res.url,
        )
        self.assertTrue(Income.objects.filter(name='給料').exists())

    def test_update_income_success_redirect(self):
        inc = make_income(
            name='old', method=self.method, amount=100, pay_date=self.today,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:update_inc',
                args=[self.today.year, self.today.month, inc.pk],
            ),
            data=self._form_data(self.today, name='new', amount=999),
        )
        self.assertEqual(res.status_code, 302)
        inc.refresh_from_db()
        self.assertEqual(inc.name, 'new')

    def test_delete_income_success(self):
        inc = make_income(
            name='gone', method=self.method, amount=1, pay_date=self.today,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:delete_inc',
                args=[self.today.year, self.today.month, inc.pk],
            ),
        )
        self.assertEqual(res.status_code, 302)
        self.assertFalse(Income.objects.filter(pk=inc.pk).exists())

    def test_create_expense_redirects(self):
        res = self.client.post(
            reverse(
                'income_and_expense:create_exp',
                args=[self.today.year, self.today.month],
            ),
            data=self._form_data(self.today, name='食費'),
        )
        self.assertEqual(res.status_code, 302)
        self.assertTrue(Expense.objects.filter(name='食費').exists())

    def test_update_expense_success(self):
        exp = make_expense(
            name='old', method=self.method, amount=1, pay_date=self.today,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:update_exp',
                args=[self.today.year, self.today.month, exp.pk],
            ),
            data=self._form_data(self.today, name='new', amount=555),
        )
        self.assertEqual(res.status_code, 302)
        exp.refresh_from_db()
        self.assertEqual(exp.amount, 555)

    def test_delete_expense_success(self):
        exp = make_expense(
            name='gone', method=self.method, amount=1, pay_date=self.today,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:delete_exp',
                args=[self.today.year, self.today.month, exp.pk],
            ),
        )
        self.assertEqual(res.status_code, 302)
        self.assertFalse(Expense.objects.filter(pk=exp.pk).exists())

    def test_update_balance_success(self):
        acc = make_account(
            bank=make_bank('X'), user=make_user('Y'), balance=0,
        )
        res = self.client.post(
            reverse(
                'income_and_expense:update_balance',
                args=[self.today.year, self.today.month, acc.pk],
            ),
            data={'bank': acc.bank.pk, 'user': acc.user.pk, 'balance': 4321},
        )
        self.assertEqual(res.status_code, 302)
        acc.refresh_from_db()
        self.assertEqual(acc.balance, 4321)

    def test_create_loan_redirects(self):
        res = self.client.post(
            reverse(
                'income_and_expense:create_loan',
                args=[self.today.year, self.today.month],
            ),
            data={
                'name': '住宅', 'pay_day': 15,
                'first_year': 2025, 'first_month': 1,
                'last_year': 2030, 'last_month': 12,
                'method': self.method.pk,
                'amount_first': 100000, 'amount_from_second': 50000,
                'state': StateChoices.DECIDED,
            },
        )
        self.assertEqual(res.status_code, 302)
        self.assertTrue(Loan.objects.filter(name='住宅').exists())

    def test_update_loan_success(self):
        loan = make_loan(name='住宅', amount_first=1, amount_from_second=1)
        res = self.client.post(
            reverse(
                'income_and_expense:update_loan',
                args=[self.today.year, self.today.month, loan.pk],
            ),
            data={
                'name': '住宅-改', 'pay_day': loan.pay_day,
                'first_year': loan.first_year, 'first_month': loan.first_month,
                'last_year': loan.last_year, 'last_month': loan.last_month,
                'method': loan.method.pk,
                'amount_first': 5, 'amount_from_second': 3,
                'state': loan.state,
            },
        )
        self.assertEqual(res.status_code, 302)
        loan.refresh_from_db()
        self.assertEqual(loan.name, '住宅-改')
