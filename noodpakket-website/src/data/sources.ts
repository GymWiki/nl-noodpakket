export type Source = { name: string; url: string; note?: string };
export type SourceGroup = { id: string; title: string; intro: string; items: Source[] };

/**
 * Bronnen die de app gebruikt, afgeleid uit assets/wiki/*.json en assets/radio/rampenzenders.json
 * van de app-repo (stand 2026-11-19). Alleen bronnen die de app echt gebruikt; `tool/check_site_urls.mjs`
 * vergelijkt dit met de app. Externe links konden vanuit de bouwomgeving niet worden gecontroleerd (zie README).
 */
export const SOURCE_GROUPS: SourceGroup[] = [
  {
    id: "algemeen",
    title: "Overheid en campagnes",
    intro: "Officiële websites waar je zelf de actuele adviezen kunt lezen. Wij zijn niet verbonden aan deze organisaties.",
    items: [
      { name: "Denk Vooruit", url: "https://www.denkvooruit.nl/", note: "Campagne van de Rijksoverheid over zelfredzaamheid" },
      { name: "Denk Vooruit: stel je noodpakket samen", url: "https://www.denkvooruit.nl/bereid-je-voor/stel-je-noodpakket-samen" },
      { name: "Politie", url: "https://www.politie.nl/" },
      { name: "Rijksoverheid: wat zit er in een noodpakket?", url: "https://www.rijksoverheid.nl/documenten/vraag-en-antwoord/veiligheidsregios-en-crisisbeheersing/wat-zit-er-in-een-noodpakket" },
      { name: "NL-Alert: zo werkt NL-Alert", url: "https://www.nl-alert.nl/zo-werkt-nl-alert" },
      { name: "Denk Vooruit: waarschuwing via de radio", url: "https://www.denkvooruit.nl/bereid-je-voor/zo-krijg-je-een-waarschuwing/radio" },
      { name: "Denk Vooruit: de sirene", url: "https://www.denkvooruit.nl/bereid-je-voor/zo-krijg-je-een-waarschuwing/de-sirene" },
    ],
  },
  {
    id: "risicos",
    title: "Risico’s in Nederland (Denk Vooruit)",
    intro: "Pagina’s per noodsituatie die als bron dienen voor de stappenplannen in de app.",
    items: [
      { name: "Geen stroom", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/geen-stroom" },
      { name: "Drinkwater", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/drinkwater" },
      { name: "Extreem weer", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/extreem-weer" },
      { name: "Hitte", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/hitte" },
      { name: "Overstroming", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/overstroming" },
      { name: "Natuurbrand", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/natuurbrand" },
      { name: "Aardbeving", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/aardbeving" },
      { name: "Uitval telecommunicatie", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/uitval-telecommunicatie" },
      { name: "Elektronisch betalen", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/elektronisch-betalen" },
      { name: "Uitbraak van infectieziekten", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/uitbraak-van-infectieziekten" },
      { name: "Een nucleair ongeval in Nederland", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/nucleair/een-nucleair-ongeval-in-nederland" },
      { name: "Cybercriminaliteit", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/cybercriminaliteit" },
      { name: "Een aanslag", url: "https://www.denkvooruit.nl/risicos/risicos-in-nederland/een-aanslag" },
    ],
  },
  {
    id: "rijk",
    title: "Rijksoverheid, RIVM, KNMI en NVWA",
    intro: "Aanvullende officiële informatie over gezondheid, weer en dierziekten.",
    items: [
      { name: "Rijksoverheid: wat kan ik doen tegen de hitte?", url: "https://www.rijksoverheid.nl/vraag-en-antwoord/droogte-en-hitte/wat-kan-ik-doen-tegen-de-hitte" },
      { name: "Rijksoverheid: jodiumtabletten", url: "https://www.rijksoverheid.nl/onderwerpen/straling/jodiumtabletten" },
      { name: "RIVM: Nationaal Hitteplan", url: "https://www.rivm.nl/hitte/nationaal-hitteplan" },
      { name: "RIVM: hygiëne", url: "https://www.rivm.nl/hygiene" },
      { name: "KNMI: waarschuwingen bij kou", url: "https://www.knmi.nl/kennis-en-datacentrum/waarschuwingen/kou" },
      { name: "KNMI: onweersbuien", url: "https://www.knmi.nl/kennis-en-datacentrum/waarschuwingen/onweersbuien" },
      { name: "KNMI: sneeuw en gladheid", url: "https://www.knmi.nl/kennis-en-datacentrum/waarschuwingen/sneeuw-en-gladheid" },
      { name: "KNMI: windstoten", url: "https://www.knmi.nl/kennis-en-datacentrum/waarschuwingen/windstoten" },
      { name: "KNMI: zware regen", url: "https://www.knmi.nl/kennis-en-datacentrum/waarschuwingen/zware-regen" },
      { name: "NVWA: vogelgriep voor particulieren", url: "https://www.nvwa.nl/onderwerpen/dier/vogelgriep/particulieren" },
    ],
  },
  {
    id: "brandweer",
    title: "Brandweer en Voedingscentrum",
    intro: "Brandveiligheid en veilig omgaan met voedsel.",
    items: [
      { name: "Brandweer", url: "https://www.brandweer.nl/" },
      { name: "Brandweer: koolmonoxide", url: "https://www.brandweer.nl/onderwerpen/koolmonoxide/" },
      { name: "Brandweer: rookmelders", url: "https://www.brandweer.nl/onderwerpen/rookmelders/" },
      { name: "Brandweer: veilige warme winter", url: "https://www.brandweer.nl/onderwerpen/veilige-warme-winter/" },
      { name: "Brandweer: vlam in de pan", url: "https://www.brandweer.nl/onderwerpen/vlam-in-de-pan/" },
      { name: "Brandweer: vlucht met je vluchtplan", url: "https://www.brandweer.nl/onderwerpen/vlucht-met-je-vluchtplan/" },
      { name: "Brandweer: blijf uit de rook", url: "https://www.brandweer.nl/onderwerpen/blijf-uit-de-rook/" },
      { name: "Brandweer: barbecueën", url: "https://www.brandweer.nl/onderwerpen/barbecueen/" },
      { name: "Brandweer: brandwonden, eerste hulp", url: "https://www.brandweer.nl/onderwerpen/brandwonden-eerste-hulp/" },
      { name: "Voedingscentrum: noodpakket met eten en drinken", url: "https://www.voedingscentrum.nl/nl/service/vraag-en-antwoord/boodschappen-doen/moet-ik-een-noodpakket-met-eten-en-drinken-in-huis-hebben.aspx" },
      { name: "Voedingscentrum: eten bij stroomstoring", url: "https://www.voedingscentrum.nl/nl/service/vraag-en-antwoord/veilig-eten/wat-moet-ik-doen-met-mijn-eten-in-de-koelkast-of-vriezer-bij-een-stroomstoring.aspx" },
      { name: "Voedingscentrum: veilig bewaren", url: "https://www.voedingscentrum.nl/nl/veilig-eten-voedselinfectie-voorkomen/veilig-bewaren.aspx" },
    ],
  },
  {
    id: "nutsbedrijven",
    title: "Netbeheerders en waterbedrijven",
    intro: "Praktische informatie bij storingen.",
    items: [
      { name: "Enexis: storingen en onderhoud", url: "https://www.enexis.nl/storingen-en-onderhoud" },
      { name: "Enexis: tips bij een gasstoring", url: "https://www.enexis.nl/storingen-en-onderhoud/tips-bij-gas-en-stroomstoringen/tips-bij-een-gasstoring" },
      { name: "Liander: ik ruik gas", url: "https://www.liander.nl/storingen-en-onderhoud/ik-ruik-gas" },
      { name: "Vitens: kookadvies drinkwater", url: "https://www.vitens.nl/storing-en-onderhoud/kookadvies-drinkwater" },
      { name: "Waternet: problemen met water", url: "https://www.waternet.nl/service-en-contact/problemen-met-water/denk-vooruit/" },
    ],
  },
  {
    id: "internationaal",
    title: "Internationale bronnen",
    intro: "Voor onderwerpen waarover Nederlandse bronnen weinig vertellen, zoals het ontsmetten van water.",
    items: [
      { name: "CDC: emergency water", url: "https://www.cdc.gov/water-emergency/about/index.html" },
      { name: "US EPA: emergency disinfection of drinking water", url: "https://www.epa.gov/ground-water-and-drinking-water/emergency-disinfection-drinking-water" },
    ],
  },
  {
    id: "gegevens",
    title: "Gegevens achter de rampenzender",
    intro: "Gegevensbronnen voor de indeling in gemeenten en veiligheidsregio’s en voor de radiofrequenties per regio.",
    items: [
      { name: "CBS: gebieden in Nederland 2026 (gemeente, provincie en veiligheidsregio)", url: "https://opendata.cbs.nl/ODataApi/odata/86247NED/TypedDataSet" },
      { name: "DARES: meterkastkaart Noord-Nederland, versie 4 (pdf)", url: "https://nn.dares.nl/wp-content/uploads/sites/5/2026/01/MKK-DARES-Noord-Nederland-V4.pdf" },
      { name: "DARES: meterkastkaart Midden- en West-Brabant, versie 1.0 (pdf)", url: "https://r20.dares.nl/wp-content/uploads/sites/11/2025/02/DARES-Meterkast-kaart-MiddenWestBrabant.pdf" },
    ],
  },
  {
    id: "radio",
    title: "Rampenzender en radio",
    intro: "Per regio gebruikt de app de informatie van de regionale omroep over de rampenzender, plus NPO Radio 1.",
    items: [
      { name: "NPO Radio 1", url: "https://www.nporadio1.nl" },
      { name: "WorldDAB: multiplexen in Nederland", url: "https://www.worlddab.org/countries/netherlands/multiplexes" },
      { name: "RTV Noord", url: "https://www.rtvnoord.nl/ontvangst" },
      { name: "Omrop Fryslân", url: "https://www.omropfryslan.nl/nl/service/untgangst-en-frekwinsjes" },
      { name: "RTV Drenthe", url: "https://www.rtvdrenthe.nl/rampenzender" },
      { name: "RTV Oost", url: "https://www.rtvoost.nl/ontvangst" },
      { name: "Omroep Flevoland", url: "https://www.omroepflevoland.nl/info/frequenties" },
      { name: "RTV Utrecht", url: "https://www.rtvutrecht.nl/hoe-ontvang-je-ons" },
      { name: "NH Nieuws", url: "https://www.nhnieuws.nl/calamiteitenzender" },
      { name: "Omroep West", url: "https://www.omroepwest.nl/calamiteitenzender" },
      { name: "Rijnmond", url: "https://www.rijnmond.nl/rampenzender" },
      { name: "Omroep Zeeland", url: "https://www.omroepzeeland.nl/frequenties" },
      { name: "Omroep Brabant", url: "https://www.omroepbrabant.nl/rampenzender" },
      { name: "L1 (Limburg)", url: "https://www.l1.nl/rampenzender" },
      { name: "Omroep Gelderland", url: "https://www.gld.nl/rampenzender" },
    ],
  },
];
