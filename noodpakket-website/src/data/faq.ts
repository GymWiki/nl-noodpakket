export type Faq = { q: string; a: string; home?: boolean };

/** Gebruikt voor de FAQ-pagina, de korte FAQ op home en de FAQPage JSON-LD. Platte tekst, geen HTML. */
export const FAQS: Faq[] = [
  {
    q: "Hoe lang moet ik mezelf kunnen redden?",
    a: "De campagne Denk Vooruit adviseert een noodpakket voor minimaal 72 uur (3 dagen). De app laat zien hoeveel dagen jouw huishouden zelfredzaam is, op basis van het water en eten dat je invult.",
    home: true,
  },
  {
    q: "Hoeveel water heb ik nodig?",
    a: "Als richtlijn geldt 3 liter per persoon per dag. De app rekent voor je uit hoeveel dat is voor jouw huishouden en voor het aantal dagen waarvoor je je wilt voorbereiden.",
  },
  {
    q: "Werkt de app zonder internet?",
    a: "Ja. NL-Noodpakket werkt volledig offline: je checklist, noodplan, stappenplannen, documentenkluis en de gegevens van de rampenzender zitten in de app. De app maakt alleen verbinding met internet als jij zelf op een externe link tikt.",
    home: true,
  },
  {
    q: "Is de app van de overheid?",
    a: "Nee. NL-Noodpakket is een onafhankelijke app van GymWiki en niet gemaakt door of in opdracht van de Nederlandse overheid, NL-Alert of Denk Vooruit. De informatie is gebaseerd op openbare bronnen; die staan op de pagina Bronnen.",
    home: true,
  },
  {
    q: "Vervangt de app NL-Alert of 112?",
    a: "Nee. De app vervangt geen hulpdiensten en geen NL-Alert. Bel bij levensgevaar altijd 112. Zorg er daarnaast zelf voor dat NL-Alert op je telefoon is ingesteld; de app waarschuwt je niet bij een noodsituatie.",
  },
  {
    q: "Wat kost de app?",
    a: "De app is gratis te downloaden. De checklist, het houdbaarheidsoverzicht, alle stappenplannen, het noodplan en de documentenkluis (tot 3 documenten) blijven gratis. Pro is een eenmalige aankoop, geen abonnement, en ontgrendelt de noodhacks, vervangherinneringen en onbeperkt documenten in de kluis. De actuele prijs zie je in de App Store of Google Play.",
  },
  {
    q: "Verzamelt de app gegevens?",
    a: "Nee. Er is geen account, geen analyse of tracking en geen advertentie. Wat je invult blijft op je eigen toestel; de documentenkluis is daar versleuteld opgeslagen. Lees het volledige privacybeleid voor de details.",
  },
  {
    q: "Waar komt de informatie vandaan?",
    a: "Uit openbare bronnen van onder andere Denk Vooruit, de Rijksoverheid, de brandweer, het RIVM, het KNMI en het Voedingscentrum. Bij elk stappenplan in de app staan de bronnen en de datum van de laatste controle. De pagina Bronnen geeft het overzicht.",
  },
  {
    q: "Hoe deel ik mijn noodplan?",
    a: "Je kunt je noodplan delen als pdf, als tekst of met een QR-code. Een QR-code werkt rechtstreeks tussen twee toestellen op hetzelfde netwerk, versleuteld en zonder server. Documenten uit je kluis worden alleen gedeeld als je die zelf aanvinkt.",
  },
];
