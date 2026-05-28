import datetime

from dateutil.relativedelta import relativedelta
from django.db.models import Q, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone
from rest_framework import generics, status, views, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from income_and_expense.models import (
    Account, DefaultExpense, DefaultExpenseMonth, DefaultIncome,
    DefaultIncomeMonth, Expense, Income, Loan, Method, StateChoices,
    TemplateExpense,
)
from income_and_expense.serializers import (
    AccountSerializer, DefaultExpenseSerializer, DefaultIncomeSerializer,
    ExpenseSerializer, IncomeSerializer, LoanSerializer, MethodSerializer,
    TemplateExpenseSerializer,
)


def _month_range(year, month):
    first_date = datetime.date(year, month, 1)
    last_date = first_date + relativedelta(months=1) - datetime.timedelta(days=1)
    return first_date, last_date


def _parse_year_month(request):
    year = request.query_params.get('year')
    month = request.query_params.get('month')
    if not year or not month:
        raise ValidationError('year と month は必須です')
    try:
        return int(year), int(month)
    except (TypeError, ValueError):
        raise ValidationError('year, month は整数で指定してください')


def _can_delete(year, month):
    current_time = timezone.now()
    current_first = datetime.date(current_time.year, current_time.month, 1)
    last_month_first = current_first - relativedelta(months=1)
    return datetime.date(year, month, 1) >= last_month_first


def _can_add_default(year, month):
    current_time = timezone.now()
    current_first = datetime.date(current_time.year, current_time.month, 1)
    return datetime.date(year, month, 1) >= current_first


def _get_balance_done(year, month):
    """該当月末までの残高(完了分)。"""
    _, last_date = _month_range(year, month)
    inc = Income.objects.filter(
        pay_date__lte=last_date, state=StateChoices.DONE
    ).aggregate(Sum('amount'))['amount__sum'] or 0
    exp = Expense.objects.filter(
        pay_date__lte=last_date, state=StateChoices.DONE
    ).aggregate(Sum('amount'))['amount__sum'] or 0
    return inc - exp


def _get_balance(year, month):
    """該当月末までの残高(全状態)。"""
    _, last_date = _month_range(year, month)
    inc = Income.objects.filter(
        pay_date__lte=last_date,
    ).aggregate(Sum('amount'))['amount__sum'] or 0
    exp = Expense.objects.filter(
        pay_date__lte=last_date,
    ).aggregate(Sum('amount'))['amount__sum'] or 0
    return inc - exp


class _InexViewSetBase(viewsets.ModelViewSet):
    model = None

    def get_queryset(self):
        qs = self.model.objects.select_related(
            'method__account__user', 'method__account__bank'
        )
        if self.action == 'list':
            year, month = _parse_year_month(self.request)
            first_date, last_date = _month_range(year, month)
            qs = qs.filter(pay_date__gte=first_date, pay_date__lte=last_date)
        return qs.order_by(
            'method__account__user__name', 'method__name',
            'method__account__bank__name', '-amount', 'state', 'pay_date', 'name'
        )

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if not _can_delete(instance.pay_date.year, instance.pay_date.month):
            raise ValidationError("古いデータは削除できません。")
        return super().destroy(request, *args, **kwargs)


class IncomeViewSet(_InexViewSetBase):
    serializer_class = IncomeSerializer
    model = Income
    queryset = Income.objects.all()

    def list(self, request, *args, **kwargs):
        year, month = _parse_year_month(request)
        prev = datetime.date(year, month, 1) - relativedelta(months=1)
        response = super().list(request, *args, **kwargs)
        response.data = {
            'results': response.data,
            'prev_balance': _get_balance(prev.year, prev.month),
        }
        return response

    @action(detail=False, methods=['post'], url_path='add_defaults')
    def add_defaults(self, request):
        year, month = _parse_year_month(request)
        if not _can_add_default(year, month):
            raise ValidationError("過去の月にはデフォルトを追加できません。")

        first_date, last_date = _month_range(year, month)
        def_inc_months = DefaultIncomeMonth.objects.filter(month=month)
        existing_names = set(
            Income.objects.filter(
                pay_date__gte=first_date, pay_date__lte=last_date
            ).values_list('name', flat=True)
        )

        add_num = 0
        for dim in def_inc_months:
            di = dim.def_inc
            if di.name in existing_names:
                continue
            Income(
                name=di.name,
                pay_date=datetime.date(year, month, di.pay_day),
                method=di.method, amount=di.amount, state=di.state,
            ).save()
            add_num += 1

        return Response({'added': add_num}, status=status.HTTP_201_CREATED)


