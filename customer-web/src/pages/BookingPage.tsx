import { useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { courtById } from "../data/courts";
import { useBookingFlow } from "../state/BookingFlowContext";
import CalendarView from "../components/booking/CalendarView";
import PaymentView from "../components/booking/PaymentView";
import ConfirmationView from "../components/booking/ConfirmationView";

// Orchestrates the multi-step booking flow off the shared BookingFlow state.
export default function BookingPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const flow = useBookingFlow();
  const court = courtById(id);

  // If the user deep-links straight here (no flow set up yet), initialise it.
  useEffect(() => {
    if (court && flow.court?.id !== court.id) {
      flow.reset(court);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [court?.id]);

  if (!court) {
    return (
      <div className="grid min-h-screen place-items-center px-6 text-center">
        <div>
          <p className="t-page-title">No court selected</p>
          <button
            onClick={() => navigate("/home")}
            className="mt-3 text-[11px] font-black uppercase tracking-wider text-primary"
          >
            Go to Home
          </button>
        </div>
      </div>
    );
  }

  // Guard against rendering a step before reset() has swapped in this court.
  if (flow.court?.id !== court.id) return null;

  if (flow.step === "payment") return <PaymentView />;
  if (flow.step === "confirmation") return <ConfirmationView />;
  return <CalendarView />;
}
