"use client";

import { useState } from "react";
import { useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  ref as storageRef,
  uploadBytesResumable,
  getDownloadURL,
} from "firebase/storage";
import { X, Plus } from "lucide-react";
import { storage } from "@/lib/firebase/client";
import {
  courtSchema,
  CourtFormValues,
  courtTypes,
  amenitiesToString,
} from "@/lib/data/courts";
import { Input } from "./ui/Input";
import { Label } from "./ui/Label";
import { Select } from "./ui/Select";
import { Textarea } from "./ui/Textarea";
import { Button } from "./ui/Button";
import { Card, CardContent } from "./ui/Card";
import { CourtCardPreview, CourtDetailPreview } from "./CourtPreview";

interface Props {
  ownerId: string;
  courtId: string;
  initial?: Partial<CourtFormValues>;
  initialAmenities?: string[];
  submitLabel?: string;
  onSubmit: (values: CourtFormValues) => Promise<void>;
}

interface Attachment {
  id: string;
  name: string;
  url?: string;
  progress: number;
}

const MAX_IMAGE_BYTES = 5 * 1024 * 1024; // 5MB, matches storage.rules
const MAX_IMAGES = 5;

export function CourtForm({
  ownerId,
  courtId,
  initial,
  initialAmenities,
  submitLabel = "Save",
  onSubmit,
}: Props) {
  const [attachments, setAttachments] = useState<Attachment[]>(() => {
    const init =
      initial?.images && initial.images.length
        ? initial.images
        : initial?.image
        ? [initial.image]
        : [];
    return init.map((url, i) => ({
      id: `init-${i}`,
      name: `Image ${i + 1}`,
      url,
      progress: 100,
    }));
  });
  const [error, setError] = useState<string | null>(null);

  const images = attachments
    .filter((a) => a.url)
    .map((a) => a.url as string);
  const uploading = attachments.some((a) => !a.url);

  const {
    register,
    handleSubmit,
    control,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<CourtFormValues>({
    resolver: zodResolver(courtSchema),
    defaultValues: {
      name: initial?.name ?? "",
      type: initial?.type ?? "badminton",
      location: initial?.location ?? "",
      price: initial?.price ?? 300,
      rating: initial?.rating ?? 4.5,
      numberOfCourts: initial?.numberOfCourts ?? 1,
      amenities: amenitiesToString(initialAmenities ?? []),
      image: initial?.image ?? "",
      description: initial?.description ?? "",
      phone: initial?.phone ?? "",
      email: initial?.email ?? "",
      mapUrl: initial?.mapUrl ?? "",
      published: initial?.published ?? false,
    },
  });

  const watched = useWatch({ control });
  const watchedMapUrl = (watched.mapUrl ?? "").trim();
  const mapWarning =
    watchedMapUrl && !watchedMapUrl.includes("/maps/embed")
      ? "This isn't a Maps embed link, so it won't show on the app. Use Share → “Embed a map” and paste the link inside src=“…”."
      : null;

  function onFilesChange(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    e.target.value = ""; // allow re-picking the same file later
    if (!files.length) return;
    setError(null);

    const remaining = MAX_IMAGES - attachments.length;
    if (remaining <= 0) {
      setError(`You can upload up to ${MAX_IMAGES} images.`);
      return;
    }
    const toUpload = files.slice(0, remaining);
    if (files.length > remaining) {
      setError(`Only ${remaining} more image(s) allowed (max ${MAX_IMAGES}).`);
    }

    for (const file of toUpload) {
      if (!file.type.startsWith("image/")) {
        setError("Please choose image files only.");
        continue;
      }
      if (file.size > MAX_IMAGE_BYTES) {
        setError(`${file.name} is over 5MB.`);
        continue;
      }
      const id = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
      setAttachments((prev) => [...prev, { id, name: file.name, progress: 0 }]);

      const path = `courts/${courtId}/img-${Date.now()}-${file.name}`;
      const task = uploadBytesResumable(storageRef(storage, path), file, {
        contentType: file.type,
      });
      task.on(
        "state_changed",
        (snap) => {
          const pct = Math.round(
            (snap.bytesTransferred / snap.totalBytes) * 100
          );
          setAttachments((prev) =>
            prev.map((a) => (a.id === id ? { ...a, progress: pct } : a))
          );
        },
        (err) => {
          setError(`Upload failed: ${err.message}`);
          setAttachments((prev) => prev.filter((a) => a.id !== id));
        },
        async () => {
          try {
            const url = await getDownloadURL(task.snapshot.ref);
            setAttachments((prev) =>
              prev.map((a) => (a.id === id ? { ...a, url, progress: 100 } : a))
            );
          } catch (err) {
            setError(`Could not get image URL: ${(err as Error).message}`);
            setAttachments((prev) => prev.filter((a) => a.id !== id));
          }
        }
      );
    }
  }

  function removeImage(id: string) {
    setAttachments((prev) => prev.filter((a) => a.id !== id));
  }

  function setAsCover(id: string) {
    setAttachments((prev) => {
      const idx = prev.findIndex((a) => a.id === id);
      if (idx <= 0) return prev;
      const copy = [...prev];
      const [item] = copy.splice(idx, 1);
      copy.unshift(item);
      return copy;
    });
  }

  function normalizeMapUrl(raw: string): string {
    const match = raw.match(/src=["']([^"']+)["']/i);
    return (match ? match[1] : raw).trim();
  }

  async function inner(values: CourtFormValues) {
    setError(null);
    if (uploading) {
      setError("Please wait for images to finish uploading.");
      return;
    }
    try {
      await onSubmit({ ...values, image: images[0] ?? "", images });
    } catch (err) {
      setError((err as Error).message);
    }
  }

  return (
    <div className="flex flex-col gap-8 xl:flex-row xl:items-start">
      <form
        onSubmit={handleSubmit(inner)}
        className="w-full space-y-6 xl:max-w-2xl"
      >
        <Card>
          <CardContent className="space-y-4 pt-6">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <Label htmlFor="name">Court name</Label>
                <Input id="name" {...register("name")} />
                {errors.name && (
                  <p className="mt-1 text-xs text-red-600">{errors.name.message}</p>
                )}
              </div>
              <div>
                <Label htmlFor="type">Sport</Label>
                <Select id="type" {...register("type")}>
                  {courtTypes.map((t) => (
                    <option key={t} value={t}>
                      {t.charAt(0).toUpperCase() + t.slice(1)}
                    </option>
                  ))}
                </Select>
              </div>
            </div>

            <div>
              <Label htmlFor="location">Location</Label>
              <Input id="location" {...register("location")} />
              {errors.location && (
                <p className="mt-1 text-xs text-red-600">
                  {errors.location.message}
                </p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
              <div>
                <Label htmlFor="price">Default price (₱)</Label>
                <Input id="price" type="number" step="1" {...register("price")} />
                {errors.price && (
                  <p className="mt-1 text-xs text-red-600">
                    {errors.price.message}
                  </p>
                )}
              </div>
              <div>
                <Label htmlFor="numberOfCourts"># of courts</Label>
                <Input
                  id="numberOfCourts"
                  type="number"
                  step="1"
                  {...register("numberOfCourts")}
                />
                {errors.numberOfCourts && (
                  <p className="mt-1 text-xs text-red-600">
                    {errors.numberOfCourts.message}
                  </p>
                )}
              </div>
              <div>
                <Label htmlFor="rating">Rating (0–5)</Label>
                <Input
                  id="rating"
                  type="number"
                  step="0.1"
                  {...register("rating")}
                />
              </div>
              <div className="flex items-end gap-2">
                <input
                  id="published"
                  type="checkbox"
                  className="h-4 w-4"
                  {...register("published")}
                />
                <Label htmlFor="published" className="mb-0">
                  Published
                </Label>
              </div>
            </div>

            <div>
              <Label htmlFor="amenities">Amenities (comma-separated)</Label>
              <Input
                id="amenities"
                placeholder="Locker Rooms, Pro Shop, Cafe"
                {...register("amenities")}
              />
            </div>

            <div>
              <Label htmlFor="description">Description</Label>
              <Textarea id="description" rows={3} {...register("description")} />
            </div>

            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <Label htmlFor="phone">Contact phone</Label>
                <Input id="phone" {...register("phone")} />
              </div>
              <div>
                <Label htmlFor="email">Contact email</Label>
                <Input id="email" type="email" {...register("email")} />
                {errors.email && (
                  <p className="mt-1 text-xs text-red-600">
                    {errors.email.message}
                  </p>
                )}
              </div>
            </div>

            <div>
              <Label htmlFor="mapUrl">Google Maps embed link</Label>
              <Input
                id="mapUrl"
                placeholder="https://www.google.com/maps/embed?pb=…"
                {...register("mapUrl", {
                  onChange: (e) => {
                    const normalized = normalizeMapUrl(e.target.value);
                    if (normalized !== e.target.value) {
                      setValue("mapUrl", normalized, { shouldDirty: true });
                    }
                  },
                })}
              />
              <p className="mt-1 text-xs text-slate-500">
                In Google Maps: <strong>Share → Embed a map → COPY HTML</strong>,
                then paste it here (we&apos;ll keep just the link). A plain share
                link won&apos;t display on the app.
              </p>
              {mapWarning && (
                <p className="mt-1 text-xs text-amber-700">{mapWarning}</p>
              )}
            </div>

            {/* Images */}
            <div>
              <Label>
                Cover &amp; gallery images{" "}
                <span className="font-normal text-slate-400">
                  (up to {MAX_IMAGES}, first is the cover)
                </span>
              </Label>
              <div className="flex flex-wrap gap-3">
                {attachments.map((a, i) => (
                  <div
                    key={a.id}
                    className="group relative h-24 w-28 overflow-hidden rounded-lg border border-slate-200 bg-slate-50"
                  >
                    {a.url ? (
                      /* eslint-disable-next-line @next/next/no-img-element */
                      <img
                        src={a.url}
                        alt={a.name}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-full w-full flex-col items-center justify-center gap-1 px-1 text-center text-xs text-slate-400">
                        <span className="font-semibold text-slate-600">
                          {a.progress}%
                        </span>
                        <span className="max-w-[88px] truncate">{a.name}</span>
                      </div>
                    )}
                    <button
                      type="button"
                      onClick={() => removeImage(a.id)}
                      className="absolute right-1 top-1 flex h-5 w-5 items-center justify-center rounded-full bg-slate-900/70 text-white hover:bg-slate-900"
                      title="Remove"
                    >
                      <X size={12} />
                    </button>
                    {i === 0 ? (
                      <span className="absolute bottom-1 left-1 rounded bg-brand-600 px-1.5 py-0.5 text-[9px] font-bold text-white">
                        COVER
                      </span>
                    ) : a.url ? (
                      <button
                        type="button"
                        onClick={() => setAsCover(a.id)}
                        className="absolute bottom-1 left-1 rounded bg-white/90 px-1.5 py-0.5 text-[9px] font-semibold text-slate-700 opacity-0 transition-opacity hover:bg-white group-hover:opacity-100"
                        title="Set as cover"
                      >
                        Set cover
                      </button>
                    ) : null}
                  </div>
                ))}

                {attachments.length < MAX_IMAGES && (
                  <label className="flex h-24 w-28 cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border-2 border-dashed border-slate-300 text-slate-400 hover:border-brand-400 hover:text-brand-600">
                    <Plus size={18} />
                    <span className="text-xs">Add image</span>
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      className="hidden"
                      onChange={onFilesChange}
                    />
                  </label>
                )}
              </div>
              <p className="mt-1 text-xs text-slate-500">JPG/PNG, up to 5MB each.</p>
            </div>
          </CardContent>
        </Card>

        {error && (
          <div className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-600">
            {error}
          </div>
        )}

        <div className="flex gap-3">
          <Button type="submit" disabled={isSubmitting || uploading}>
            {isSubmitting ? "Saving…" : submitLabel}
          </Button>
          <input type="hidden" value={ownerId} readOnly />
        </div>
      </form>

      <aside className="hidden flex-1 xl:block">
        <div className="sticky top-6 flex flex-col items-center gap-4">
          <span className="text-xs font-medium uppercase tracking-widest text-slate-400">
            Live app preview
          </span>
          <div className="flex flex-wrap items-start justify-center gap-6">
            <CourtCardPreview values={watched} images={images} />
            <CourtDetailPreview values={watched} images={images} />
          </div>
        </div>
      </aside>
    </div>
  );
}
