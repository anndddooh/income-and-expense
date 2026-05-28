from django.db import models
from django.core import validators
from income_and_expense.const import const_data

# Create your models here.


class Bank(models.Model):
    name = models.CharField(max_length=50, unique=True)

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_BANK
        verbose_name_plural = const_data.const.SHOWN_NAME_BANK

    def __str__(self):
        return self.name


class User(models.Model):
    name = models.CharField(max_length=50, unique=True)

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_USER
        verbose_name_plural = const_data.const.SHOWN_NAME_USER

    def __str__(self):
        return self.name


class Account(models.Model):
    bank = models.ForeignKey(Bank, on_delete=models.PROTECT)
    user = models.ForeignKey(User, on_delete=models.PROTECT)
    balance = models.IntegerField()

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_ACCOUNT
        verbose_name_plural = const_data.const.SHOWN_NAME_ACCOUNT

        # 他レコードで同じ'bank'と'user'の組み合わせを許さない
        unique_together = ('bank', 'user')

    def __str__(self):
        return "{0}{1}".format(self.user, self.bank)

    def formed_balance(self):
        return "¥{:,}".format(self.balance)
    formed_balance.short_description = const_data.const.SHOWN_NAME_BALANCE


class Method(models.Model):
    name = models.CharField(max_length=50)
    account = models.ForeignKey(Account, on_delete=models.PROTECT)

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_METHOD
        verbose_name_plural = const_data.const.SHOWN_NAME_METHOD

    def __str__(self):
        my_str = self.name
        patterns = ['振込', '預入', '現金', '引き落とし']
        for pattern in patterns:
            if pattern in my_str:
                my_str = "{0}({1})".format(self.name, self.account)
        return my_str


class StateChoices(models.IntegerChoices):
    UNDECIDED = 0, const_data.const.SHOWN_NAME_UNDECIDED
    DECIDED = 1, const_data.const.SHOWN_NAME_DECIDED
    DONE = 2, const_data.const.SHOWN_NAME_DONE


class Expense(models.Model):
    name = models.CharField(max_length=50)
    pay_date = models.DateField('payment date')
    method = models.ForeignKey(Method, on_delete=models.PROTECT)
    amount = models.PositiveIntegerField()
    state = models.IntegerField(choices=StateChoices.choices, default=StateChoices.UNDECIDED)
    memo = models.TextField(blank=True, null=True)

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_EXPENSE
        verbose_name_plural = const_data.const.SHOWN_NAME_EXPENSE

    def __str__(self):
        return self.name

    def account_info(self):
        return self.method.account
    account_info.short_description = const_data.const.SHOWN_NAME_ACCOUNT

    def formed_amount(self):
        return "¥{:,}".format(self.amount)
    formed_amount.short_description = const_data.const.SHOWN_NAME_AMOUNT

    def state_info(self):
        return (StateChoices(self.state).label)
    state_info.short_description = const_data.const.SHOWN_NAME_STATE


class Income(models.Model):
    name = models.CharField(max_length=50)
    pay_date = models.DateField('payment date')
    method = models.ForeignKey(Method, on_delete=models.PROTECT)
    amount = models.PositiveIntegerField()
    state = models.IntegerField(choices=StateChoices.choices, default=StateChoices.UNDECIDED)
    memo = models.TextField(blank=True, null=True)

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_INCOME
        verbose_name_plural = const_data.const.SHOWN_NAME_INCOME

    def __str__(self):
        return self.name

    def account_info(self):
        return self.method.account
    account_info.short_description = const_data.const.SHOWN_NAME_ACCOUNT

    def formed_amount(self):
        return "¥{:,}".format(self.amount)
    formed_amount.short_description = const_data.const.SHOWN_NAME_AMOUNT

    def state_info(self):
        return (StateChoices(self.state).label)
    state_info.short_description = const_data.const.SHOWN_NAME_STATE


class DefaultExpense(models.Model):
    name = models.CharField(max_length=50, unique=True)
    pay_day = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(28)
    ])
    method = models.ForeignKey(Method, on_delete=models.PROTECT)
    amount = models.PositiveIntegerField()
    state = models.IntegerField(choices=StateChoices.choices, default=StateChoices.UNDECIDED)

    class Meta:
        verbose_name = (
            const_data.const.SHOWN_NAME_EXPENSE +
            const_data.const.SHOWN_NAME_DEFAULT
        )
        verbose_name_plural = (
            const_data.const.SHOWN_NAME_EXPENSE +
            const_data.const.SHOWN_NAME_DEFAULT
        )

    def __str__(self):
        return self.name

    def account_info(self):
        return self.method.account
    account_info.short_description = const_data.const.SHOWN_NAME_ACCOUNT

    def formed_amount(self):
        return "¥{:,}".format(self.amount)
    formed_amount.short_description = const_data.const.SHOWN_NAME_AMOUNT

    def state_info(self):
        return (StateChoices(self.state).label)
    state_info.short_description = const_data.const.SHOWN_NAME_STATE


