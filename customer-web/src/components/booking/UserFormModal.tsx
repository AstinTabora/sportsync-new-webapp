import { useState } from "react";
import Modal from "../ui/Modal";
import Button from "../ui/Button";
import { useBookingFlow } from "../../state/BookingFlowContext";
import { useAuth } from "../../state/AuthContext";

interface Props {
  open: boolean;
  onClose: () => void;
  onSubmit: () => void;
}

// "Your details" capture before payment.
export default function UserFormModal({ open, onClose, onSubmit }: Props) {
  const flow = useBookingFlow();
  const auth = useAuth();
  const [name, setName] = useState(flow.details.name || (auth.signedIn ? auth.profile.displayName : ""));
  const [email, setEmail] = useState(flow.details.email || auth.profile.email);
  const [phone, setPhone] = useState(flow.details.phone || auth.profile.phone);

  const valid = name.trim() && email.trim() && phone.trim();

  function submit() {
    if (!valid) return;
    flow.setDetails({ name, email, phone });
    onSubmit();
  }

  return (
    <Modal open={open} onClose={onClose} title="YOUR DETAILS" maxWidth="max-w-md">
      <p className="t-body-bold -mt-2 mb-4 text-slate-400">
        We'll send your booking confirmation here.
      </p>
      <div className="space-y-3">
        <Field label="Full name" value={name} onChange={setName} placeholder="Juan dela Cruz" />
        <Field label="Email" value={email} onChange={setEmail} placeholder="you@example.com" type="email" />
        <Field label="Phone" value={phone} onChange={setPhone} placeholder="+63 9XX XXX XXXX" type="tel" />
      </div>
      <Button full className="mt-5" disabled={!valid} onClick={submit}>
        Continue to Payment
      </Button>
    </Modal>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
}) {
  return (
    <label className="block">
      <span className="t-micro text-slate-500">{label}</span>
      <input
        type={type}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="mt-1.5 w-full rounded-md border border-slate-200 bg-slate-50 px-3 py-3 text-[14px] font-semibold text-slate-700 outline-none transition focus:border-primary/40 focus:bg-white"
      />
    </label>
  );
}
