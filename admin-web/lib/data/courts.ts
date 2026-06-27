import { z } from "zod";

export type CourtType = "badminton" | "pickleball" | "basketball";

export const courtTypes: CourtType[] = [
  "badminton",
  "pickleball",
  "basketball",
];

export const courtSchema = z.object({
  name: z.string().min(2, "Name is required"),
  type: z.enum(["badminton", "pickleball", "basketball"]),
  location: z.string().min(3, "Location is required"),
  price: z.coerce.number().min(0, "Price must be non-negative"),
  rating: z.coerce
    .number()
    .min(0, "Rating must be 0–5")
    .max(5, "Rating must be 0–5"),
  numberOfCourts: z.coerce.number().int().min(1, "Must have at least 1 court"),
  amenities: z.string().optional(), // comma-separated in the form
  image: z.string().optional(), // cover = images[0]
  images: z.array(z.string()).optional(), // ordered gallery, up to 5
  description: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional().or(z.literal("")),
  // Plain string (not strict URL): we normalize/extract the embed src in the
  // form and only warn — never block — if it isn't an embed link.
  mapUrl: z.string().optional(),
  published: z.boolean(),
});

export type CourtFormValues = z.infer<typeof courtSchema>;

export interface CourtDoc extends Omit<CourtFormValues, "amenities"> {
  ownerId: string;
  amenities: string[];
}

export function amenitiesToArray(input: string | undefined): string[] {
  if (!input) return [];
  return input
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

export function amenitiesToString(input: string[] | undefined): string {
  return (input ?? []).join(", ");
}
