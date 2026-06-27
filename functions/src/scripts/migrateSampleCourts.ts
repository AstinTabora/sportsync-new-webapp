/**
 * One-time migration: port the 5 hardcoded courts from
 * lib/features/home/data/sample_courts.dart into Firestore under
 * ownerId='seed'. Run via:
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=service-account.json \
 *     npm run build && node lib/scripts/migrateSampleCourts.js
 *
 * Re-running is safe: courts upsert by id, schedules upsert by day.
 */
import { initializeApp, getApps } from "firebase-admin/app";
import { firestore } from "firebase-admin";
import { CourtDoc, ScheduleSlot, DAYS_OF_WEEK } from "../domain/courts";

if (getApps().length === 0) initializeApp();

const SEED_OWNER_ID = "seed";

interface SeedCourt extends Omit<CourtDoc, "createdAt" | "updatedAt"> {
  id: string;
}

const SEED_COURTS: SeedCourt[] = [
  {
    id: "c1",
    ownerId: SEED_OWNER_ID,
    name: "Smash Ville Fitness Center",
    type: "badminton",
    image: "assets/images/SMASHVILLE.png",
    price: 350,
    rating: 4.8,
    location: "31 T.Monteverde St, Poblacion District, Davao City",
    amenities: ["Locker Rooms", "Pro Shop", "Cafe"],
    description:
      "Premier indoor badminton facility with professional-grade flooring and lighting.",
    phone: "+63 82 221 1234",
    email: "contact@smashville.ph",
    numberOfCourts: 12,
    latitude: 7.0738,
    longitude: 125.6206,
    mapUrl:
      "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3959.4487355590404!2d125.6206634745354!3d7.073858392928862!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x32f96d9652d3e113%3A0x5279cba81601055f!2sSmash%20Ville%20Fitness%20Center!5e0!3m2!1sen!2sph!4v1772108882457!5m2!1sen!2sph",
    published: true,
  },
  {
    id: "c2",
    ownerId: SEED_OWNER_ID,
    name: "MTS Pickleball Courts",
    type: "pickleball",
    image: "assets/images/MTS.png",
    price: 300,
    rating: 4.6,
    location: "Matina Town Square, Talomo, Davao City",
    amenities: ["Equipment Rental", "Water Station"],
    description:
      "Modern pickleball courts with a vibrant community atmosphere.",
    phone: "+63 82 297 5678",
    email: "play@thepickleloft.ph",
    numberOfCourts: 6,
    latitude: 7.0644,
    longitude: 125.5967,
    mapUrl:
      "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d494.9412219687384!2d125.59673685266986!3d7.0644019234539295!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x32f96d6362c41db1%3A0xcb1e8b779d4d959a!2sUniversity%20of%20Mindanao%20Dr%2C%20Talomo%2C%20Davao%20City%2C%20Davao%20del%20Sur!5e0!3m2!1sen!2sph!4v1772108188373!5m2!1sen!2sph",
    published: true,
  },
  {
    id: "c3",
    ownerId: SEED_OWNER_ID,
    name: "Evergold Recreation Center",
    type: "basketball",
    image: "assets/images/EVERGOLD.png",
    price: 400,
    rating: 4.9,
    location: "Iñigo St, Obrero, Davao City",
    amenities: ["Showers", "Bleachers", "Scoreboard"],
    description:
      "Full-sized hardwood basketball court perfect for team practice and pickup games.",
    phone: "+63 82 225 9012",
    email: "info@evergold.ph",
    numberOfCourts: 2,
    latitude: 7.0875,
    longitude: 125.6137,
    mapUrl:
      "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3959.331490054907!2d125.61374897453554!3d7.087517392915517!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x32f96daf20097833%3A0x8d4139b09a4432b8!2sEvergold%20Recreation%20Center!5e0!3m2!1sen!2sph!4v1772109577059!5m2!1sen!2sph",
    published: true,
  },
  {
    id: "c4",
    ownerId: SEED_OWNER_ID,
    name: "Badminton World",
    type: "badminton",
    image: "assets/images/BADMINTONWORLD.png",
    price: 350,
    rating: 4.7,
    location: "Avanceña St, Poblacion District, Davao City",
    amenities: ["Coach Available", "Parking"],
    description:
      "Elite training center specializing in badminton player development.",
    phone: "+63 82 224 3456",
    email: "hello@badmintonworld.ph",
    numberOfCourts: 10,
    latitude: 7.0771,
    longitude: 125.6032,
    mapUrl:
      "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3959.420188699609!2d125.60329407453548!3d7.077186492925669!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x32f96d74cb88e44b%3A0xc2f9df780221f68d!2sBadminton%20World!5e0!3m2!1sen!2sph!4v1772109325225!5m2!1sen!2sph",
    published: true,
  },
  {
    id: "c5",
    ownerId: SEED_OWNER_ID,
    name: "Crisron Pickle Ball Court",
    type: "pickleball",
    image: "assets/images/CRISRON.png",
    price: 250,
    rating: 4.5,
    location: "168 Don Julian Rodriguez Sr. Ave, Talomo, Davao City",
    amenities: ["Benches", "Night Lighting"],
    description:
      "Affordable outdoor courts with excellent night lighting and a friendly neighborhood vibe.",
    phone: "+63 82 298 7890",
    email: "support@crisron.ph",
    numberOfCourts: 8,
    latitude: 7.0993,
    longitude: 125.5787,
    mapUrl:
      "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3959.2301273042276!2d125.57871967453565!3d7.099304992903959!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x32f96d005d6cb097%3A0x8302b886d65d3949!2sCrisron%20pickle%20ball%20court%20(8%20court)!5e0!3m2!1sen!2sph!4v1772108501569!5m2!1sen!2sph",
    published: true,
  },
];

// Default schedule: 06:00 – 22:00, 1-hour slots, every day. Mirrors the
// current mobile-app booking grid so behaviour doesn't change post-migration.
function defaultSlots(price: number): ScheduleSlot[] {
  const out: ScheduleSlot[] = [];
  for (let hour = 6; hour < 22; hour++) {
    const time = `${String(hour).padStart(2, "0")}:00`;
    out.push({ time, durationMins: 60, price, courtNumbers: [] });
  }
  return out;
}

async function run(): Promise<void> {
  const db = firestore();
  const batch = db.batch();

  for (const court of SEED_COURTS) {
    const ref = db.collection("courts").doc(court.id);
    const { id: _id, ...data } = court;
    batch.set(
      ref,
      {
        ...data,
        createdAt: firestore.FieldValue.serverTimestamp(),
        updatedAt: firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    for (const day of DAYS_OF_WEEK) {
      const scheduleRef = ref.collection("schedule").doc(day);
      batch.set(
        scheduleRef,
        {
          active: true,
          slots: defaultSlots(court.price),
          updatedAt: firestore.FieldValue.serverTimestamp(),
          updatedBy: "migration-script",
        },
        { merge: true }
      );
    }
  }

  await batch.commit();
  console.log(`Migrated ${SEED_COURTS.length} courts to Firestore.`);
}

run().catch((e) => {
  console.error("Migration failed:", e);
  process.exit(1);
});
