import { expect, test } from '@playwright/test'

// 現在の年月に依存する(APIの1か月前バリデーションを通すため)
const now = new Date()
const year = now.getFullYear()
const month = now.getMonth() + 1

test.describe('収入CRUDフロー', () => {
  test('作成→一覧確認→編集→削除', async ({ page }) => {
    const name = `E2E収入_${Date.now()}`
    const updatedName = `${name}_更新`

    await page.goto('/')
    await expect(
      page.getByRole('heading', { name: 'ダッシュボード' })
    ).toBeVisible()

    await page.goto(`/incomes/${year}/${month}`)
    await expect(page.getByRole('heading', { name: /収入一覧/ })).toBeVisible()

    // 新規作成
    await page.getByRole('button', { name: /新規作成/ }).click()
    await expect(
      page.getByRole('heading', { name: /収入を追加/ })
    ).toBeVisible()

    await page.getByLabel('名称').fill(name)
    await page.getByLabel('金額').fill('12345')
    await page.getByRole('button', { name: '追加' }).click()

    // 一覧に戻り、作成した行が見える
    await expect(page.getByRole('heading', { name: /収入一覧/ })).toBeVisible()
    const row = page.getByRole('row').filter({ hasText: name })
    await expect(row).toBeVisible()
    await expect(row).toContainText('¥12,345')

    // 編集(行クリックで編集画面へ)
    await row.click()
    await expect(
      page.getByRole('heading', { name: /収入を編集/ })
    ).toBeVisible()
    await page.getByLabel('名称').fill(updatedName)
    await page.getByLabel('金額').fill('99999')
    await page.getByRole('button', { name: '更新' }).click()

    const updatedRow = page.getByRole('row').filter({ hasText: updatedName })
    await expect(updatedRow).toBeVisible()
    await expect(updatedRow).toContainText('¥99,999')

    // 削除 (AlertDialogで確認)
    await updatedRow.getByRole('button', { name: '削除' }).click()
    await page
      .getByRole('alertdialog')
      .getByRole('button', { name: '削除' })
      .click()

    await expect(
      page.getByRole('row').filter({ hasText: updatedName })
    ).toHaveCount(0)
  })
})
