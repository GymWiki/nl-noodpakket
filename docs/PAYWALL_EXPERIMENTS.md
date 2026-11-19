# Paywall-experimenten

Doel: meer mensen kopen Pro **bewust**, op een manier die past bij de rustige stijl van de app en eerlijk is.
We verbeteren de paywall in kleine, meetbare stappen, **zonder tracking**: de app bevat geen analytics en dat blijft zo.
Het effect lees je af in de statistieken die de winkels zelf al hebben.

## Spelregels (niet onderhandelbaar)

- Per release **één ding** wijzigen. Zo weet je waar een verschil vandaan komt.
- Elke wijziging moet door `test/paywall_guard_test.dart` komen (dark-pattern-bewaker). Verboden: aftellers en tijdsdruk,
  valse schaarste, doorgestreepte of verzonnen "van"-prijzen, vooraf gekozen opties, schuldgevoel op de afwijsknop,
  angstzaaien, een verborgen of kleine sluitknop, verzonnen sociaal bewijs, uitroeptekens, nadruk met hoofdletters,
  herhaalde pop-ups, en een paywall bij opstarten of in de onboarding.
- De prijs komt altijd uit de winkel (`ProductDetails`), nooit uit de code. Wat Pro bevat verandert niet.
- Veiligheidsinformatie is en blijft gratis en zonder paywall (`test/pro_protection_test.dart`, `test/paywall_safety_test.dart`).
- De paywall verschijnt alleen na een bewuste actie van de gebruiker.

## Hoe wijzig je één ding

| Wat | Waar |
|---|---|
| Welke rijen, in welke volgorde, welke blokken zichtbaar zijn, Family Sharing aan of uit | `defaultPaywallConfig` in `lib/features/pro/paywall_config.dart` |
| De teksten | `lib/core/l10n/strings.dart`, blok `// ---- Pro ----` |
| Het moment (waar de paywall of een hint opent) | de aanroepen van `showPaywall`; een bewuste lijst staat in `test/paywall_guard_test.dart` |
| Het uiterlijk | `lib/features/pro/paywall_sheet.dart` |

Schrijf bij elke wijziging een regel in het logboek hieronder, **voordat** je de release bouwt.

## Meten zonder tracking

Gebruik de statistieken van de winkels. De menunamen kunnen in beide consoles veranderen; zoek op de begrippen.

- **Apple, App Store Connect**: Analytics en Sales and Trends. Kijk naar het aantal aankopen van `pro_unlock`
  en naar het aantal nieuwe downloads in dezelfde periode.
- **Google, Play Console**: Statistieken (installaties) en de financiële rapporten of het overzicht van producten in de app
  (aantal aankopen van `pro_unlock`).
- **Vergelijk** per winkel apart: aantal aankopen per 1000 nieuwe installaties, over een vaste periode van minstens 28 dagen,
  vóór en na de release. Noteer de aantallen, niet alleen het percentage.

Eerlijke kanttekeningen:

- Het aantal aankopen is klein. Een verschil van een paar aankopen is ruis. Neem als vuistregel pas een conclusie bij minstens
  30 aankopen per periode; anders: nog een periode doorlopen.
- Je kunt **niet per context** meten (noodhacks, herinneringen of kluis), want dat zou in-app tracking vragen. Je meet het totaal.
  Wil je een context beoordelen, zet hem dan in een release uit of aan en vergelijk het totaal.
- Seizoen en nieuws (stroomstoringen, campagnes) beïnvloeden de installaties. Vergelijk per 1000 installaties en noteer bijzonderheden.
- De winkels tonen alleen wat de winkel zelf ziet. Een mislukte of afgebroken aankoop is daar niet altijd in terug te vinden.

## Logboek

Vul bij elke release in: wat is gewijzigd, de hypothese, de datum en waar je het resultaat aflevert. Vul de uitkomst in na de meetperiode.

