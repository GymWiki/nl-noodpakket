import '../../domain/models.dart';

/// Standaardlijst (offline). Basis: advies op denkvooruit.nl (3 dagen / 72 uur,
/// 3 liter water p.p.p.d., contant geld €70 per volwassene en €30 per kind,
/// elk half jaar controleren), aangevuld met praktische items.
const seedItems = <SeedItem>[
  // Water en voeding
  SeedItem(
    id: 'water', category: Cat.water, name: 'Drinkwater', unit: 'liter',
    why: 'Zonder stroom of leidingwater heb je toch dagelijks water nodig. '
        'Reken op 3 liter per persoon per dag, voor 3 dagen.',
    shelfAdvice: 'Vervang flessen ongeveer elk jaar of volgens de datum op de fles.',
    intervalMonths: 12,
    perAdult: 9, perChild: 9, perBaby: 9, perSenior: 9, perPet: 2,
  ),
  SeedItem(
    id: 'food', category: Cat.water, name: 'Houdbaar eten voor 3 dagen', unit: 'maaltijden',
    why: 'Eten dat je niet hoeft te koelen of te koken, zoals blikgroente, '
        'noten, gedroogd fruit, havermout, houdbare melk, pasta en rijst.',
    shelfAdvice: 'Gebruik wat bijna verloopt en vul aan (rouleren).',
    intervalMonths: 6,
    perAdult: 9, perChild: 9, perSenior: 9,
  ),
  SeedItem(
    id: 'snacks', category: Cat.water, name: 'Snacks en energierepen', unit: 'stuks',
    why: 'Handig voor tussendoor en om op te vallen als het even tegenzit.',
    shelfAdvice: 'Check de houdbaarheid elk half jaar.', intervalMonths: 6,
    perAdult: 6, perChild: 6, perSenior: 6,
  ),
  SeedItem(
    id: 'baby_food', category: Cat.water, name: 'Babyvoeding', unit: 'potjes of porties',
    why: "Baby's kunnen niet zomaar overstappen op ander eten. "
        'Zorg voor flesvoeding of potjes voor minimaal 3 dagen.',
    shelfAdvice: 'Controleer de houdbaarheid regelmatig.', intervalMonths: 6,
    perBaby: 9, need: Need.baby,
  ),
  SeedItem(
    id: 'pet_food', category: Cat.water, name: 'Huisdiervoer', unit: 'dagrantsoenen',
    why: 'Je huisdier heeft ook eten nodig. Rekenhulp voor water: '
        'ongeveer 50 ml per kilo lichaamsgewicht per dag.',
    shelfAdvice: 'Controleer de houdbaarheid regelmatig.', intervalMonths: 6,
    perPet: 3, need: Need.pet,
  ),
  SeedItem(
    id: 'can_opener', category: Cat.water, name: 'Handmatige blikopener',
    why: 'Blikvoedsel is lang houdbaar, maar zonder opener kom je er niet in.',
    base: 1,
  ),
  SeedItem(
    id: 'stove', category: Cat.water,
    name: 'Kookmogelijkheid (campingstoof + brandstof)',
    why: 'Om warm te eten of water te koken. Alleen buiten gebruiken: '
        'binnen koken op gas of brandstof is gevaarlijk.',
    shelfAdvice: 'Controleer de brandstof elk jaar.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'cutlery', category: Cat.water,
    name: 'Servies en bestek voor eenmalig gebruik', unit: 'sets',
    why: 'Zonder stromend water is afwassen lastig. Wegwerpservies houdt het schoon.',
    perAdult: 3, perChild: 3, perSenior: 3,
  ),

  // Informatie en communicatie
  SeedItem(
    id: 'radio', category: Cat.info, name: 'Radio op batterijen of zwengel',
    why: 'Als internet en tv uitvallen, blijft radio vaak werken. '
        'Luister bijvoorbeeld naar NPO Radio 1 voor actuele informatie.',
    base: 1,
  ),
  SeedItem(
    id: 'batteries', category: Cat.info, name: 'Extra batterijen', unit: 'stuks',
    why: 'Voor radio en zaklamp. Zonder batterijen werken ze niet.',
    shelfAdvice: 'Controleer de houdbaarheidsdatum elk jaar.', intervalMonths: 12,
    base: 8,
  ),
  SeedItem(
    id: 'powerbank', category: Cat.info, name: 'Powerbank (opgeladen)',
    why: 'Zo kun je je telefoon blijven gebruiken als er geen stroom is.',
    shelfAdvice: 'Laad hem elk half jaar even op.', intervalMonths: 6,
    perAdult: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'cables', category: Cat.info, name: 'Oplaadkabels',
    why: 'Een powerbank is niets waard zonder de juiste kabel.',
    base: 1,
  ),
  SeedItem(
    id: 'phone_numbers', category: Cat.info,
    name: 'Belangrijke telefoonnummers op papier',
    why: 'Je telefoon kan leeg zijn. Schrijf nummers van familie, buren, '
        'huisarts en school op.',
    shelfAdvice: 'Controleer de nummers elk jaar.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'map', category: Cat.info, name: 'Papieren kaart of plattegrond van de regio',
    why: 'Navigatie via telefoon werkt niet altijd. Een papieren kaart wel.',
    base: 1,
  ),

  // Licht en warmte
  SeedItem(
    id: 'flashlight', category: Cat.light, name: 'Zaklamp',
    why: 'Veiliger dan kaarsen en altijd direct bruikbaar in het donker.',
    perAdult: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'headlamp', category: Cat.light, name: 'Hoofdlamp',
    why: 'Je hebt je handen vrij, handig bij koken of verzorgen in het donker.',
    base: 1,
  ),
  SeedItem(
    id: 'candles', category: Cat.light, name: 'Kaarsen of waxinelichtjes',
    why: 'Als reservelicht. Gebruik ze voorzichtig en laat ze nooit onbeheerd.',
    base: 6,
  ),
  SeedItem(
    id: 'lighter', category: Cat.light, name: 'Lucifers of aansteker',
    why: 'Nodig voor kaarsen en kooktoestel. Bewaar ze droog en buiten bereik van kinderen.',
    base: 1,
  ),
  SeedItem(
    id: 'blankets', category: Cat.light, name: 'Extra dekens of slaapzak',
    why: 'Zonder verwarming koelt een huis snel af.',
    perAdult: 1, perChild: 1, perBaby: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'warm_clothes', category: Cat.light, name: 'Warme kleding', unit: 'sets',
    why: 'Meerdere lagen houden je warm als de verwarming uitvalt.',
    perAdult: 1, perChild: 1, perBaby: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'rain_clothes', category: Cat.light, name: 'Regenkleding', unit: 'sets',
    why: 'Droog blijven is belangrijk als je naar buiten moet.',
    perAdult: 1, perChild: 1, perSenior: 1,
  ),

  // Gezondheid en hygiëne
  SeedItem(
    id: 'first_aid', category: Cat.health, name: 'EHBO-set',
    why: 'Voor kleine wonden en ongelukjes. Lees de gebruiksaanwijzing vooraf.',
    shelfAdvice: 'Controleer de inhoud en houdbaarheid elk jaar.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'medication', category: Cat.health, name: 'Persoonlijke medicatie', unit: 'dagen',
    why: 'Zorg voor minimaal 3 dagen voorraad van wat je dagelijks nodig hebt.',
    shelfAdvice: 'Controleer de houdbaarheid en vul aan, elk half jaar.',
    intervalMonths: 6,
    base: 3, need: Need.medication,
  ),
  SeedItem(
    id: 'prescription', category: Cat.health,
    name: 'Kopie van recept of medicatieoverzicht',
    why: 'Zo kan een arts of apotheker snel helpen als je medicijnen kwijt bent.',
    base: 1, need: Need.medication,
  ),
  SeedItem(
    id: 'painkillers', category: Cat.health, name: 'Pijnstillers', unit: 'strips',
    why: 'Voor hoofdpijn, koorts of pijn. Let op de leeftijd en dosering.',
    shelfAdvice: 'Check de houdbaarheid elk jaar.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'iodine', category: Cat.health, name: 'Jodiumtabletten (alleen informatief)',
    why: 'Neem jodiumtabletten alleen in als de overheid dat uitdrukkelijk '
        'adviseert. Niet op eigen initiatief: het helpt dan niet en kan schaden. '
        'Volg altijd de officiële instructies.',
    shelfAdvice: 'Controleer de houdbaarheid.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'toilet_paper', category: Cat.health, name: 'Toiletpapier', unit: 'rollen',
    why: 'Eén van de eerste dingen waar je gemak van hebt.',
    perAdult: 1, perChild: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'wipes', category: Cat.health, name: 'Vochtige doekjes', unit: 'pakken',
    why: 'Om je te wassen als er geen water is.',
    shelfAdvice: 'Check de houdbaarheid elk jaar.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'soap', category: Cat.health, name: 'Zeep of handgel',
    why: 'Handen schoon houden voorkomt ziekte, ook zonder stromend water.',
    base: 1,
  ),
  SeedItem(
    id: 'toothbrush', category: Cat.health, name: 'Tandenborstel en tandpasta',
    unit: 'sets',
    why: 'Mondverzorging blijft belangrijk, ook in een noodsituatie.',
    perAdult: 1, perChild: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'period', category: Cat.health, name: 'Maandverband of tampons',
    unit: 'pakken',
    why: 'Basisverzorging die je niet kunt missen.',
    base: 1,
  ),
  SeedItem(
    id: 'diapers', category: Cat.health, name: 'Luiers',
    why: 'Reken op ongeveer 6 luiers per baby per dag.',
    perBaby: 18, need: Need.baby,
  ),
  SeedItem(
    id: 'trash_bags', category: Cat.health, name: 'Vuilniszakken', unit: 'rollen',
    why: 'Om afval en gebruikt toiletmateriaal veilig op te bergen.',
    base: 1,
  ),
  SeedItem(
    id: 'masks', category: Cat.health, name: 'Mondkapjes',
    why: 'Handig bij stof, rook of ziekte in huis.',
    perAdult: 3, perChild: 3, perSenior: 3,
  ),
  SeedItem(
    id: 'thermometer', category: Cat.health, name: 'Thermometer',
    why: 'Om koorts te meten, zeker bij kinderen en ouderen.',
    base: 1,
  ),

  // Documenten en geld
  SeedItem(
    id: 'id_copies', category: Cat.docs, name: 'Kopieën van ID en paspoort',
    unit: 'sets',
    why: 'Bewaar kopieën apart van de originelen, in een waterdichte hoes.',
    shelfAdvice: 'Controleer of ze nog geldig zijn.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'insurance', category: Cat.docs, name: 'Verzekeringspapieren',
    why: 'Handig voor schademelding of hulp na een incident.',
    base: 1,
  ),
  SeedItem(
    id: 'cash', category: Cat.docs, name: 'Contant geld (kleine coupures)', unit: '€',
    why: 'Pinnen en betalen kan uitvallen. Richtlijn: €70 per volwassene en €30 per kind '
        'voor de eerste 72 uur. Je kunt dit langzaam opbouwen.',
    perAdult: 70, perChild: 30, perSenior: 70,
  ),
  SeedItem(
    id: 'usb', category: Cat.docs, name: 'USB-stick met digitale kopieën',
    why: "Foto's en documenten op een stick zijn los van je telefoon of cloud.",
    shelfAdvice: 'Werk de inhoud elk jaar bij.', intervalMonths: 12,
    base: 1,
  ),
  SeedItem(
    id: 'spare_keys', category: Cat.docs, name: 'Reservesleutels (huis en auto)',
    unit: 'sets',
    why: 'Als je snel weg moet of buitengesloten raakt.',
    base: 1,
  ),

  // Overig
  SeedItem(
    id: 'bag', category: Cat.other, name: 'Rugzak of waterdichte tas',
    why: 'Bewaar je noodpakket op een bereikbare plek in een waterdichte tas, '
        'zodat je het snel kunt meenemen.',
    base: 1,
  ),
  SeedItem(
    id: 'multitool', category: Cat.other, name: 'Multitool of zakmes',
    why: 'Voor allerlei kleine klussen. Ook gereedschap zoals een tang of hamer '
        'kan van pas komen.',
    base: 1,
  ),
  SeedItem(
    id: 'tape', category: Cat.other, name: 'Tape', unit: 'rollen',
    why: 'Voor reparaties en afdichten.', base: 1,
  ),
  SeedItem(
    id: 'whistle', category: Cat.other, name: 'Fluitje',
    why: 'Maak jezelf hoorbaar als je hulp nodig hebt.',
    perAdult: 1, perChild: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'tent', category: Cat.other, name: 'Tent of zeil',
    why: 'Voor tijdelijk onderdak of om schade aan je huis af te dekken.',
    base: 1,
  ),
  SeedItem(
    id: 'gloves', category: Cat.other, name: 'Handschoenen', unit: 'paar',
    why: 'Voor warmte en om je handen te beschermen.',
    perAdult: 1, perChild: 1, perSenior: 1,
  ),
  SeedItem(
    id: 'toys', category: Cat.other, name: 'Speelgoed of spelletjes voor kinderen',
    unit: 'sets',
    why: 'Afleiding houdt kinderen rustig en helpt bij stress.',
    base: 1, need: Need.child,
  ),
  SeedItem(
    id: 'pet_supplies', category: Cat.other, name: 'Spullen voor huisdieren',
    unit: 'sets',
    why: 'Denk aan een riem of draagmand, bak en eventuele medicijnen. '
        'Meer weten: diereninrampen.nl.',
    base: 1, need: Need.pet,
  ),
];
