// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ItemRowsTable extends ItemRows with TableInfo<$ItemRowsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inHouseMeta = const VerificationMeta(
    'inHouse',
  );
  @override
  late final GeneratedColumn<bool> inHouse = GeneratedColumn<bool>(
    'in_house',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_house" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quantityHaveMeta = const VerificationMeta(
    'quantityHave',
  );
  @override
  late final GeneratedColumn<double> quantityHave = GeneratedColumn<double>(
    'quantity_have',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityOverrideMeta = const VerificationMeta(
    'quantityOverride',
  );
  @override
  late final GeneratedColumn<double> quantityOverride = GeneratedColumn<double>(
    'quantity_override',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalMonthsMeta = const VerificationMeta(
    'intervalMonths',
  );
  @override
  late final GeneratedColumn<int> intervalMonths = GeneratedColumn<int>(
    'interval_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckedMeta = const VerificationMeta(
    'lastChecked',
  );
  @override
  late final GeneratedColumn<DateTime> lastChecked = GeneratedColumn<DateTime>(
    'last_checked',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isCustom,
    hidden,
    name,
    categoryId,
    why,
    unit,
    inHouse,
    quantityHave,
    quantityOverride,
    expiryDate,
    intervalMonths,
    lastChecked,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('in_house')) {
      context.handle(
        _inHouseMeta,
        inHouse.isAcceptableOrUnknown(data['in_house']!, _inHouseMeta),
      );
    }
    if (data.containsKey('quantity_have')) {
      context.handle(
        _quantityHaveMeta,
        quantityHave.isAcceptableOrUnknown(
          data['quantity_have']!,
          _quantityHaveMeta,
        ),
      );
    }
    if (data.containsKey('quantity_override')) {
      context.handle(
        _quantityOverrideMeta,
        quantityOverride.isAcceptableOrUnknown(
          data['quantity_override']!,
          _quantityOverrideMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('interval_months')) {
      context.handle(
        _intervalMonthsMeta,
        intervalMonths.isAcceptableOrUnknown(
          data['interval_months']!,
          _intervalMonthsMeta,
        ),
      );
    }
    if (data.containsKey('last_checked')) {
      context.handle(
        _lastCheckedMeta,
        lastChecked.isAcceptableOrUnknown(
          data['last_checked']!,
          _lastCheckedMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      inHouse: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_house'],
      )!,
      quantityHave: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_have'],
      ),
      quantityOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_override'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      intervalMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_months'],
      ),
      lastChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $ItemRowsTable createAlias(String alias) {
    return $ItemRowsTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final bool isCustom;
  final bool hidden;
  final String? name;
  final String? categoryId;
  final String? why;
  final String? unit;
  final bool inHouse;
  final double? quantityHave;
  final double? quantityOverride;
  final DateTime? expiryDate;
  final int? intervalMonths;
  final DateTime? lastChecked;
  final String notes;
  const ItemRow({
    required this.id,
    required this.isCustom,
    required this.hidden,
    this.name,
    this.categoryId,
    this.why,
    this.unit,
    required this.inHouse,
    this.quantityHave,
    this.quantityOverride,
    this.expiryDate,
    this.intervalMonths,
    this.lastChecked,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_custom'] = Variable<bool>(isCustom);
    map['hidden'] = Variable<bool>(hidden);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || why != null) {
      map['why'] = Variable<String>(why);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['in_house'] = Variable<bool>(inHouse);
    if (!nullToAbsent || quantityHave != null) {
      map['quantity_have'] = Variable<double>(quantityHave);
    }
    if (!nullToAbsent || quantityOverride != null) {
      map['quantity_override'] = Variable<double>(quantityOverride);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || intervalMonths != null) {
      map['interval_months'] = Variable<int>(intervalMonths);
    }
    if (!nullToAbsent || lastChecked != null) {
      map['last_checked'] = Variable<DateTime>(lastChecked);
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  ItemRowsCompanion toCompanion(bool nullToAbsent) {
    return ItemRowsCompanion(
      id: Value(id),
      isCustom: Value(isCustom),
      hidden: Value(hidden),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      why: why == null && nullToAbsent ? const Value.absent() : Value(why),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      inHouse: Value(inHouse),
      quantityHave: quantityHave == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityHave),
      quantityOverride: quantityOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityOverride),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      intervalMonths: intervalMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalMonths),
      lastChecked: lastChecked == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChecked),
      notes: Value(notes),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      name: serializer.fromJson<String?>(json['name']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      why: serializer.fromJson<String?>(json['why']),
      unit: serializer.fromJson<String?>(json['unit']),
      inHouse: serializer.fromJson<bool>(json['inHouse']),
      quantityHave: serializer.fromJson<double?>(json['quantityHave']),
      quantityOverride: serializer.fromJson<double?>(json['quantityOverride']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      intervalMonths: serializer.fromJson<int?>(json['intervalMonths']),
      lastChecked: serializer.fromJson<DateTime?>(json['lastChecked']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isCustom': serializer.toJson<bool>(isCustom),
      'hidden': serializer.toJson<bool>(hidden),
      'name': serializer.toJson<String?>(name),
      'categoryId': serializer.toJson<String?>(categoryId),
      'why': serializer.toJson<String?>(why),
      'unit': serializer.toJson<String?>(unit),
      'inHouse': serializer.toJson<bool>(inHouse),
      'quantityHave': serializer.toJson<double?>(quantityHave),
      'quantityOverride': serializer.toJson<double?>(quantityOverride),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'intervalMonths': serializer.toJson<int?>(intervalMonths),
      'lastChecked': serializer.toJson<DateTime?>(lastChecked),
      'notes': serializer.toJson<String>(notes),
    };
  }

  ItemRow copyWith({
    String? id,
    bool? isCustom,
    bool? hidden,
    Value<String?> name = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> why = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? inHouse,
    Value<double?> quantityHave = const Value.absent(),
    Value<double?> quantityOverride = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<int?> intervalMonths = const Value.absent(),
    Value<DateTime?> lastChecked = const Value.absent(),
    String? notes,
  }) => ItemRow(
    id: id ?? this.id,
    isCustom: isCustom ?? this.isCustom,
    hidden: hidden ?? this.hidden,
    name: name.present ? name.value : this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    why: why.present ? why.value : this.why,
    unit: unit.present ? unit.value : this.unit,
    inHouse: inHouse ?? this.inHouse,
    quantityHave: quantityHave.present ? quantityHave.value : this.quantityHave,
    quantityOverride: quantityOverride.present
        ? quantityOverride.value
        : this.quantityOverride,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    intervalMonths: intervalMonths.present
        ? intervalMonths.value
        : this.intervalMonths,
    lastChecked: lastChecked.present ? lastChecked.value : this.lastChecked,
    notes: notes ?? this.notes,
  );
  ItemRow copyWithCompanion(ItemRowsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      why: data.why.present ? data.why.value : this.why,
      unit: data.unit.present ? data.unit.value : this.unit,
      inHouse: data.inHouse.present ? data.inHouse.value : this.inHouse,
      quantityHave: data.quantityHave.present
          ? data.quantityHave.value
          : this.quantityHave,
      quantityOverride: data.quantityOverride.present
          ? data.quantityOverride.value
          : this.quantityOverride,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      intervalMonths: data.intervalMonths.present
          ? data.intervalMonths.value
          : this.intervalMonths,
      lastChecked: data.lastChecked.present
          ? data.lastChecked.value
          : this.lastChecked,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('isCustom: $isCustom, ')
          ..write('hidden: $hidden, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('why: $why, ')
          ..write('unit: $unit, ')
          ..write('inHouse: $inHouse, ')
          ..write('quantityHave: $quantityHave, ')
          ..write('quantityOverride: $quantityOverride, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('intervalMonths: $intervalMonths, ')
          ..write('lastChecked: $lastChecked, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isCustom,
    hidden,
    name,
    categoryId,
    why,
    unit,
    inHouse,
    quantityHave,
    quantityOverride,
    expiryDate,
    intervalMonths,
    lastChecked,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.isCustom == this.isCustom &&
          other.hidden == this.hidden &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.why == this.why &&
          other.unit == this.unit &&
          other.inHouse == this.inHouse &&
          other.quantityHave == this.quantityHave &&
          other.quantityOverride == this.quantityOverride &&
          other.expiryDate == this.expiryDate &&
          other.intervalMonths == this.intervalMonths &&
          other.lastChecked == this.lastChecked &&
          other.notes == this.notes);
}

class ItemRowsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<bool> isCustom;
  final Value<bool> hidden;
  final Value<String?> name;
  final Value<String?> categoryId;
  final Value<String?> why;
  final Value<String?> unit;
  final Value<bool> inHouse;
  final Value<double?> quantityHave;
  final Value<double?> quantityOverride;
  final Value<DateTime?> expiryDate;
  final Value<int?> intervalMonths;
  final Value<DateTime?> lastChecked;
  final Value<String> notes;
  final Value<int> rowid;
  const ItemRowsCompanion({
    this.id = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.hidden = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.why = const Value.absent(),
    this.unit = const Value.absent(),
    this.inHouse = const Value.absent(),
    this.quantityHave = const Value.absent(),
    this.quantityOverride = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.intervalMonths = const Value.absent(),
    this.lastChecked = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemRowsCompanion.insert({
    required String id,
    this.isCustom = const Value.absent(),
    this.hidden = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.why = const Value.absent(),
    this.unit = const Value.absent(),
    this.inHouse = const Value.absent(),
    this.quantityHave = const Value.absent(),
    this.quantityOverride = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.intervalMonths = const Value.absent(),
    this.lastChecked = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<bool>? isCustom,
    Expression<bool>? hidden,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? why,
    Expression<String>? unit,
    Expression<bool>? inHouse,
    Expression<double>? quantityHave,
    Expression<double>? quantityOverride,
    Expression<DateTime>? expiryDate,
    Expression<int>? intervalMonths,
    Expression<DateTime>? lastChecked,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isCustom != null) 'is_custom': isCustom,
      if (hidden != null) 'hidden': hidden,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (why != null) 'why': why,
      if (unit != null) 'unit': unit,
      if (inHouse != null) 'in_house': inHouse,
      if (quantityHave != null) 'quantity_have': quantityHave,
      if (quantityOverride != null) 'quantity_override': quantityOverride,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (intervalMonths != null) 'interval_months': intervalMonths,
      if (lastChecked != null) 'last_checked': lastChecked,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemRowsCompanion copyWith({
    Value<String>? id,
    Value<bool>? isCustom,
    Value<bool>? hidden,
    Value<String?>? name,
    Value<String?>? categoryId,
    Value<String?>? why,
    Value<String?>? unit,
    Value<bool>? inHouse,
    Value<double?>? quantityHave,
    Value<double?>? quantityOverride,
    Value<DateTime?>? expiryDate,
    Value<int?>? intervalMonths,
    Value<DateTime?>? lastChecked,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return ItemRowsCompanion(
      id: id ?? this.id,
      isCustom: isCustom ?? this.isCustom,
      hidden: hidden ?? this.hidden,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      why: why ?? this.why,
      unit: unit ?? this.unit,
      inHouse: inHouse ?? this.inHouse,
      quantityHave: quantityHave ?? this.quantityHave,
      quantityOverride: quantityOverride ?? this.quantityOverride,
      expiryDate: expiryDate ?? this.expiryDate,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      lastChecked: lastChecked ?? this.lastChecked,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (inHouse.present) {
      map['in_house'] = Variable<bool>(inHouse.value);
    }
    if (quantityHave.present) {
      map['quantity_have'] = Variable<double>(quantityHave.value);
    }
    if (quantityOverride.present) {
      map['quantity_override'] = Variable<double>(quantityOverride.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (intervalMonths.present) {
      map['interval_months'] = Variable<int>(intervalMonths.value);
    }
    if (lastChecked.present) {
      map['last_checked'] = Variable<DateTime>(lastChecked.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemRowsCompanion(')
          ..write('id: $id, ')
          ..write('isCustom: $isCustom, ')
          ..write('hidden: $hidden, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('why: $why, ')
          ..write('unit: $unit, ')
          ..write('inHouse: $inHouse, ')
          ..write('quantityHave: $quantityHave, ')
          ..write('quantityOverride: $quantityOverride, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('intervalMonths: $intervalMonths, ')
          ..write('lastChecked: $lastChecked, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemRowsTable itemRows = $ItemRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [itemRows, settingRows];
}

typedef $$ItemRowsTableCreateCompanionBuilder =
    ItemRowsCompanion Function({
      required String id,
      Value<bool> isCustom,
      Value<bool> hidden,
      Value<String?> name,
      Value<String?> categoryId,
      Value<String?> why,
      Value<String?> unit,
      Value<bool> inHouse,
      Value<double?> quantityHave,
      Value<double?> quantityOverride,
      Value<DateTime?> expiryDate,
      Value<int?> intervalMonths,
      Value<DateTime?> lastChecked,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$ItemRowsTableUpdateCompanionBuilder =
    ItemRowsCompanion Function({
      Value<String> id,
      Value<bool> isCustom,
      Value<bool> hidden,
      Value<String?> name,
      Value<String?> categoryId,
      Value<String?> why,
      Value<String?> unit,
      Value<bool> inHouse,
      Value<double?> quantityHave,
      Value<double?> quantityOverride,
      Value<DateTime?> expiryDate,
      Value<int?> intervalMonths,
      Value<DateTime?> lastChecked,
      Value<String> notes,
      Value<int> rowid,
    });

class $$ItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemRowsTable> {
  $$ItemRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inHouse => $composableBuilder(
    column: $table.inHouse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityHave => $composableBuilder(
    column: $table.quantityHave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityOverride => $composableBuilder(
    column: $table.quantityOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastChecked => $composableBuilder(
    column: $table.lastChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemRowsTable> {
  $$ItemRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inHouse => $composableBuilder(
    column: $table.inHouse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityHave => $composableBuilder(
    column: $table.quantityHave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityOverride => $composableBuilder(
    column: $table.quantityOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastChecked => $composableBuilder(
    column: $table.lastChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemRowsTable> {
  $$ItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get inHouse =>
      $composableBuilder(column: $table.inHouse, builder: (column) => column);

  GeneratedColumn<double> get quantityHave => $composableBuilder(
    column: $table.quantityHave,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityOverride => $composableBuilder(
    column: $table.quantityOverride,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastChecked => $composableBuilder(
    column: $table.lastChecked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$ItemRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemRowsTable,
          ItemRow,
          $$ItemRowsTableFilterComposer,
          $$ItemRowsTableOrderingComposer,
          $$ItemRowsTableAnnotationComposer,
          $$ItemRowsTableCreateCompanionBuilder,
          $$ItemRowsTableUpdateCompanionBuilder,
          (ItemRow, BaseReferences<_$AppDatabase, $ItemRowsTable, ItemRow>),
          ItemRow,
          PrefetchHooks Function()
        > {
  $$ItemRowsTableTableManager(_$AppDatabase db, $ItemRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> why = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> inHouse = const Value.absent(),
                Value<double?> quantityHave = const Value.absent(),
                Value<double?> quantityOverride = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<int?> intervalMonths = const Value.absent(),
                Value<DateTime?> lastChecked = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemRowsCompanion(
                id: id,
                isCustom: isCustom,
                hidden: hidden,
                name: name,
                categoryId: categoryId,
                why: why,
                unit: unit,
                inHouse: inHouse,
                quantityHave: quantityHave,
                quantityOverride: quantityOverride,
                expiryDate: expiryDate,
                intervalMonths: intervalMonths,
                lastChecked: lastChecked,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isCustom = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> why = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> inHouse = const Value.absent(),
                Value<double?> quantityHave = const Value.absent(),
                Value<double?> quantityOverride = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<int?> intervalMonths = const Value.absent(),
                Value<DateTime?> lastChecked = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemRowsCompanion.insert(
                id: id,
                isCustom: isCustom,
                hidden: hidden,
                name: name,
                categoryId: categoryId,
                why: why,
                unit: unit,
                inHouse: inHouse,
                quantityHave: quantityHave,
                quantityOverride: quantityOverride,
                expiryDate: expiryDate,
                intervalMonths: intervalMonths,
                lastChecked: lastChecked,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemRowsTable,
      ItemRow,
      $$ItemRowsTableFilterComposer,
      $$ItemRowsTableOrderingComposer,
      $$ItemRowsTableAnnotationComposer,
      $$ItemRowsTableCreateCompanionBuilder,
      $$ItemRowsTableUpdateCompanionBuilder,
      (ItemRow, BaseReferences<_$AppDatabase, $ItemRowsTable, ItemRow>),
      ItemRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder =
    SettingRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingRowsTableUpdateCompanionBuilder =
    SettingRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemRowsTableTableManager get itemRows =>
      $$ItemRowsTableTableManager(_db, _db.itemRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
}
