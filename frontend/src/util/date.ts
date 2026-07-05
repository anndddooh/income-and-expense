export const todayYearMonth = () => {
  const d = new Date()
  return { year: d.getFullYear(), month: d.getMonth() + 1 }
}

/** ISO 日付("YYYY-MM-DD"等)から「27日」表記を返す。 */
export const dayOf = (isoDate: string): string => {
  const parts = isoDate.split('-')
  const day = Number(parts[2] ?? parts[parts.length - 1])
  return Number.isFinite(day) ? `${day}日` : isoDate
}

export const parseYearMonth = (y?: string, m?: string) => {
  const { year, month } = todayYearMonth()
  return {
    year: y ? Number(y) : year,
    month: m ? Number(m) : month,
  }
}
