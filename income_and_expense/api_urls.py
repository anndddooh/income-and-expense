from django.urls import include, path
from rest_framework.routers import DefaultRouter

from income_and_expense import api_views

app_name = 'api'

router = DefaultRouter()
router.register(r'incomes', api_views.IncomeViewSet, basename='income')
router.register(r'expenses', api_views.ExpenseViewSet, basename='expense')
router.register(r'accounts', api_views.AccountViewSet, basename='account')
router.register(r'loans', api_views.LoanViewSet, basename='loan')
router.register(
    r'default_incomes',
    api_views.DefaultIncomeViewSet,
    basename='default-income',
)
router.register(
    r'default_expenses',
    api_views.DefaultExpenseViewSet,
    basename='default-expense',
)

urlpatterns = [
    path('', include(router.urls)),
    path('methods/', api_views.MethodListAPIView.as_view(), name='method-list'),
    path(
        'template_expenses/',
        api_views.TemplateExpenseListAPIView.as_view(),
        name='template-expense-list',
    ),
    path(
        'methods/<int:pk>/done/',
        api_views.MethodDoneAPIView.as_view(),
        name='method-done',
    ),
    path('balance/', api_views.BalanceAPIView.as_view(), name='balance'),
    path('trends/', api_views.TrendAPIView.as_view(), name='trends'),
    path(
        'account_require/',
        api_views.AccountRequireAPIView.as_view(),
        name='account-require',
    ),
    path(
        'method_require/',
        api_views.MethodRequireAPIView.as_view(),
        name='method-require',
    ),
]
