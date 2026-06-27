import { Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./state/AuthContext";
import { BookingsProvider } from "./state/BookingsContext";
import { BookingFlowProvider } from "./state/BookingFlowContext";
import { OnboardingProvider } from "./state/OnboardingContext";
import AppShell from "./components/layout/AppShell";
import HomePage from "./pages/HomePage";
import RecommendationsPage from "./pages/RecommendationsPage";
import CourtDetailPage from "./pages/CourtDetailPage";
import BookingPage from "./pages/BookingPage";
import MyBookingsPage from "./pages/MyBookingsPage";
import ProfilePage from "./pages/ProfilePage";
import EditProfilePage from "./pages/EditProfilePage";
import AccountPage from "./pages/AccountPage";
import AboutPage from "./pages/AboutPage";

export default function App() {
  return (
    <AuthProvider>
      <BookingsProvider>
        <OnboardingProvider>
          <BookingFlowProvider>
            <Routes>
              <Route element={<AppShell />}>
                <Route index element={<Navigate to="/home" replace />} />
                <Route path="/home" element={<HomePage />} />
                <Route path="/home/recommendations" element={<RecommendationsPage />} />
                <Route path="/courts/:id" element={<CourtDetailPage />} />
                <Route path="/courts/:id/book" element={<BookingPage />} />
                <Route path="/bookings" element={<MyBookingsPage />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/profile/edit" element={<EditProfilePage />} />
                <Route path="/profile/account" element={<AccountPage />} />
                <Route path="/profile/about" element={<AboutPage />} />
              </Route>
              <Route path="*" element={<Navigate to="/home" replace />} />
            </Routes>
          </BookingFlowProvider>
        </OnboardingProvider>
      </BookingsProvider>
    </AuthProvider>
  );
}
