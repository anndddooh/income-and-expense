"""シリアライザ層のテスト。"""
import datetime

from dateutil.relativedelta import relativedelta
from django.test import TestCase
from django.utils import timezone

from income_and_expense.models import (
    DefaultExpenseMonth, DefaultIncomeMonth, StateChoices,
)
from income_and_expense.serializers import (
    AccountSerializer, DefaultExpenseSerializer, DefaultIncomeSerializer,
    ExpenseSerializer, IncomeSerializer, LoanSerializer, MethodSerializer,
    TemplateExpenseSerializer, is_valid_pay_date,
)
from income_and_expense.tests.factories import (
    make_account, make_bank, make_default_expense,
    make_default_expense_month, make_default_income,
    make_default_income_month, make_expense, make_income, make_loan,
    make_method, make_template_expense, make_user,
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

    def test_validate_pay_date_unchanged_allowed_on_update(self):
        # マージで追加された免除ロジック: 既存インスタンスで pay_date が
        # 同じ値なら、古い日付でもバリデーションを通す。
        old = _today() - relativedelta(months=3)
        inc = make_income(
            name='x', method=self.method, amount=1, pay_date=old,
        )
        s = IncomeSerializer(inc, data={
            'name': 'updated', 'pay_date': old.isoformat(),
            'method': self.method.pk, 'amount': 2,
            'state': StateChoices.UNDECIDED, 'memo': '',
        })
        self.assertTrue(s.is_valid(), s.errors)

    def test_validate_pay_date_changed_to_old_still_rejected(self):
        # 別の古い日付に変えようとすると引き続き拒否される。
        inc = make_income(
            name='x', method=self.method, amount=1, pay_date=_today(),
        )
        too_old = _today() - relativedelta(months=2)
        s = IncomeSerializer(inc, data={
            'name': 'x', 'pay_date': too_old.isoformat(),
            'method': self.method.pk, 'amount': 1,
            'state': StateChoices.UNDECIDED, 'memo': '',
        })
        self.assertFalse(s.is_valid())
        self.assertIn('pay_date', s.errors)


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


class DefaultIncomeSerializerTests(TestCase):
    def setUp(self):
        self.acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        self.method = make_method(name='クレ', account=self.acc)

    def test_serialize_includes_months_sorted(self):
        di = make_default_income(name='給料', method=self.method)
        make_default_income_month(9, di)
        make_default_income_month(3, di)
        make_default_income_month(6, di)
        data = DefaultIncomeSerializer(di).data
        self.assertEqual(data['months'], [3, 6, 9])
        self.assertEqual(data['name'], '給料')
        self.assertEqual(data['method_name'], 'クレ')
        self.assertEqual(data['account'], {
            'id': self.acc.id, 'user': 'U', 'bank': 'A',
        })

    def test_serialize_no_months(self):
        di = make_default_income(name='給料', method=self.method)
        data = DefaultIncomeSerializer(di).data
        self.assertEqual(data['months'], [])

    def test_validate_months_rejects_duplicates(self):
        s = DefaultIncomeSerializer(data={
            'name': 'ボーナス', 'pay_day': 1, 'method': self.method.pk,
            'amount': 1000, 'state': StateChoices.DECIDED,
            'months': [1, 1, 2],
        })
        self.assertFalse(s.is_valid())
        self.assertIn('months', s.errors)

    def test_validate_months_rejects_out_of_range(self):
        s = DefaultIncomeSerializer(data={
            'name': 'ボーナス', 'pay_day': 1, 'method': self.method.pk,
            'amount': 1000, 'state': StateChoices.DECIDED,
            'months': [0, 13],
        })
        self.assertFalse(s.is_valid())
        self.assertIn('months', s.errors)

    def test_validate_months_sorts(self):
        s = DefaultIncomeSerializer(data={
            'name': 'ボーナス', 'pay_day': 1, 'method': self.method.pk,
            'amount': 1000, 'state': StateChoices.DECIDED,
            'months': [12, 6, 3],
        })
        self.assertTrue(s.is_valid(), s.errors)
        self.assertEqual(s.validated_data['months'], [3, 6, 12])

    def test_create_with_months(self):
        s = DefaultIncomeSerializer(data={
            'name': 'ボーナス', 'pay_day': 1, 'method': self.method.pk,
            'amount': 1000, 'state': StateChoices.DECIDED,
            'months': [6, 12],
        })
        self.assertTrue(s.is_valid(), s.errors)
        di = s.save()
        actual = sorted(
            DefaultIncomeMonth.objects
            .filter(def_inc=di).values_list('month', flat=True)
        )
        self.assertEqual(actual, [6, 12])

    def test_update_sync_months_removes_and_adds(self):
        di = make_default_income(name='給料', method=self.method)
        make_default_income_month(3, di)
        make_default_income_month(6, di)
        s = DefaultIncomeSerializer(
            di, data={'months': [6, 9]}, partial=True,
        )
        self.assertTrue(s.is_valid(), s.errors)
        s.save()
        actual = sorted(
            DefaultIncomeMonth.objects
            .filter(def_inc=di).values_list('month', flat=True)
        )
        self.assertEqual(actual, [6, 9])

    def test_update_without_months_preserves(self):
        di = make_default_income(name='給料', method=self.method)
        make_default_income_month(3, di)
        s = DefaultIncomeSerializer(
            di, data={'amount': 999}, partial=True,
        )
        self.assertTrue(s.is_valid(), s.errors)
        s.save()
        actual = list(
            DefaultIncomeMonth.objects
            .filter(def_inc=di).values_list('month', flat=True)
        )
        self.assertEqual(actual, [3])


class DefaultExpenseSerializerTests(TestCase):
    def setUp(self):
        self.acc = make_account(
            bank=make_bank('A'), user=make_user('U'), balance=0,
        )
        self.method = make_method(name='クレ', account=self.acc)

    def test_serialize_includes_months_sorted(self):
        de = make_default_expense(name='家賃', method=self.method)
        make_default_expense_month(11, de)
        make_default_expense_month(2, de)
        data = DefaultExpenseSerializer(de).data
        self.assertEqual(data['months'], [2, 11])
        self.assertEqual(data['name'], '家賃')
        self.assertEqual(data['account']['user'], 'U')

    def test_validate_months_rejects_duplicates(self):
        s = DefaultExpenseSerializer(data={
            'name': '家賃', 'pay_day': 10, 'method': self.method.pk,
            'amount': 80000, 'state': StateChoices.DECIDED,
            'months': [4, 4],
        })
        self.assertFalse(s.is_valid())
        self.assertIn('months', s.errors)

    def test_create_and_update_sync_months(self):
        s = DefaultExpenseSerializer(data={
            'name': '家賃', 'pay_day': 10, 'method': self.method.pk,
            'amount': 80000, 'state': StateChoices.DECIDED,
            'months': [1, 7],
        })
        self.assertTrue(s.is_valid(), s.errors)
        de = s.save()
        self.assertEqual(
            sorted(
                DefaultExpenseMonth.objects
                .filter(def_exp=de).values_list('month', flat=True)
            ),
            [1, 7],
        )
        s2 = DefaultExpenseSerializer(
            de, data={'months': [7, 8, 9]}, partial=True,
        )
        self.assertTrue(s2.is_valid(), s2.errors)
        s2.save()
        self.assertEqual(
            sorted(
                DefaultExpenseMonth.objects
                .filter(def_exp=de).values_list('month', flat=True)
            ),
            [7, 8, 9],
        )


class TemplateExpenseSerializerTests(TestCase):
    def setUp(self):
        self.method = make_method(name='クレ')

    def test_today_type_returns_today(self):
        te = make_template_expense(
            template_name='ランチ', name='食費',
            date_type='today', method=self.method,
        )
        data = TemplateExpenseSerializer(te).data
        self.assertEqual(
            data['pay_date'],
            datetime.date.today().strftime('%Y-%m-%d'),
        )
        self.assertEqual(data['template_name'], 'ランチ')
        self.assertEqual(data['name'], '食費')
        self.assertEqual(data['date_type'], 'today')
        self.assertEqual(data['method_name'], str(self.method))

    def test_later_type_returns_parseable_future_date(self):
        # date_type='later' は実行日依存だが、ISO 形式かつ今日以降の日付に
        # なることだけ保証する(具体的な月推移は実装ロジックの一意性に依存)。
        te = make_template_expense(
            template_name='家賃', name='家賃',
            date_type='later', pay_day=10, limit_day_of_this_month=5,
            method=self.method,
        )
        data = TemplateExpenseSerializer(te).data
        parsed = datetime.datetime.strptime(
            data['pay_date'], '%Y-%m-%d'
        ).date()
        self.assertGreaterEqual(parsed, datetime.date.today())
