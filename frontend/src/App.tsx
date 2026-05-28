import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import AppLayout from '@/components/AppLayout'
import ProtectedRoute from '@/components/ProtectedRoute'
import { Toaster } from '@/components/ui/sonner'
import { TooltipProvider } from '@/components/ui/tooltip'
import AccountRequire from '@/pages/AccountRequire'
import Balance from '@/pages/Balance'
import Dashboard from '@/pages/Dashboard'
import DefaultExpenseForm from '@/pages/DefaultExpenseForm'
import DefaultExpenseList from '@/pages/DefaultExpenseList'
import DefaultIncomeForm from '@/pages/DefaultIncomeForm'
import DefaultIncomeList from '@/pages/DefaultIncomeList'
import ExpenseForm from '@/pages/ExpenseForm'
import ExpenseList from '@/pages/ExpenseList'
import IncomeForm from '@/pages/IncomeForm'
import IncomeList from '@/pages/IncomeList'
import LoanForm from '@/pages/LoanForm'
import LoanList from '@/pages/LoanList'
import Login from '@/pages/Login'
import MethodRequire from '@/pages/MethodRequire'
import Settings from '@/pages/Settings'

const queryClient = new QueryClient()

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route path="/" element={<Dashboard />} />
              <Route path="/dashboard/:year/:month" element={<Dashboard />} />
              <Route path="/incomes/:year/:month" element={<IncomeList />} />
              <Route path="/incomes/:year/:month/new" element={<IncomeForm />} />
              <Route
                path="/incomes/:year/:month/:id/edit"
                element={<IncomeForm />}
              />
              <Route path="/expenses/:year/:month" element={<ExpenseList />} />
              <Route path="/expenses/:year/:month/new" element={<ExpenseForm />} />
              <Route
                path="/expenses/:year/:month/:id/edit"
                element={<ExpenseForm />}
              />
              <Route path="/balance/:year/:month" element={<Balance />} />
              <Route path="/loans/:year/:month" element={<LoanList />} />
              <Route path="/loans/:year/:month/new" element={<LoanForm />} />
              <Route path="/loans/:year/:month/:id/edit" element={<LoanForm />} />
              <Route
                path="/account_require/:year/:month"
                element={<AccountRequire />}
              />
              <Route
                path="/method_require/:year/:month"
                element={<MethodRequire />}
              />
              <Route path="/settings" element={<Settings />} />
              <Route
                path="/settings/default-incomes"
                element={<DefaultIncomeList />}
              />
              <Route
                path="/settings/default-incomes/new"
                element={<DefaultIncomeForm />}
              />
              <Route
                path="/settings/default-incomes/:id/edit"
                element={<DefaultIncomeForm />}
              />
              <Route
                path="/settings/default-expenses"
                element={<DefaultExpenseList />}
              />
              <Route
                path="/settings/default-expenses/new"
                element={<DefaultExpenseForm />}
              />
              <Route
                path="/settings/default-expenses/:id/edit"
                element={<DefaultExpenseForm />}
              />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
      <Toaster richColors position="top-right" />
      </TooltipProvider>
    </QueryClientProvider>
  )
}
