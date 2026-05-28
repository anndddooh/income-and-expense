import { expect, test } from '@playwright/test'

const now = new Date()
const year = now.getFullYear()
const month = now.getMonth() + 1

test.describe('サイドバーナビゲーション', () => {
  test('各機能ページへ遷移できる', async ({ page }) => {
    await page.goto('/')
    await expect(
      page.getByRole('heading', { name: 'ダッシュボード' })
    ).toBeVisible()

    const checks: { link: string; heading: string | RegExp }[] = [
      { link: '収入', heading: /収入一覧/ },
      { link: '支出', heading: /支出一覧/ },
      { link: '残高', heading: '残高' },
      { link: 'ローン', heading: /ローン一覧/ },
      { link: '口座別必要額', heading: '口座別必要金額' },
      { link: '支払方法別必要額', heading: '支払方法別必要金額' },
    ]

    for (const c of checks) {
      await page.goto('/')
      await page
        .getByRole('link', { name: c.link, exact: true })
        .first()
        .click()
      await expect(page.getByRole('heading', { name: c.heading })).toBeVisible()
    }
  })

  test('ヘッダーの前月→次月で年月が変わる', async ({ page }) => {
    await page.goto(`/incomes/${year}/${month}`)
    await expect(page.getByText(`${year}年${month}月`).first()).toBeVisible()

    await page.getByRole('button', { name: /前月/ }).click()
    const prevMonth = month === 1 ? 12 : month - 1
    const prevYear = month === 1 ? year - 1 : year
    await expect(
      page.getByText(`${prevYear}年${prevMonth}月`).first()
    ).toBeVisible()

    await page.getByRole('button', { name: /次月/ }).click()
    await expect(page.getByText(`${year}年${month}月`).first()).toBeVisible()
  })
})
