import { Navigate, Route, Routes } from 'react-router-dom'
import { AppLayout } from './components/layout/AppLayout'
import { Home } from './pages/Home'
import { ComingSoon } from './pages/ComingSoon'
import { Search } from './pages/Search'
import { ListingDetail } from './pages/ListingDetail'
import { Dashboard } from './pages/Dashboard'
import { Login } from './pages/auth/Login'
import { Register } from './pages/auth/Register'
import { PostPropertyWizard } from './pages/PostPropertyWizard'
import { AdminLayout } from './pages/admin/AdminLayout'
import { Dashboard as AdminDashboard } from './pages/admin/Dashboard'
import { Users as AdminUsers } from './pages/admin/Users'
import { Agencies as AdminAgencies } from './pages/admin/Agencies'
import { Amenities as AdminAmenities } from './pages/admin/Amenities'
import { Ratings as AdminRatings } from './pages/admin/Ratings'
import { Banners as AdminBanners } from './pages/admin/Banners'
import { Seo as AdminSeo } from './pages/admin/Seo'
import { SeoPageEditor as AdminSeoPageEditor } from './pages/admin/SeoPageEditor'
import { PendingListings } from './pages/admin/PendingListings'
import { Reports } from './pages/admin/Reports'
import { DuplicateFlags } from './pages/admin/DuplicateFlags'
import { Verifications } from './pages/admin/Verifications'
import { Locations } from './pages/admin/Locations'
import { NeighborhoodScores } from './pages/admin/NeighborhoodScores'
import { CommunityNotesModeration } from './pages/admin/CommunityNotes'
import { Saved } from './pages/Saved'
import { Messages } from './pages/Messages'
import { ViewingRequests } from './pages/ViewingRequests'
import { VerificationCenter } from './pages/VerificationCenter'
import { RentalCalculator } from './pages/Calculators/RentalCalculator'
import { PurchaseCalculator } from './pages/Calculators/PurchaseCalculator'
import { NeighborhoodDirectory } from './pages/Neighborhoods'
import { NeighborhoodProfile } from './pages/Neighborhoods/NeighborhoodProfile'
import { MatchPreferences } from './pages/Matching/MatchPreferences'
import { MatchResults } from './pages/Matching/MatchResults'
import { PaymentHistory } from './pages/Payments/PaymentHistory'
import { Payments as AdminPayments } from './pages/admin/Payments'
import { AgentDirectory } from './pages/Agents'
import { AgencyProfile } from './pages/Agents/AgencyProfile'
import { PropertyRequests } from './pages/PropertyRequests'
import { RequireAuth } from './components/auth/RequireAuth'

export default function App() {
  return (
    <Routes>
      <Route element={<AppLayout />}>
        <Route index element={<Home />} />
        <Route path="buy" element={<Search />} />
        <Route path="rent" element={<Search />} />
        <Route path="rooms" element={<Search />} />
        <Route path="land" element={<Search />} />
        <Route path="commercial" element={<Search />} />
        <Route path="search" element={<Search />} />
        <Route path="listings/:slug" element={<ListingDetail />} />
        <Route path="neighborhoods" element={<NeighborhoodDirectory />} />
        <Route path="neighborhoods/:id" element={<NeighborhoodProfile />} />
        <Route path="agents" element={<AgentDirectory />} />
        <Route path="agents/:slug" element={<AgencyProfile />} />
        <Route path="property-requests" element={<PropertyRequests />} />
        <Route path="calculators/rental" element={<RentalCalculator />} />
        <Route path="calculators/purchase" element={<PurchaseCalculator />} />

        <Route path="login" element={<Login />} />
        <Route path="register" element={<Register />} />

        <Route
          path="saved"
          element={
            <RequireAuth>
              <Saved />
            </RequireAuth>
          }
        />
        <Route
          path="messages"
          element={
            <RequireAuth>
              <Messages />
            </RequireAuth>
          }
        />
        <Route
          path="messages/:id"
          element={
            <RequireAuth>
              <Messages />
            </RequireAuth>
          }
        />
        <Route
          path="account/viewing-requests"
          element={
            <RequireAuth>
              <ViewingRequests />
            </RequireAuth>
          }
        />
        <Route
          path="account/verification"
          element={
            <RequireAuth>
              <VerificationCenter />
            </RequireAuth>
          }
        />
        <Route
          path="account/match-preferences"
          element={
            <RequireAuth>
              <MatchPreferences />
            </RequireAuth>
          }
        />
        <Route
          path="account/match-results"
          element={
            <RequireAuth>
              <MatchResults />
            </RequireAuth>
          }
        />
        <Route
          path="account/payments"
          element={
            <RequireAuth>
              <PaymentHistory />
            </RequireAuth>
          }
        />
        <Route
          path="dashboard"
          element={
            <RequireAuth>
              <Dashboard />
            </RequireAuth>
          }
        />
        <Route
          path="post-property"
          element={
            <RequireAuth>
              <PostPropertyWizard />
            </RequireAuth>
          }
        />

        <Route path="*" element={<ComingSoon title="Page not found" />} />
      </Route>

      {/* Admin console has its own dedicated layout — no public header/footer. */}
      <Route
        path="admin"
        element={
          <RequireAuth adminOnly>
            <AdminLayout />
          </RequireAuth>
        }
      >
        <Route index element={<Navigate to="dashboard" replace />} />
        <Route path="dashboard" element={<AdminDashboard />} />
        <Route path="banners" element={<AdminBanners />} />
        <Route path="users" element={<AdminUsers />} />
        <Route path="agencies" element={<AdminAgencies />} />
        <Route path="listings/pending" element={<PendingListings />} />
        <Route path="reports" element={<Reports />} />
        <Route path="duplicate-flags" element={<DuplicateFlags />} />
        <Route path="verifications" element={<Verifications />} />
        <Route path="locations" element={<Locations />} />
        <Route path="neighborhoods" element={<NeighborhoodScores />} />
        <Route path="amenities" element={<AdminAmenities />} />
        <Route path="community-notes" element={<CommunityNotesModeration />} />
        <Route path="ratings" element={<AdminRatings />} />
        <Route path="payments" element={<AdminPayments />} />
        <Route path="seo" element={<AdminSeo />} />
        <Route path="seo/:key" element={<AdminSeoPageEditor />} />
      </Route>
    </Routes>
  )
}
