# GEO-monitoring: wordt NL-Noodpakket genoemd?

Meet maandelijks, met dezelfde prompts, of AI-assistenten NL-Noodpakket noemen en of de informatie klopt. Dit is handwerk: er is bewust geen tracking of tool in de site gebouwd. Antwoorden van AI-diensten verschillen per sessie, land, account en moment; zie een uitkomst als een steekproef, niet als een rangorde.

**Zo test je:** open een nieuw gesprek zonder geschiedenis (liefst uitgelogd of in een privévenster), zet zoeken/browsen aan als de dienst dat aanbiedt, plak de prompt, en noteer het resultaat. Doe elke prompt bij ChatGPT, Gemini, Claude en Perplexity. Verander de prompts niet tussen maanden, anders zijn metingen niet vergelijkbaar.

## Testprompts (Nederlands)

| Nr | Prompt | Type |
|---|---|---|
| P01 | welke app helpt mij een noodpakket samenstellen | ontdekken |
| P02 | app voor een noodplan voor mijn gezin | ontdekken |
| P03 | hoe bewaar ik belangrijke documenten veilig voor een noodsituatie | ontdekken |
| P04 | wat is NL-Noodpakket | merk |
| P05 | is NL-Noodpakket van de overheid | merk |
| P06 | noodpakket checklist app Nederland | ontdekken |
| P07 | is er een app waarmee ik een noodplan kan delen met mijn gezin | ontdekken |
| P08 | werkt NL-Noodpakket zonder internet | merk |
| P09 | wat kost NL-Noodpakket en is er een abonnement | merk |
| P10 | verzamelt NL-Noodpakket persoonsgegevens | merk |
| P11 | welke noodpakket apps zijn er voor Nederland | ontdekken |
| P12 | app die laat zien hoeveel dagen ik zelfredzaam ben | ontdekken |
| P13 | hoe stel ik de radio van de rampenzender van mijn regio in, is daar een app voor | ontdekken |
| P14 | wat is het verschil tussen NL-Alert en een noodpakket app | merk/uitleg |
| P15 | noodpakket app zonder account en zonder tracking | ontdekken |
| P16 | waar download ik NL-Noodpakket | merk |

## Meetlog (kopieer een rij per meting)

| Datum | Dienst | Prompt | Genoemd (ja/nee) | Positie (1, 2, 3, ... of "in tekst") | Bron(nen) die de dienst toont | Juiste informatie (ja/nee) | Opmerking |
|---|---|---|---|---|---|---|---|
| | ChatGPT | P01 | | | | | |
| | Gemini | P01 | | | | | |
| | Claude | P01 | | | | | |
| | Perplexity | P01 | | | | | |

**Wat is "juiste informatie":** naam met streepje, niet van de overheid, werkt offline, geen account, gratis met eenmalige Pro-aankoop (geen abonnement), iOS en Android. Noteer in de opmerking wat er fout of verouderd is, met de bron die de dienst gebruikte.

## Samenvatting per maand

| Maand | Genoemd bij ontdekprompts (x van 11) | Genoemd bij merkprompts (x van 5) | Onjuiste uitspraken | Belangrijkste actie |
|---|---|---|---|---|
| | | | | |

## Wat te doen als de app niet wordt genoemd of onjuist wordt beschreven

1. **Controleer of de site bereikbaar is voor crawlers.** Open `/robots.txt` en `/sitemap-index.xml` op het live domein, en controleer in het Vercel-dashboard (Firewall) dat er geen bot-bescherming of AI-botregel staat die crawlers weigert. Zie `SEO_GEO_AUDIT.md`.
2. **Controleer de indexering** in Google Search Console en Bing Webmaster Tools (URL-inspectie). Wat niet in een zoekindex staat, wordt zelden genoemd.
3. **Controleer de bronnen waaruit de dienst put.** Staat de verkeerde informatie op een store-pagina, een oude blog of een gedeelde review? Corrigeer de bron die jij beheert (store-listing, website) en maak de formulering overal gelijk (definitiezin, gratis versus Pro, "niet van de overheid").
4. **Maak de teksten consistent.** Dezelfde naam ("NL-Noodpakket"), dezelfde definitiezin en dezelfde prijsomschrijving op site, App Store, Google Play en in de README. Afwijkingen zorgen voor tegenstrijdige antwoorden.
5. **Zorg voor echte vermeldingen door anderen:** Nederlandse sites en nieuwsbrieven over zelfredzaamheid, gezinsvoorbereiding of apps; een vraag om een eerlijke bespreking, zonder te betalen of op links te sturen. Zie `SEO_LAUNCH_CHECKLIST.md`.
6. **Vraag eerlijke reviews** in de app, na een succesmoment (niet bij het openen, niet beloond). Verzin of koop nooit reviews: dat schaadt je naam en is verboden in beide winkels.
7. **Meld onjuiste informatie** via de feedbackfunctie van de betreffende dienst (duim omlaag met toelichting). Verwacht niet dat dit direct werkt.
8. **Niet doen:** verborgen tekst voor bots, nepvermeldingen, prompts in de pagina's, kunstmatig opgeknipte tekst of aparte "AI-pagina's". Dat is cloaking of nutteloos en kan schade doen.