class DefaultIncome(models.Model):
    name = models.CharField(max_length=50, unique=True)
    pay_day = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(28)
    ])
    method = models.ForeignKey(Method, on_delete=models.PROTECT)
    amount = models.PositiveIntegerField()
    state = models.IntegerField(choices=StateChoices.choices, default=StateChoices.UNDECIDED)

    class Meta:
        verbose_name = (
            const_data.const.SHOWN_NAME_INCOME +
            const_data.const.SHOWN_NAME_DEFAULT
        )
        verbose_name_plural = (
            const_data.const.SHOWN_NAME_INCOME +
            const_data.const.SHOWN_NAME_DEFAULT
        )

    def __str__(self):
        return self.name

    def account_info(self):
        return self.method.account
    account_info.short_description = const_data.const.SHOWN_NAME_ACCOUNT

    def formed_amount(self):
        return "¥{:,}".format(self.amount)
    formed_amount.short_description = const_data.const.SHOWN_NAME_AMOUNT

    def state_info(self):
        return (StateChoices(self.state).label)
    state_info.short_description = const_data.const.SHOWN_NAME_STATE


class DefaultExpenseMonth(models.Model):
    month = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(12)
    ])
    def_exp = models.ForeignKey(DefaultExpense, on_delete=models.CASCADE)

    class Meta:
        verbose_name = (
            const_data.const.SHOWN_NAME_EXPENSE +
            const_data.const.SHOWN_NAME_DEFAULT +
            const_data.const.SHOWN_NAME_APPLY_MONTH
        )
        verbose_name_plural = (
            const_data.const.SHOWN_NAME_EXPENSE +
            const_data.const.SHOWN_NAME_DEFAULT +
            const_data.const.SHOWN_NAME_APPLY_MONTH
        )

        unique_together = ('month', 'def_exp')

    def __str__(self):
        return "{0}({1}月)".format(self.def_exp, self.month)

    def def_exp_name(self):
        return self.def_exp
    def_exp_name.short_description = const_data.const.SHOWN_NAME_EXPENSE


class DefaultIncomeMonth(models.Model):
    month = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(12)
    ])
    def_inc = models.ForeignKey(DefaultIncome, on_delete=models.CASCADE)

    class Meta:
        verbose_name = (
            const_data.const.SHOWN_NAME_INCOME +
            const_data.const.SHOWN_NAME_DEFAULT +
            const_data.const.SHOWN_NAME_APPLY_MONTH
        )
        verbose_name_plural = (
            const_data.const.SHOWN_NAME_INCOME +
            const_data.const.SHOWN_NAME_DEFAULT +
            const_data.const.SHOWN_NAME_APPLY_MONTH
        )

        unique_together = ('month', 'def_inc')

    def __str__(self):
        return "{0}({1}月)".format(self.def_inc, self.month)

    def def_inc_name(self):
        return self.def_inc

    def_inc_name.short_description = const_data.const.SHOWN_NAME_INCOME


class TemplateExpense(models.Model):
    DATE_TYPE = (
        ('today', '即日'),
        ('later', "後日")
    )

    template_name = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=50, blank=True)
    date_type = models.CharField(max_length=10, choices=DATE_TYPE)
    pay_day = models.PositiveIntegerField(
        validators=[
            validators.MinValueValidator(1),
            validators.MaxValueValidator(28)
        ],
        null=True, blank=True
    )
    limit_day_of_this_month =  models.PositiveIntegerField(
        validators=[
            validators.MinValueValidator(1),
            validators.MaxValueValidator(28)
        ],
        null=True, blank=True
    )
    method = models.ForeignKey(Method, on_delete=models.PROTECT)
    state = models.IntegerField(choices=StateChoices.choices, default=StateChoices.UNDECIDED)

    class Meta:
        verbose_name = (
            const_data.const.SHOWN_NAME_EXPENSE +
            const_data.const.SHOWN_NAME_TEMPLATE
        )
        verbose_name_plural = (
            const_data.const.SHOWN_NAME_EXPENSE +
            const_data.const.SHOWN_NAME_TEMPLATE
        )

    def __str__(self):
        return self.template_name

    def account_info(self):
        return self.method.account
    account_info.short_description = const_data.const.SHOWN_NAME_ACCOUNT

    def state_info(self):
        return (StateChoices(self.state).label)
    state_info.short_description = const_data.const.SHOWN_NAME_STATE


class Loan(models.Model):
    name = models.CharField(max_length=50, unique=True)
    pay_day = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(28)
    ])
    first_year = models.PositiveIntegerField()
    first_month = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(12)
    ])
    last_year = models.PositiveIntegerField()
    last_month = models.PositiveIntegerField(validators=[
        validators.MinValueValidator(1),
        validators.MaxValueValidator(12)
    ])
    method = models.ForeignKey(Method, on_delete=models.PROTECT)
    amount_first = models.PositiveIntegerField()
    amount_from_second = models.PositiveIntegerField()
    state = models.IntegerField(choices=StateChoices.choices, default=StateChoices.UNDECIDED)

    class Meta:
        verbose_name = const_data.const.SHOWN_NAME_LOAN
        verbose_name_plural = const_data.const.SHOWN_NAME_LOAN

    def __str__(self):
        return self.name

    def account_info(self):
        return self.method.account
    account_info.short_description = const_data.const.SHOWN_NAME_ACCOUNT

    def formed_amount_first(self):
        return "¥{:,}".format(self.amount_first)
    formed_amount_first.short_description = (
        const_data.const.SHOWN_NAME_AMOUNT +
        const_data.const.SHOWN_NAME_FIRST
    )

    def formed_amount_from_second(self):
        return "¥{:,}".format(self.amount_from_second)
    formed_amount_from_second.short_description = (
        const_data.const.SHOWN_NAME_AMOUNT +
        const_data.const.SHOWN_NAME_FROM_SECOND
    )

    def state_info(self):
        return (StateChoices(self.state).label)
    state_info.short_description = const_data.const.SHOWN_NAME_STATE
