/// Teksten van het onderdeel Rampenzender (rustig Nederlands, B1).
/// Apart bestand zodat het onderdeel los te onderhouden is; stijl en toon volgen [S].
class RZ {
  RZ._();

  static const title = 'Rampenzender in jouw regio';
  static const entryTitle = 'Rampenzender in jouw regio';
  static const entrySub = 'Stem je radio alvast af, zodat je bij een ramp direct de goede zender hebt.';
  static const intro =
      'Bij een ramp of noodsituatie geeft de overheid informatie via de radio. '
      'Zoek hier jouw gemeente en stel je radio nu alvast in.';

  // Regio kiezen
  static const pickTitle = 'Kies jouw gemeente';
  static const pickHint = 'Zoek je gemeente';
  static const pickNone = 'We vinden geen gemeente met deze naam. Controleer de spelling.';
  static const pickStart = 'Typ de naam van je gemeente. Zo weten we welke zender bij jou hoort.';
  static const pickNoLocation = 'De app gebruikt je locatie niet. Je kiest zelf je gemeente.';
  static String pickResultSub(String broadcaster, String region) => '$broadcaster, veiligheidsregio $region';
  static const change = 'Andere gemeente kiezen';
  static const remove = 'Regio wissen';
  static const yourMunicipality = 'Jouw gemeente';

  // Resultaat
  static String forMunicipality(String gm, String broadcaster) => '$gm: rampenzender is $broadcaster.';
  static const fmLabel = 'FM';
  static const mhz = 'MHz';
  static const dabLabel = 'DAB+';
  static String dabChannel(String ch) => 'Kanaal $ch';
  static String dabSearch(String name) => 'Zoek op de naam: $name';
  static const regionalHeading = 'Rampenzender van jouw regio';
  static const nationalHeading = 'NPO Radio 1 (heel Nederland)';
  static const nationalFm =
      'De FM-frequentie kan per plek verschillen. Zoek op de FM-band naar NPO Radio 1.';
  static const nationalFmSemantics = 'FM: kan per plek verschillen. Zoek op de FM-band naar NPO Radio 1.';
  static String fmSemantics(List<String> spoken) => 'FM, ${spoken.join(', of ')}';
  static String dabSemantics(String ch, String name) => 'DAB plus, kanaal $ch. Zoek op de naam $name.';

  static const chooseHeading = 'Woon je in dit gebied?';
  static const chooseIntro =
      'In jouw gemeente zijn er meer frequenties. We weten niet zeker welke bij jouw huis hoort. '
      'Kijk bij welk gebied je woont, of probeer ze na elkaar.';
  static String livingIn(String area) => 'Woon je in $area?';
  static const myArea = 'Dit is mijn gebied';
  static const myAreaChosen = 'Jouw gebied';
  static const unchoose = 'Toon alle gebieden';
  static const otherAreas = 'Andere gebieden van deze omroep';

  static const noDataTitle = 'Nog geen gecontroleerde frequentie';
  static String noData(String? site) =>
      'We hebben voor jouw regio nog geen gecontroleerde frequentie. '
      'Stem af op NPO Radio 1 en kijk op de website van je regionale omroep${site == null ? '' : ' ($site)'}.';

  static const whyHeading = 'Waarom deze zender?';
  static const why =
      'Bij een ramp wijst de overheid de regionale publieke omroep aan als rampenzender. '
      'Daarnaast zendt NPO Radio 1 landelijk uit.';
  static const howHeading = 'Zo stel je je radio in';
  static const howFm =
      'FM: zet je radio aan en draai aan de afstemknop, of druk op zoeken, tot je de frequentie ziet. '
      'FM is meestal de eenvoudigste noodoplossing.';
  static const howDab =
      'DAB+: laat je radio alle zenders zoeken (autoscan) en kies daarna de zender in de lijst.';
  static const tipHeading = 'Tip';
  static const tip = 'Sla de zender op een voorkeurstoets op. Dan hoef je in een noodsituatie niet te zoeken.';

  static const markDone = 'Ik heb mijn radio ingesteld';
  static const markedDone = 'Je radio is ingesteld';
  static const markedDoneSub = 'Fijn. Controleer elk jaar even of je zender nog klopt.';
  static const undo = 'Toch nog niet ingesteld';

  static const moreExplain = 'Meer uitleg';
  static const adviceHeading = 'Welke radio heb ik nodig?';
  static const advice =
      'Kies bij voorkeur een radio die FM én DAB+ ontvangt en werkt op batterijen of met een zwengel. '
      'FM is meestal de eenvoudigste back-up.';
  static const adviceLink = 'Bekijk de radio op je checklist';

  static String checkedOn(String date) => 'Gegevens gecontroleerd op $date';
  static const frequenciesChange =
      'Frequenties kunnen wijzigen. Controleer de gegevens af en toe bij je regionale omroep.';
  static const singleSource = 'Deze gegevens komen uit één officiële bron. Controleer ze op je eigen radio.';
  static const report = 'Klopt dit niet? Laat het ons weten';
  static const reportHint = 'Opent je browser met een ingevuld meldingsformulier. Er wordt niets automatisch verstuurd.';
  static String reportTitle(String gm) => 'Rampenzender klopt niet: $gm';
  static String reportBody(String gm, String broadcaster, String freq, String date) =>
      'Gemeente: $gm\nOmroep: $broadcaster\nGetoonde frequentie: $freq\nGegevens gecontroleerd op: $date\n\n'
      'Wat klopt er niet? (Vul hier in wat je op je radio ziet.)\n';
  static const sourcesHeading = 'Bronnen';

  // Koppelingen
  static const dashTitle = 'Stel je radio in';
  static const dashSub = 'Kies je gemeente en stem je radio alvast af op de rampenzender.';
  static const dashAction = 'Rampenzender instellen';
  static const dashSetTitle = 'Stel je radio in op de rampenzender';
  static String dashFreq(String name, String fm) => '$name, FM $fm';
  static String tuneLine(String name, String fm) => 'Stem je radio af op: $name FM $fm';
  static String tuneLineDab(String name, String ch) => 'Stem je radio af op: $name DAB+ $ch';
  static const tuneLineNoRegion = 'Stem je radio af op de rampenzender van jouw regio. Kies eerst je gemeente.';
  static const tuneLineNoData =
      'Stem je radio af op NPO Radio 1. Voor jouw regio hebben we nog geen gecontroleerde frequentie.';
  static const tuneLineMore = 'Bekijk de rampenzender';
  static const settingsRow = 'Rampenzender-regio';
  static const settingsNone = 'Nog geen gemeente gekozen';
  static String settingsValue(String gm) => gm;

  // Noodplan en meterkastkaart
  static const planRadioLabel = 'Radio (rampenzender)';
  static String planRadioLine(String gm, String name, String fm) => '$gm: $name, FM $fm';
  static String planRadioNational(String fmFree) => 'NPO Radio 1: $fmFree';
  static const planRadioNationalShort = 'NPO Radio 1: zoek op de FM-band';
  static String planRadioSelect(String name) => '$name: kies je gebied in de app';
}
