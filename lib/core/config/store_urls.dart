// Winkelpagina's van NL-Noodpakket, voor de rij "Beoordeel NL-Noodpakket" (Meer > Informatie).
// Staat bewust naast `site_urls.dart`: dat bestand wordt door `tool/check_site_urls.py` gelezen en bevat alleen de
// URL's van de website. Dit zijn de pagina's in de winkels.

/// Apple ID van de app (App Store Connect > Algemeen > App-informatie).
const appStoreId = '6757681584';

/// De App Store-pagina van de app.
const appStoreUrl = 'https://apps.apple.com/nl/app/nl-noodpakket/id$appStoreId';

/// Opent op iOS direct het scherm "Schrijf een beoordeling" in de App Store-app.
// TODO: controleer op een echt toestel dat deze URL de App Store opent en het beoordelingsscherm toont
// (vanuit de ontwikkelomgeving was apps.apple.com niet te bereiken, dus dit is niet getest).
const appStoreReviewUrl = '$appStoreUrl?action=write-review';

/// Pakket-id van de Android-app (applicationId in android/app/build.gradle.kts).
const androidPackageId = 'com.mycompany.mijnnoodpakket';

/// De Play Store-pagina van de app, afgeleid van het pakket-id.
// TODO: de Play-pagina bestaat nog niet (de app staat nog niet in Google Play). Deze URL werkt pas zodra de app
// gepubliceerd is; controleer hem dan en pas hem aan als het pakket-id verandert.
const playStoreUrl = 'https://play.google.com/store/apps/details?id=$androidPackageId';
