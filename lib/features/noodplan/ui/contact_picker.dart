import 'dart:io' show Platform;

import 'package:flutter_contacts/flutter_contacts.dart';

class PickedContact {
  const PickedContact({required this.name, required this.phone});
  final String name, phone;
}

enum PickResult { picked, cancelled, denied }

/// Contactkiezer van het systeem. De toestemming (Android) wordt pas gevraagd
/// op het moment dat deze functie wordt aangeroepen; handmatig invullen kan altijd.
Future<(PickResult, PickedContact?)> pickPhoneContact() async {
  try {
    if (Platform.isAndroid) {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        return (PickResult.denied, null);
      }
    }
    final c = await FlutterContacts.native.showPicker(properties: {ContactProperty.phone});
    if (c == null) return (PickResult.cancelled, null);
    final number = c.phones.isEmpty ? '' : c.phones.first.number;
    return (PickResult.picked, PickedContact(name: c.displayName ?? '', phone: number));
  } catch (_) {
    return (PickResult.denied, null);
  }
}