| Release | Datum | Wijziging | Hypothese | Meetperiode | Waar aflezen | Uitkomst |
|---|---|---|---|---|---|---|
| tot en met 2.0.0 (build 20) | tot 2026-11-19 | Oude paywall: één blad met "Wat je erbij krijgt", inklapbaar gratis-blok, geen context, geen herstelzin in het blad, losse Pro-regel op het dashboard | Dit is de **nulmeting** | zie hieronder | zie hierboven | nulmeting invullen uit de winkelcijfers over de laatste 28 dagen |
| eerstvolgende release na 2.0.0 (nummer invullen) | 2026-11-19 (ontwikkeld) | **Paywall v2**: rustige sheet met kruisje en even grote "Niet nu", drie contextvarianten (noodhacks, vervangherinneringen, kluis) met echte waarden uit de data, algemeen blok in Instellingen, gratis-blok altijd zichtbaar, winkelzin en "Eenmalig, geen abonnement", zachte hint na het invullen van een houdbaarheidsdatum, bevestiging na aankoop met één actie, foutstaten. De Pro-regel op het dashboard is verwijderd. | Mensen die precies zien wat ze krijgen op het moment dat ze het nodig hebben, kopen vaker bewust dan mensen die een algemeen aanbod zien. | 28 dagen na verschijnen in beide winkels | App Store Connect (Analytics en Sales and Trends) en Play Console (Statistieken en financiële rapporten) | invullen |

**Let op:** de v2-release verandert bewust veel tegelijk (het is een herontwerp). Daardoor is geen enkel onderdeel apart te beoordelen.
Dit is de nieuwe nulmeting. **Vanaf de volgende release geldt: één wijziging per release.**

Sjabloon voor een volgende regel:

```
| 2.x.y | JJJJ-MM-DD | <één wijziging> | <wat denk je dat er gebeurt en waarom> | 28 dagen | <waar> | <invullen> |
```

## Mogelijke volgende experimenten

Volgorde: **eerst het moment en het aanbod, dan de teksten, daarna pas het uiterlijk.** Het moment en wat iemand krijgt
bepalen het meest; kleur en vorm het minst.

### 1. Moment en aanbod
1. **Hint wel of niet.** De zachte hint na een ingevulde houdbaarheidsdatum uitzetten (`ProHint.reminderAfterDate` niet claimen).
   Hypothese: de hint op het moment van waarde levert aankopen op die er anders niet waren.
2. **Hint ook bij bestaande items.** Nu staat de hint alleen bij een nieuw item, omdat een bestaand item al de schakelaar heeft.
   Hypothese: dezelfde hint bij bestaande items vergroot het bereik zonder dat het opdringerig wordt.
3. **Welke rijen bovenaan.** In `defaultPaywallConfig`, hacks-variant: `hackSearch` ("Wat heb ik in huis?") boven `hackCount`.
   Hypothese: wat iemand direct kan doen, spreekt meer aan dan een aantal.
4. **Eigen voorbeeld versus algemene tekst** in de herinneringsvariant: `reminderExample` weglaten en alleen `reminderChoice` en
   `reminderOnDevice` tonen. Hypothese: het echte item met datum werkt beter dan de algemene zin.
5. **Gratis-blok**: weg (`showFreeBlock: false`) of onder de koopknop (nu) versus boven de koopknop.
   Hypothese: zichtbaar vertrouwen vooraf werkt beter dan een kortere sheet.
6. **Kluisvariant eerder tonen**: een rustige regel bij de teller "n van 3 gratis documenten" bij het 3e document, niet pas bij het 4e.
   Pas toe met dezelfde regels voor hints (één per sessie, met kruisje en "Niet meer tonen").
7. **Op termijn: de prijs.** Eén prijswijziging per release, alleen in App Store Connect en Play Console (de app leest de prijs uit de winkel).
   Verander de prijs nooit tegelijk met iets anders, en let op regionale prijzen.

### 2. Teksten
8. Kop van de noodhacks-variant: huidige ("Alle noodhacks, ook als je pakket op is") tegenover een kop met het aantal.
9. Koopknop: "Ontgrendel Pro voor {prijs}" tegenover "Koop Pro voor {prijs}".
10. Eén gerust zinnetje: de huidige winkelzin tegenover een korte versie zonder het herstel-deel.

