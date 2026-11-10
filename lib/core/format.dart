import 'package:intl/intl.dart';

import '../domain/models.dart';
import 'l10n/strings.dart';

String fmtQty(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

String fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'nl_NL').format(d);

/// Naam van een categorie; eigen categorieën zijn hun eigen naam.
String categoryName(String id) => switch (id) {
      Cat.water => S.catWater,
      Cat.info => S.catInfo,
      Cat.light => S.catLight,
      Cat.health => S.catHealth,
      Cat.docs => S.catDocs,
      Cat.other => S.catOther,
      _ => id,
    };

/// Standaardvolgorde, daarna eigen categorieën alfabetisch.
int compareCategories(String a, String b) {
  final ia = Cat.standard.indexOf(a), ib = Cat.standard.indexOf(b);
  if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
  if (ia >= 0) return -1;
  if (ib >= 0) return 1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// "3 van 9 liter" of "9 liter".
String quantityText(Item i) {
  final target = fmtQty(i.target);
  if (i.quantityHave != null) {
    return '${fmtQty(i.quantityHave!)} van $target ${i.unit}';
  }
  return '$target ${i.unit}';
}
