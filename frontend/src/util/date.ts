export const todayYearMonth = () => {
  const d = new Date()
  return { year: d.getFullYear(), month: d.getMonth() + 1 }
}

export const parseYearMonth = (y?: string, m?: string) => {
  const { year, month } = todayYearMonth()
  return {
    year: y ? Number(y) : year,
    month: m ? Number(m) : month,
  }
}
