import { Outlet } from 'react-router-dom'
import { Header } from './Header'
import { Footer } from './Footer'
import { InstallAppPrompt } from './InstallAppPrompt'
import { PageBackdrop } from './PageBackdrop'

export function AppLayout() {
  return (
    <div className="flex min-h-screen flex-col">
      <PageBackdrop />
      <Header />
      <main className="mx-auto w-full max-w-[1440px] flex-1 px-4 py-6 sm:px-6 lg:px-10">
        <Outlet />
      </main>
      <Footer />
      <InstallAppPrompt />
    </div>
  )
}