class ExpenseViewSet(_InexViewSetBase):
    serializer_class = ExpenseSerializer
    model = Expense
    queryset = Expense.objects.all()

    def list(self, request, *args, **kwargs):
        year, month = _parse_year_month(request)
        response = super().list(request, *args, **kwargs)
        response.data = {
            'results': response.data,
            'balance': _get_balance(year, month),
        }
        return response

    @action(detail=False, methods=['post'], url_path='add_defaults')
    def add_defaults(self, request):
        year, month = _parse_year_month(request)
        if not _can_add_default(year, month):
            raise ValidationError("過去の月にはデフォルトを追加できません。")

        first_date, last_date = _month_range(year, month)
        existing_names = set(
            Expense.objects.filter(
                pay_date__gte=first_date, pay_date__lte=last_date
            ).values_list('name', flat=True)
        )

        add_num = 0
        for dem in DefaultExpenseMonth.objects.filter(month=month):
            de = dem.def_exp
            if de.name in existing_names:
                continue
            Expense(
                name=de.name,
                pay_date=datetime.date(year, month, de.pay_day),
                method=de.method, amount=de.amount, state=de.state,
            ).save()
            add_num += 1
            existing_names.add(de.name)

        loans = Loan.objects.filter(
            (Q(first_year__lt=year) | Q(first_year=year, first_month__lte=month)),
            (Q(last_year__gt=year) | Q(last_year=year, last_month__gte=month))
        )
        for loan in loans:
            if loan.name in existing_names:
                continue
            if year == loan.first_year and month == loan.first_month:
                amount = loan.amount_first
            else:
                amount = loan.amount_from_second
            Expense(
                name=loan.name,
                pay_date=datetime.date(year, month, loan.pay_day),
                method=loan.method, amount=amount, state=loan.state,
            ).save()
            add_num += 1
            existing_names.add(loan.name)

        return Response({'added': add_num}, status=status.HTTP_201_CREATED)


class TemplateExpenseListAPIView(generics.ListAPIView):
    serializer_class = TemplateExpenseSerializer
    queryset = TemplateExpense.objects.select_related(
        'method__account__user', 'method__account__bank'
    ).all()


class MethodListAPIView(generics.ListAPIView):
    serializer_class = MethodSerializer

    def get_queryset(self):
        return Method.objects.select_related(
            'account__user', 'account__bank'
        ).order_by(
            'name', 'account__user__name', 'account__bank__name'
        )


class DefaultIncomeViewSet(viewsets.ModelViewSet):
    serializer_class = DefaultIncomeSerializer
    queryset = DefaultIncome.objects.select_related(
        'method__account__user', 'method__account__bank'
    ).order_by('name')


class DefaultExpenseViewSet(viewsets.ModelViewSet):
    serializer_class = DefaultExpenseSerializer
    queryset = DefaultExpense.objects.select_related(
        'method__account__user', 'method__account__bank'
    ).order_by('name')


class LoanViewSet(viewsets.ModelViewSet):
    serializer_class = LoanSerializer
    queryset = Loan.objects.select_related(
        'method__account__user', 'method__account__bank'
    ).order_by('-last_year', '-last_month')


class AccountViewSet(viewsets.ModelViewSet):
    """口座一覧と残高更新用。"""
    serializer_class = AccountSerializer
    queryset = Account.objects.select_related('user', 'bank').order_by(
        'user__name', 'bank__name'
    )


class AccountRequireAPIView(views.APIView):
    """口座別の必要金額(未完了支出の合計)と不足額。"""

    def get(self, request):
        year, month = _parse_year_month(request)
        first_date, last_date = _month_range(year, month)
        exps = Expense.objects.filter(
            pay_date__gte=first_date, pay_date__lte=last_date
        )
        rows = []
        require_sum = 0
        insufficient_sum = 0
        for a in Account.objects.select_related('user', 'bank').order_by(
            'user__name', 'bank__name'
        ):
            require = exps.filter(method__account=a).exclude(
                state=StateChoices.DONE
            ).aggregate(Sum('amount'))['amount__sum'] or 0
            if a.balance < require:
                insufficient = require - a.balance
                is_insufficient = True
            else:
                insufficient = 0
                is_insufficient = False
            require_sum += require
            insufficient_sum += insufficient
            rows.append({
                'id': a.id,
                'user': a.user.name,
                'bank': a.bank.name,
                'balance': a.balance,
                'formed_balance': a.formed_balance(),
                'require': require,
                'formed_require': '¥{:,}'.format(require),
                'insufficient_amount': insufficient,
                'formed_insufficient': '¥{:,}'.format(insufficient),
                'is_insufficient': is_insufficient,
            })
        return Response({
            'accounts': rows,
            'require_sum': require_sum,
            'insufficient_sum': insufficient_sum,
        })


