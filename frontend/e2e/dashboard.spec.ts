import { expect, test } from '@playwright/test'

test.describe('ダッシュボード', () => {
  test('KPIカードと月次推移チャートが表示される', async ({ page }) => {
    await page.goto('/')
    await expect(
      page.getByRole('heading', { name: 'ダッシュボード' })
    ).toBeVisible()

    // 4つのKPIラベルが見える
    await expect(page.getByText('今月の収入')).toBeVisible()
    await expect(page.getByText('今月の支出')).toBeVisible()
    await expect(page.getByText('口座残高合計')).toBeVisible()
    await expect(page.getByText('不足額合計')).toBeVisible()

    // 推移チャートのタイトルとSVG
    await expect(page.getByText(/月次推移/)).toBeVisible()
    // RechartsのBarChartはsvgをレンダーする
    await expect(
      page.locator('.recharts-wrapper svg').first()
    ).toBeVisible()

    // クイックアクション(収入追加リンク)
    const addIncome = page.getByRole('link', { name: /収入を追加/ })
    await expect(addIncome).toBeVisible()
  })
})
