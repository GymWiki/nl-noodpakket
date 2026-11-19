/**
 * Eén bron voor de tekst die op meerdere plekken terugkomt: homepage, llms.txt en structured data.
 * Houd dit gelijk aan de store-listings (App Store en Google Play) en de README. Definitiezin en naam: site.ts.
 */
import { FEATURES } from "./site";

export type Tint = "blue" | "teal" | "sand" | "pink" | "indigo" | "green";

export const AUDIENCES = [
  { icon: "users", title: "Gezinnen", text: "Reken met je hele huishouden: volwassenen, kinderen, baby’s en huisdieren. De checklist past zich aan.", tint: "blue" },
  { icon: "user", title: "Alleenstaanden", text: "Een overzichtelijk pakket dat past bij één persoon, zonder dat je alles zelf hoeft uit te zoeken.", tint: "teal" },
  { icon: "heart", title: "Ouderen", text: "Grote, duidelijke tekst, rustige schermen en ruime tikdoelen. Ook handig om samen met een familielid in te vullen.", tint: "sand" },
] as const;

export const STEPS = [
  { title: "Vul je huishouden in", text: "Je geeft aan uit hoeveel volwassenen, kinderen, baby’s, ouderen en huisdieren je huishouden bestaat. De checklist en de berekening passen zich daarop aan." },
  { title: "Stel je noodpakket en noodplan samen", text: "Vink af wat je in huis hebt, vul houdbaarheidsdata in en maak een noodplan met afspraken, contacten en verzamelplaatsen." },
  { title: "Houd het bij", text: "De app laat zien hoeveel dagen jouw huishouden zelfredzaam is en wat de volgende stap is. Met Pro krijg je herinneringen voor spullen die aan vervanging toe zijn." },
] as const;

type Feature = { key: string; icon: string; title: string; text: string; tint: Tint; label: string };

/** Functies van de app. `label` is de korte vorm voor llms.txt en structured data. */
export const APP_FEATURES: Feature[] = [
  { key: "checklist", icon: "list", title: "Checklist met houdbaarheid", text: "Stel je noodpakket samen en zie in één overzicht wat bijna over datum is.", tint: "green", label: "checklist met houdbaarheid" },
  { key: "delen", icon: "share", title: "Noodplan delen als pdf, tekst of QR", text: "Maak een noodplan voor je huishouden en deel het met mensen die je vertrouwt.", tint: "blue", label: "noodplan delen via pdf, tekst of QR" },
  { key: "stappenplannen", icon: "route", title: "Stappenplannen voor meer dan 20 noodsituaties", text: "Overzichtelijke stappenplannen op basis van openbare bronnen, met bronvermelding.", tint: "indigo", label: "stappenplannen voor meer dan 20 noodsituaties" },
  { key: "kluis", icon: "lock", title: "Documentenkluis met biometrie", text: "Bewaar kopieën van belangrijke documenten versleuteld op je toestel, te openen met vingerafdruk of gezicht.", tint: "teal", label: "documentenkluis met biometrie" },
  { key: "rampenzender", icon: "radio", title: "Rampenzender per regio", text: "Kies je gemeente en zie vooraf de radiofrequenties van jouw regio. Zonder locatie en offline.", tint: "sand", label: "rampenzender per regio" },
  FEATURES.noodmodus
    ? { key: "eersteuur", icon: "flame", title: "Noodmodus en Eerste-uur kaart", text: "Een rustige weergave met alleen wat je op dat moment nodig hebt, en een kaart voor het eerste uur.", tint: "pink", label: "noodmodus en Eerste-uur kaart" }
    : { key: "eersteuur", icon: "flame", title: "Eerste-uur kaart", text: "Een kaart met wat je het eerste uur van een noodsituatie kunt doen, altijd bij de hand.", tint: "pink", label: "Eerste-uur kaart" },
  { key: "meterkast", icon: "check", title: "Meterkastkaart", text: "Een afdrukbare kaart voor in je meterkast, met de belangrijkste gegevens uit je plan.", tint: "sand", label: "meterkastkaart" },
  { key: "toegankelijk", icon: "access", title: "Toegankelijk ontworpen", text: "Grote tikdoelen, labels voor schermlezers en respect voor de tekstgrootte van je toestel.", tint: "green", label: "toegankelijk ontwerp" },
];

export const FREE_LIST = ["Checklist voor je noodpakket", "Houdbaarheidsoverzicht", "Alle stappenplannen", "Noodplan", ...(FEATURES.noodmodus ? ["Noodmodus"] : []), "Documentenkluis tot 3 documenten"];
export const PRO_LIST = ["Noodhacks", "Vervangherinneringen", "Onbeperkt documenten in de kluis"];

/** Prijsomschrijving: geen bedrag (de winkel toont de actuele prijs). */
export const PRICING = {
  short: "De app is gratis te downloaden. Pro is een eenmalige aankoop, geen abonnement.",
  store: "Aankoop via de App Store of Google Play. De actuele prijs zie je in de winkel.",
};

export const NOT_DOING = [
  { icon: "phone", title: "Vervangt geen 112", text: "Bij levensgevaar bel je 112. De app belt nooit zelf; een nummer opent alleen de telefoon-app." },
  { icon: "bellOff", title: "Geen NL-Alert", text: "De app waarschuwt je niet bij een noodsituatie. Stel NL-Alert zelf in op je telefoon." },
  { icon: "landmark", title: "Niet van de overheid", text: "Een onafhankelijke app van GymWiki, niet gemaakt door of in opdracht van de overheid." },
  { icon: "steth", title: "Geen medisch advies", text: "De informatie is algemeen. Twijfel je over je gezondheid, neem dan contact op met een arts." },
] as const;

export const PRIVACY_POINTS = [
  { icon: "wifiOff", title: "Volledig offline", text: "Alles wat je invult blijft op je eigen toestel." },
  { icon: "userX", title: "Geen account", text: "Geen e-mailadres, geen inloggen, geen profiel." },
  { icon: "eyeOff", title: "Geen tracking", text: "Geen analyse, geen advertenties, geen cookies op deze site." },
] as const;
