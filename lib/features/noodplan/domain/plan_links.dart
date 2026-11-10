import 'plan_models.dart';
import 'plan_share.dart';

enum PlanRefKind { agreement, place, location, contact }

/// Verwijzing naar één stukje van het plan dat bij een noodgeval hoort.
class PlanRef {
  const PlanRef(this.kind, this.key);
  final PlanRefKind kind;
  final String key;

  PlanSection get section => switch (kind) {
        PlanRefKind.agreement => key == PlanKeys.helpMe ||
                key == PlanKeys.iHelp ||
                key == PlanKeys.neighbourDeals
            ? PlanSection.neighbours
            : PlanSection.agreements,
        PlanRefKind.place => PlanSection.places,
        PlanRefKind.location => PlanSection.home,
        PlanRefKind.contact => PlanSection.contacts,
      };

  String get label => switch (kind) {
        PlanRefKind.agreement => agreementLabel(key),
        PlanRefKind.place => placeLabel(key),
        PlanRefKind.location => locationLabel(key),
        PlanRefKind.contact => contactRoleLabel(key),
      };

  String valueIn(Plan p) => switch (kind) {
        PlanRefKind.agreement => p.agreement(key),
        PlanRefKind.place => [
            p.place(key)?.address.trim() ?? '',
            p.place(key)?.notes.trim() ?? '',
          ].where((s) => s.isNotEmpty).join(', '),
        PlanRefKind.location => p.locationText(key),
        PlanRefKind.contact => [
            for (final c in p.contactsOf(key))
              [c.name.trim(), c.phone.trim()].where((s) => s.isNotEmpty).join(' '),
          ].where((s) => s.isNotEmpty).join('; '),
      };
}

const _agr = PlanRefKind.agreement;
const _place = PlanRefKind.place;
const _loc = PlanRefKind.location;
const _contact = PlanRefKind.contact;

/// Welk deel van het plan bij welk noodgeval (wiki-id) hoort.
const planLinks = <String, List<PlanRef>>{
  'eerste-uur': [
    PlanRef(_agr, PlanKeys.checkin),
    PlanRef(_place, PlanKeys.placeNeighbourhood),
    PlanRef(_contact, PlanKeys.roleOutside),
  ],
  'stroomstoring': [
    PlanRef(_agr, PlanKeys.checkin),
    PlanRef(_contact, PlanKeys.roleOutside),
    PlanRef(_loc, PlanKeys.radio),
    PlanRef(_loc, PlanKeys.flashlight),
    PlanRef(_loc, PlanKeys.powerMain),
  ],
  'uitval-telecom': [
    PlanRef(_agr, PlanKeys.checkin),
    PlanRef(_place, PlanKeys.placeNeighbourhood),
    PlanRef(_contact, PlanKeys.roleOutside),
    PlanRef(_agr, PlanKeys.infoSource),
  ],
  'uitval-water': [PlanRef(_loc, PlanKeys.waterMain), PlanRef(_loc, PlanKeys.noodpakket)],
  'uitval-verwarming': [PlanRef(_agr, PlanKeys.vulnerable)],
  'overstroming': [
    PlanRef(_loc, PlanKeys.waterMain),
    PlanRef(_loc, PlanKeys.gasMain),
    PlanRef(_loc, PlanKeys.powerMain),
    PlanRef(_loc, PlanKeys.shelter),
    PlanRef(_loc, PlanKeys.noodpakket),
  ],
  'wateroverlast': [PlanRef(_loc, PlanKeys.meterkast), PlanRef(_loc, PlanKeys.shelter)],
  'storm': [PlanRef(_loc, PlanKeys.shelter)],
  'onweer': [PlanRef(_loc, PlanKeys.shelter)],
  'hitte': [PlanRef(_agr, PlanKeys.vulnerable)],
  'kou-gladheid': [PlanRef(_agr, PlanKeys.vulnerable)],
  'natuurbrand': [PlanRef(_place, PlanKeys.placeOutside), PlanRef(_loc, PlanKeys.noodpakket)],
  'aardbeving': [PlanRef(_loc, PlanKeys.shelter), PlanRef(_loc, PlanKeys.escapeRoutes)],
  'sirene-nl-alert': [
    PlanRef(_loc, PlanKeys.shelter),
    PlanRef(_agr, PlanKeys.kids),
    PlanRef(_agr, PlanKeys.infoSource),
  ],
  'kernongeval': [
    PlanRef(_loc, PlanKeys.shelter),
    PlanRef(_loc, PlanKeys.gasMain),
    PlanRef(_loc, PlanKeys.powerMain),
  ],
  'gaslucht': [PlanRef(_loc, PlanKeys.meterkast), PlanRef(_loc, PlanKeys.gasMain)],
  'co-vergiftiging': [PlanRef(_loc, PlanKeys.escapeRoutes)],
  'brand-in-huis': [
    PlanRef(_place, PlanKeys.placeHome),
    PlanRef(_loc, PlanKeys.smokeDetectors),
    PlanRef(_loc, PlanKeys.escapeRoutes),
  ],
  'pan-in-brand': [PlanRef(_loc, PlanKeys.smokeDetectors)],
};