class MethodRequireAPIView(views.APIView):
    """支払方法別の必要金額(未完了支出の合計)。"""

    def get(self, request):
        year, month = _parse_year_month(request)
        first_date, last_date = _month_range(year, month)
        exps = Expense.objects.filter(
            pay_date__gte=first_date, pay_date__lte=last_date
        )
        rows = []
        require_sum = 0
        for m in Method.objects.select_related(
            'account__user', 'account__bank'
        ).order_by('account__user__name', 'name', 'account__bank__name'):
            require = exps.filter(method=m).exclude(
                state=StateChoices.DONE
            ).aggregate(Sum('amount'))['amount__sum'] or 0
            require_sum += require
            rows.append({
                'id': m.id,
                'name': m.name,
                'display_name': str(m),
                'require': require,
                'formed_require': '¥{:,}'.format(require),
            })
        return Response({
            'methods': rows,
            'require_sum': require_sum,
        })


class MethodDoneAPIView(views.APIView):
    """指定支払方法の今月の未完了支出をすべて完了にする。"""

    def post(self, request, pk):
        year, month = _parse_year_month(request)
        first_date, last_date = _month_range(year, month)
        qs = Expense.objects.filter(
            method__pk=pk,
            pay_date__gte=first_date, pay_date__lte=last_date,
        )
        updated = qs.update(state=StateChoices.DONE)
        return Response({'updated': updated})


class TrendAPIView(views.APIView):
    """月次の収入・支出推移を返す。

    Query:
      months=12 (default 12)
      end_year / end_month: 末尾の月。未指定ならクエリ時点の月。
    """

    def get(self, request):
        try:
            months = int(request.query_params.get('months', '12'))
        except (TypeError, ValueError):
            raise ValidationError('months は整数で指定してください')
        months = max(1, min(months, 36))

        end_year = request.query_params.get('end_year')
        end_month = request.query_params.get('end_month')
        if end_year and end_month:
            try:
                ey, em = int(end_year), int(end_month)
            except (TypeError, ValueError):
                raise ValidationError('end_year / end_month は整数で指定してください')
        else:
            now = timezone.now()
            ey, em = now.year, now.month

        end_first = datetime.date(ey, em, 1)
        start_first = end_first - relativedelta(months=months - 1)
        end_last = end_first + relativedelta(months=1) - datetime.timedelta(days=1)

        def _aggregate(model):
            rows = (
                model.objects
                .filter(pay_date__gte=start_first, pay_date__lte=end_last)
                .annotate(m=TruncMonth('pay_date'))
                .values('m')
                .annotate(total=Sum('amount'))
            )
            return {r['m']: r['total'] or 0 for r in rows}

        inc_map = _aggregate(Income)
        exp_map = _aggregate(Expense)

        months_data = []
        cur = start_first
        while cur <= end_first:
            months_data.append({
                'year': cur.year,
                'month': cur.month,
                'income': inc_map.get(cur, 0),
                'expense': exp_map.get(cur, 0),
            })
            cur = cur + relativedelta(months=1)

        return Response({'months': months_data})


class BalanceAPIView(views.APIView):
    """残高サマリ。口座一覧 + DB上残高(完了分) + 差額。"""

    def get(self, request):
        year, month = _parse_year_month(request)
        accounts = Account.objects.select_related('user', 'bank').order_by(
            'user__name', 'bank__name'
        )
        account_rows = []
        balance_sum = 0
        for a in accounts:
            account_rows.append({
                'id': a.id,
                'bank': a.bank.name,
                'user': a.user.name,
                'balance': a.balance,
                'formed_balance': a.formed_balance(),
            })
            balance_sum += a.balance

        balance_on_db = _get_balance_done(year, month)
        balance_diff = balance_sum - balance_on_db

        return Response({
            'year': year,
            'month': month,
            'accounts': account_rows,
            'balance_sum': balance_sum,
            'balance_on_db': balance_on_db,
            'balance_diff': balance_diff,
        })
