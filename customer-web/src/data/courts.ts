import type { Court, SportType } from "./types";

// The 5 seed courts — ported verbatim from
// functions/src/scripts/migrateSampleCourts.ts. Images point at /public/images.
export const COURTS: Court[] = [
  {
    id: "c1",
    name: "Smash Ville Fitness Center",
    type: "badminton",
    image: "/images/SMASHVILLE.png",
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
    name: "MTS Pickleball Courts",
    type: "pickleball",
    image: "/images/MTS.png",
    price: 300,
    rating: 4.6,
    location: "Matina Town Square, Talomo, Davao City",
    amenities: ["Equipment Rental", "Water Station"],
    description: "Modern pickleball courts with a vibrant community atmosphere.",
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
    name: "Evergold Recreation Center",
    type: "basketball",
    image: "/images/EVERGOLD.png",
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
    name: "Badminton World",
    type: "badminton",
    image: "/images/BADMINTONWORLD.png",
    price: 350,
    rating: 4.7,
    location: "Avanceña St, Poblacion District, Davao City",
    amenities: ["Coach Available", "Parking"],
    description: "Elite training center specializing in badminton player development.",
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
    name: "Crisron Pickle Ball Court",
    type: "pickleball",
    image: "/images/CRISRON.png",
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

export function courtById(id: string | undefined): Court | undefined {
  return COURTS.find((c) => c.id === id);
}

export const SPORT_LABELS: Record<SportType, string> = {
  badminton: "Badminton",
  pickleball: "Pickleball",
  basketball: "Basketball",
};