### 3. Uiterlijk
11. Volgorde of tint van de iconen (uit het bestaande categoriepalet; houd de kleurenblindheidstest `test/color_distance_test.dart` groen).
12. Hoogte van het blad: nu hoogte naar inhoud; alternatief een vaste halve hoogte.

## Regelcontrole (2026-11-19)

Gecontroleerd tegen de officiële pagina's. **Niet alles kon worden gecontroleerd; dat staat erbij.**

**Apple** (App Store Review Guidelines, developer.apple.com/app-store/review/guidelines/). Alleen het eerste deel van de pagina kwam
woordelijk binnen; het latere deel (waaronder 3.1.x en 5.6.x) kwam als samenvatting. Controleer die nummers op de live pagina.
- 3.1.1: ontgrendelen via in-app aankoop en een herstelmogelijkheid voor herstelbare aankopen. De app heeft "Aankoop herstellen"
  in het blad en in Instellingen. Geen afwijking.
- 3.1.2(c) (over abonnementen, bij ons alleen een richtlijn): duidelijk beschrijven wat de gebruiker voor de prijs krijgt. Het blad toont per
  context wat Pro geeft, vóór de koopknop. Geen afwijking.
- 2.3.1(a) (woordelijk): een valse prijs is een reden voor verwijdering. De prijs komt uit `ProductDetails`; een test verbiedt een vaste prijs.
- 3.2.2(x) en 5.6.x (samenvatting): gebruikers niet dwingen of belonen om te beoordelen; eigen reviewvragen worden afgekeurd; geen
  misleidende aankoopprikkels. De app vraagt nergens om een review (een test controleert dat in en na de paywall).
- Family Sharing: staat niet in de richtlijnen; het stel je in App Store Connect in. De app noemt het alleen als de configvlag aan staat
  (`PaywallConfig.familySharing`, nu uit).
- **Afwijkingen gevonden: geen.**

**Google Play.**
- Gelezen: Play Billing, "Integrate" (developer.android.com/google/play/billing/integrate). Aankopen binnen 3 dagen bevestigen
  (de app doet dat via `completePurchase`); alleen toekennen bij de status gekocht (de app wacht bij "pending"); aankopen opvragen bij het
  starten en terugkomen in de app; vóór het aanbieden controleren of de gebruiker het item al bezit; `ProductDetails` niet cachen.
- **Niet kunnen lezen:** het Play-beleid zelf (Payments, Deceptive Behavior, beoordelingen en incentives): `play.google` en
  `support.google.com` zijn niet bereikbaar vanuit de ontwikkelomgeving. De regels voor misleidende aankoopprikkels en reviewmanipulatie voor
  Google Play zijn dus **niet** gecontroleerd. Lees ze zelf na (Play Console, Policy center) vóór je publiceert.
- Aandachtspunten voor een test met een echt toestel (geen bewezen afwijking): (a) de app controleert alleen lokaal of Pro al is gekocht
  (op Android ook stil bij het opstarten); een nieuwe installatie waar de stille controle nog niet klaar is, kan een aankoop
  starten van iets wat al bezit is; Play weigert dat en de app toont dan "De aankoop is niet gelukt" in plaats van te herstellen. Test dit
  en overweeg herstellen automatisch te proberen na zo'n fout. (b) `StorePurchaseService` bewaart `ProductDetails` tijdens een sessie; bij elk
  openen van het blad wordt de prijs opnieuw opgehaald, dus de kans op een verouderd object is klein.

## Screenshots

`docs/paywall/`: noodhacks, herinneringen en kluis, elk licht en donker (360 dp breed). Prijs, item en hack zijn demo-waarden voor de
afbeelding. Opnieuw maken met `PAYWALL_SHOTS_DIR=docs/paywall flutter test test/tool_paywall_shots_test.dart`.

## Wat we bewust niet doen

- Geen in-app analytics, geen A/B-test in de app, geen gebruikers-ID's of gebeurtenissen.
- Geen aftellers, schaarste, doorgestreepte prijzen, vooraf gekozen opties of schuldgevoel (zie de spelregels).
- Geen vraag om een review in of direct na de paywall of de aankoop.
- Geen paywall op veiligheidsschermen (wiki, Eerste-uur kaart, noodplan, mythes, gratis proefhacks).
