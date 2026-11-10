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

class $PlanMembersTable extends PlanMembers
    with TableInfo<$PlanMembersTable, PlanMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('person'),
  );
  static const VerificationMeta _ageGroupMeta = const VerificationMeta(
    'ageGroup',
  );
  @override
  late final GeneratedColumn<String> ageGroup = GeneratedColumn<String>(
    'age_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('adult'),
  );
  static const VerificationMeta _needsHelpMeta = const VerificationMeta(
    'needsHelp',
  );
  @override
  late final GeneratedColumn<bool> needsHelp = GeneratedColumn<bool>(
    'needs_help',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_help" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    name,
    kind,
    ageGroup,
    needsHelp,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('age_group')) {
      context.handle(
        _ageGroupMeta,
        ageGroup.isAcceptableOrUnknown(data['age_group']!, _ageGroupMeta),
      );
    }
    if (data.containsKey('needs_help')) {
      context.handle(
        _needsHelpMeta,
        needsHelp.isAcceptableOrUnknown(data['needs_help']!, _needsHelpMeta),
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
  PlanMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      ageGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_group'],
      )!,
      needsHelp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_help'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $PlanMembersTable createAlias(String alias) {
    return $PlanMembersTable(attachedDatabase, alias);
  }
}

class PlanMember extends DataClass implements Insertable<PlanMember> {
  final int id;
  final String name;

  /// person | pet
  final String kind;

  /// adult | senior | child | baby (alleen voor personen)
  final String ageGroup;
  final bool needsHelp;
  final String notes;
  const PlanMember({
    required this.id,
    required this.name,
    required this.kind,
    required this.ageGroup,
    required this.needsHelp,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['age_group'] = Variable<String>(ageGroup);
    map['needs_help'] = Variable<bool>(needsHelp);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  PlanMembersCompanion toCompanion(bool nullToAbsent) {
    return PlanMembersCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      ageGroup: Value(ageGroup),
      needsHelp: Value(needsHelp),
      notes: Value(notes),
    );
  }

  factory PlanMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanMember(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      ageGroup: serializer.fromJson<String>(json['ageGroup']),
      needsHelp: serializer.fromJson<bool>(json['needsHelp']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'ageGroup': serializer.toJson<String>(ageGroup),
      'needsHelp': serializer.toJson<bool>(needsHelp),
      'notes': serializer.toJson<String>(notes),
    };
  }

  PlanMember copyWith({
    int? id,
    String? name,
    String? kind,
    String? ageGroup,
    bool? needsHelp,
    String? notes,
  }) => PlanMember(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    ageGroup: ageGroup ?? this.ageGroup,
    needsHelp: needsHelp ?? this.needsHelp,
    notes: notes ?? this.notes,
  );
  PlanMember copyWithCompanion(PlanMembersCompanion data) {
    return PlanMember(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      ageGroup: data.ageGroup.present ? data.ageGroup.value : this.ageGroup,
      needsHelp: data.needsHelp.present ? data.needsHelp.value : this.needsHelp,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanMember(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('ageGroup: $ageGroup, ')
          ..write('needsHelp: $needsHelp, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, ageGroup, needsHelp, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanMember &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.ageGroup == this.ageGroup &&
          other.needsHelp == this.needsHelp &&
          other.notes == this.notes);
}

class PlanMembersCompanion extends UpdateCompanion<PlanMember> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> ageGroup;
  final Value<bool> needsHelp;
  final Value<String> notes;
  const PlanMembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.ageGroup = const Value.absent(),
    this.needsHelp = const Value.absent(),
    this.notes = const Value.absent(),
  });
  PlanMembersCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.ageGroup = const Value.absent(),
    this.needsHelp = const Value.absent(),
    this.notes = const Value.absent(),
  });
  static Insertable<PlanMember> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? ageGroup,
    Expression<bool>? needsHelp,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (ageGroup != null) 'age_group': ageGroup,
      if (needsHelp != null) 'needs_help': needsHelp,
      if (notes != null) 'notes': notes,
    });
  }

  PlanMembersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? ageGroup,
    Value<bool>? needsHelp,
    Value<String>? notes,
  }) {
    return PlanMembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      ageGroup: ageGroup ?? this.ageGroup,
      needsHelp: needsHelp ?? this.needsHelp,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ageGroup.present) {
      map['age_group'] = Variable<String>(ageGroup.value);
    }
    if (needsHelp.present) {
      map['needs_help'] = Variable<bool>(needsHelp.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanMembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('ageGroup: $ageGroup, ')
          ..write('needsHelp: $needsHelp, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $PlanContactsTable extends PlanContacts
    with TableInfo<$PlanContactsTable, PlanContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _relationMeta = const VerificationMeta(
    'relation',
  );
  @override
  late final GeneratedColumn<String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, role, name, relation, phone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('relation')) {
      context.handle(
        _relationMeta,
        relation.isAcceptableOrUnknown(data['relation']!, _relationMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanContact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      relation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
    );
  }

  @override
  $PlanContactsTable createAlias(String alias) {
    return $PlanContactsTable(attachedDatabase, alias);
  }
}

class PlanContact extends DataClass implements Insertable<PlanContact> {
  final int id;

  /// outside_region | emergency | neighbour | doctor | school | vet
  final String role;
  final String name;
  final String relation;
  final String phone;
  const PlanContact({
    required this.id,
    required this.role,
    required this.name,
    required this.relation,
    required this.phone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['role'] = Variable<String>(role);
    map['name'] = Variable<String>(name);
    map['relation'] = Variable<String>(relation);
    map['phone'] = Variable<String>(phone);
    return map;
  }

  PlanContactsCompanion toCompanion(bool nullToAbsent) {
    return PlanContactsCompanion(
      id: Value(id),
      role: Value(role),
      name: Value(name),
      relation: Value(relation),
      phone: Value(phone),
    );
  }

  factory PlanContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanContact(
      id: serializer.fromJson<int>(json['id']),
      role: serializer.fromJson<String>(json['role']),
      name: serializer.fromJson<String>(json['name']),
      relation: serializer.fromJson<String>(json['relation']),
      phone: serializer.fromJson<String>(json['phone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'role': serializer.toJson<String>(role),
      'name': serializer.toJson<String>(name),
      'relation': serializer.toJson<String>(relation),
      'phone': serializer.toJson<String>(phone),
    };
  }

  PlanContact copyWith({
    int? id,
    String? role,
    String? name,
    String? relation,
    String? phone,
  }) => PlanContact(
    id: id ?? this.id,
    role: role ?? this.role,
    name: name ?? this.name,
    relation: relation ?? this.relation,
    phone: phone ?? this.phone,
  );
  PlanContact copyWithCompanion(PlanContactsCompanion data) {
    return PlanContact(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      name: data.name.present ? data.name.value : this.name,
      relation: data.relation.present ? data.relation.value : this.relation,
      phone: data.phone.present ? data.phone.value : this.phone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanContact(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('relation: $relation, ')
          ..write('phone: $phone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, role, name, relation, phone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanContact &&
          other.id == this.id &&
          other.role == this.role &&
          other.name == this.name &&
          other.relation == this.relation &&
          other.phone == this.phone);
}

class PlanContactsCompanion extends UpdateCompanion<PlanContact> {
  final Value<int> id;
  final Value<String> role;
  final Value<String> name;
  final Value<String> relation;
  final Value<String> phone;
  const PlanContactsCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.name = const Value.absent(),
    this.relation = const Value.absent(),
    this.phone = const Value.absent(),
  });
  PlanContactsCompanion.insert({
    this.id = const Value.absent(),
    required String role,
    this.name = const Value.absent(),
    this.relation = const Value.absent(),
    this.phone = const Value.absent(),
  }) : role = Value(role);
  static Insertable<PlanContact> custom({
    Expression<int>? id,
    Expression<String>? role,
    Expression<String>? name,
    Expression<String>? relation,
    Expression<String>? phone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (name != null) 'name': name,
      if (relation != null) 'relation': relation,
      if (phone != null) 'phone': phone,
    });
  }

  PlanContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? role,
    Value<String>? name,
    Value<String>? relation,
    Value<String>? phone,
  }) {
    return PlanContactsCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phone: phone ?? this.phone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (relation.present) {
      map['relation'] = Variable<String>(relation.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanContactsCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('relation: $relation, ')
          ..write('phone: $phone')
          ..write(')'))
        .toString();
  }
}

class $PlanPlacesTable extends PlanPlaces
    with TableInfo<$PlanPlacesTable, PlanPlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  List<GeneratedColumn> get $columns => [kind, address, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanPlace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
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
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  PlanPlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanPlace(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $PlanPlacesTable createAlias(String alias) {
    return $PlanPlacesTable(attachedDatabase, alias);
  }
}

class PlanPlace extends DataClass implements Insertable<PlanPlace> {
  /// home_outside | neighbourhood | outside_region
  final String kind;
  final String address;
  final String notes;
  const PlanPlace({
    required this.kind,
    required this.address,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['address'] = Variable<String>(address);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  PlanPlacesCompanion toCompanion(bool nullToAbsent) {
    return PlanPlacesCompanion(
      kind: Value(kind),
      address: Value(address),
      notes: Value(notes),
    );
  }

  factory PlanPlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanPlace(
      kind: serializer.fromJson<String>(json['kind']),
      address: serializer.fromJson<String>(json['address']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'address': serializer.toJson<String>(address),
      'notes': serializer.toJson<String>(notes),
    };
  }

  PlanPlace copyWith({String? kind, String? address, String? notes}) =>
      PlanPlace(
        kind: kind ?? this.kind,
        address: address ?? this.address,
        notes: notes ?? this.notes,
      );
  PlanPlace copyWithCompanion(PlanPlacesCompanion data) {
    return PlanPlace(
      kind: data.kind.present ? data.kind.value : this.kind,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanPlace(')
          ..write('kind: $kind, ')
          ..write('address: $address, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, address, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanPlace &&
          other.kind == this.kind &&
          other.address == this.address &&
          other.notes == this.notes);
}

class PlanPlacesCompanion extends UpdateCompanion<PlanPlace> {
  final Value<String> kind;
  final Value<String> address;
  final Value<String> notes;
  final Value<int> rowid;
  const PlanPlacesCompanion({
    this.kind = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanPlacesCompanion.insert({
    required String kind,
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind);
  static Insertable<PlanPlace> custom({
    Expression<String>? kind,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanPlacesCompanion copyWith({
    Value<String>? kind,
    Value<String>? address,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return PlanPlacesCompanion(
      kind: kind ?? this.kind,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
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
    return (StringBuffer('PlanPlacesCompanion(')
          ..write('kind: $kind, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanAgreementsTable extends PlanAgreements
    with TableInfo<$PlanAgreementsTable, PlanAgreement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanAgreementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [key, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_agreements';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanAgreement> instance, {
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
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PlanAgreement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanAgreement(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $PlanAgreementsTable createAlias(String alias) {
    return $PlanAgreementsTable(attachedDatabase, alias);
  }
}

class PlanAgreement extends DataClass implements Insertable<PlanAgreement> {
  final String key;
  final String body;
  const PlanAgreement({required this.key, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['body'] = Variable<String>(body);
    return map;
  }

  PlanAgreementsCompanion toCompanion(bool nullToAbsent) {
    return PlanAgreementsCompanion(key: Value(key), body: Value(body));
  }

  factory PlanAgreement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanAgreement(
      key: serializer.fromJson<String>(json['key']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'body': serializer.toJson<String>(body),
    };
  }

  PlanAgreement copyWith({String? key, String? body}) =>
      PlanAgreement(key: key ?? this.key, body: body ?? this.body);
  PlanAgreement copyWithCompanion(PlanAgreementsCompanion data) {
    return PlanAgreement(
      key: data.key.present ? data.key.value : this.key,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanAgreement(')
          ..write('key: $key, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanAgreement &&
          other.key == this.key &&
          other.body == this.body);
}

class PlanAgreementsCompanion extends UpdateCompanion<PlanAgreement> {
  final Value<String> key;
  final Value<String> body;
  final Value<int> rowid;
  const PlanAgreementsCompanion({
    this.key = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanAgreementsCompanion.insert({
    required String key,
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<PlanAgreement> custom({
    Expression<String>? key,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanAgreementsCompanion copyWith({
    Value<String>? key,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return PlanAgreementsCompanion(
      key: key ?? this.key,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanAgreementsCompanion(')
          ..write('key: $key, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanLocationsTable extends PlanLocations
    with TableInfo<$PlanLocationsTable, PlanLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, body, photoPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanLocation> instance, {
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
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PlanLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanLocation(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
    );
  }

  @override
  $PlanLocationsTable createAlias(String alias) {
    return $PlanLocationsTable(attachedDatabase, alias);
  }
}

class PlanLocation extends DataClass implements Insertable<PlanLocation> {
  final String key;
  final String body;

  /// Pad naar een lokaal opgeslagen foto (verlaat het toestel nooit zonder delen).
  final String? photoPath;
  const PlanLocation({required this.key, required this.body, this.photoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    return map;
  }

  PlanLocationsCompanion toCompanion(bool nullToAbsent) {
    return PlanLocationsCompanion(
      key: Value(key),
      body: Value(body),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
    );
  }

  factory PlanLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanLocation(
      key: serializer.fromJson<String>(json['key']),
      body: serializer.fromJson<String>(json['body']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'body': serializer.toJson<String>(body),
      'photoPath': serializer.toJson<String?>(photoPath),
    };
  }

  PlanLocation copyWith({
    String? key,
    String? body,
    Value<String?> photoPath = const Value.absent(),
  }) => PlanLocation(
    key: key ?? this.key,
    body: body ?? this.body,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
  );
  PlanLocation copyWithCompanion(PlanLocationsCompanion data) {
    return PlanLocation(
      key: data.key.present ? data.key.value : this.key,
      body: data.body.present ? data.body.value : this.body,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanLocation(')
          ..write('key: $key, ')
          ..write('body: $body, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, body, photoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanLocation &&
          other.key == this.key &&
          other.body == this.body &&
          other.photoPath == this.photoPath);
}

class PlanLocationsCompanion extends UpdateCompanion<PlanLocation> {
  final Value<String> key;
  final Value<String> body;
  final Value<String?> photoPath;
  final Value<int> rowid;
  const PlanLocationsCompanion({
    this.key = const Value.absent(),
    this.body = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanLocationsCompanion.insert({
    required String key,
    this.body = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<PlanLocation> custom({
    Expression<String>? key,
    Expression<String>? body,
    Expression<String>? photoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (body != null) 'body': body,
      if (photoPath != null) 'photo_path': photoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanLocationsCompanion copyWith({
    Value<String>? key,
    Value<String>? body,
    Value<String?>? photoPath,
    Value<int>? rowid,
  }) {
    return PlanLocationsCompanion(
      key: key ?? this.key,
      body: body ?? this.body,
      photoPath: photoPath ?? this.photoPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanLocationsCompanion(')
          ..write('key: $key, ')
          ..write('body: $body, ')
          ..write('photoPath: $photoPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanMetaTable extends PlanMeta
    with TableInfo<$PlanMetaTable, PlanMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _householdNameMeta = const VerificationMeta(
    'householdName',
  );
  @override
  late final GeneratedColumn<String> householdName = GeneratedColumn<String>(
    'household_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _medicationMeta = const VerificationMeta(
    'medication',
  );
  @override
  late final GeneratedColumn<String> medication = GeneratedColumn<String>(
    'medication',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _devicesMeta = const VerificationMeta(
    'devices',
  );
  @override
  late final GeneratedColumn<String> devices = GeneratedColumn<String>(
    'devices',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  @override
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _caregivingMeta = const VerificationMeta(
    'caregiving',
  );
  @override
  late final GeneratedColumn<String> caregiving = GeneratedColumn<String>(
    'caregiving',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _documentsMeta = const VerificationMeta(
    'documents',
  );
  @override
  late final GeneratedColumn<String> documents = GeneratedColumn<String>(
    'documents',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<String> skipped = GeneratedColumn<String>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _wizardStepMeta = const VerificationMeta(
    'wizardStep',
  );
  @override
  late final GeneratedColumn<int> wizardStep = GeneratedColumn<int>(
    'wizard_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sharedVersionMeta = const VerificationMeta(
    'sharedVersion',
  );
  @override
  late final GeneratedColumn<int> sharedVersion = GeneratedColumn<int>(
    'shared_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSharedAtMeta = const VerificationMeta(
    'lastSharedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSharedAt = GeneratedColumn<DateTime>(
    'last_shared_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastConfirmedAtMeta = const VerificationMeta(
    'lastConfirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastConfirmedAt =
      GeneratedColumn<DateTime>(
        'last_confirmed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdName,
    medication,
    devices,
    allergies,
    caregiving,
    documents,
    skipped,
    wizardStep,
    sharedVersion,
    createdAt,
    updatedAt,
    lastSharedAt,
    lastConfirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_name')) {
      context.handle(
        _householdNameMeta,
        householdName.isAcceptableOrUnknown(
          data['household_name']!,
          _householdNameMeta,
        ),
      );
    }
    if (data.containsKey('medication')) {
      context.handle(
        _medicationMeta,
        medication.isAcceptableOrUnknown(data['medication']!, _medicationMeta),
      );
    }
    if (data.containsKey('devices')) {
      context.handle(
        _devicesMeta,
        devices.isAcceptableOrUnknown(data['devices']!, _devicesMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('caregiving')) {
      context.handle(
        _caregivingMeta,
        caregiving.isAcceptableOrUnknown(data['caregiving']!, _caregivingMeta),
      );
    }
    if (data.containsKey('documents')) {
      context.handle(
        _documentsMeta,
        documents.isAcceptableOrUnknown(data['documents']!, _documentsMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('wizard_step')) {
      context.handle(
        _wizardStepMeta,
        wizardStep.isAcceptableOrUnknown(data['wizard_step']!, _wizardStepMeta),
      );
    }
    if (data.containsKey('shared_version')) {
      context.handle(
        _sharedVersionMeta,
        sharedVersion.isAcceptableOrUnknown(
          data['shared_version']!,
          _sharedVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_shared_at')) {
      context.handle(
        _lastSharedAtMeta,
        lastSharedAt.isAcceptableOrUnknown(
          data['last_shared_at']!,
          _lastSharedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_confirmed_at')) {
      context.handle(
        _lastConfirmedAtMeta,
        lastConfirmedAt.isAcceptableOrUnknown(
          data['last_confirmed_at']!,
          _lastConfirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_name'],
      )!,
      medication: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication'],
      )!,
      devices: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devices'],
      )!,
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      )!,
      caregiving: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiving'],
      )!,
      documents: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documents'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skipped'],
      )!,
      wizardStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wizard_step'],
      )!,
      sharedVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shared_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      lastSharedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_shared_at'],
      ),
      lastConfirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_confirmed_at'],
      ),
    );
  }

  @override
  $PlanMetaTable createAlias(String alias) {
    return $PlanMetaTable(attachedDatabase, alias);
  }
}

class PlanMetaData extends DataClass implements Insertable<PlanMetaData> {
  final int id;
  final String householdName;
  final String medication;
  final String devices;
  final String allergies;
  final String caregiving;
  final String documents;

  /// JSON-lijst met overgeslagen onderdelen.
  final String skipped;
  final int wizardStep;
  final int sharedVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSharedAt;
  final DateTime? lastConfirmedAt;
  const PlanMetaData({
    required this.id,
    required this.householdName,
    required this.medication,
    required this.devices,
    required this.allergies,
    required this.caregiving,
    required this.documents,
    required this.skipped,
    required this.wizardStep,
    required this.sharedVersion,
    this.createdAt,
    this.updatedAt,
    this.lastSharedAt,
    this.lastConfirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_name'] = Variable<String>(householdName);
    map['medication'] = Variable<String>(medication);
    map['devices'] = Variable<String>(devices);
    map['allergies'] = Variable<String>(allergies);
    map['caregiving'] = Variable<String>(caregiving);
    map['documents'] = Variable<String>(documents);
    map['skipped'] = Variable<String>(skipped);
    map['wizard_step'] = Variable<int>(wizardStep);
    map['shared_version'] = Variable<int>(sharedVersion);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || lastSharedAt != null) {
      map['last_shared_at'] = Variable<DateTime>(lastSharedAt);
    }
    if (!nullToAbsent || lastConfirmedAt != null) {
      map['last_confirmed_at'] = Variable<DateTime>(lastConfirmedAt);
    }
    return map;
  }

  PlanMetaCompanion toCompanion(bool nullToAbsent) {
    return PlanMetaCompanion(
      id: Value(id),
      householdName: Value(householdName),
      medication: Value(medication),
      devices: Value(devices),
      allergies: Value(allergies),
      caregiving: Value(caregiving),
      documents: Value(documents),
      skipped: Value(skipped),
      wizardStep: Value(wizardStep),
      sharedVersion: Value(sharedVersion),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      lastSharedAt: lastSharedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSharedAt),
      lastConfirmedAt: lastConfirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConfirmedAt),
    );
  }

  factory PlanMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanMetaData(
      id: serializer.fromJson<int>(json['id']),
      householdName: serializer.fromJson<String>(json['householdName']),
      medication: serializer.fromJson<String>(json['medication']),
      devices: serializer.fromJson<String>(json['devices']),
      allergies: serializer.fromJson<String>(json['allergies']),
      caregiving: serializer.fromJson<String>(json['caregiving']),
      documents: serializer.fromJson<String>(json['documents']),
      skipped: serializer.fromJson<String>(json['skipped']),
      wizardStep: serializer.fromJson<int>(json['wizardStep']),
      sharedVersion: serializer.fromJson<int>(json['sharedVersion']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      lastSharedAt: serializer.fromJson<DateTime?>(json['lastSharedAt']),
      lastConfirmedAt: serializer.fromJson<DateTime?>(json['lastConfirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdName': serializer.toJson<String>(householdName),
      'medication': serializer.toJson<String>(medication),
      'devices': serializer.toJson<String>(devices),
      'allergies': serializer.toJson<String>(allergies),
      'caregiving': serializer.toJson<String>(caregiving),
      'documents': serializer.toJson<String>(documents),
      'skipped': serializer.toJson<String>(skipped),
      'wizardStep': serializer.toJson<int>(wizardStep),
      'sharedVersion': serializer.toJson<int>(sharedVersion),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'lastSharedAt': serializer.toJson<DateTime?>(lastSharedAt),
      'lastConfirmedAt': serializer.toJson<DateTime?>(lastConfirmedAt),
    };
  }

  PlanMetaData copyWith({
    int? id,
    String? householdName,
    String? medication,
    String? devices,
    String? allergies,
    String? caregiving,
    String? documents,
    String? skipped,
    int? wizardStep,
    int? sharedVersion,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> lastSharedAt = const Value.absent(),
    Value<DateTime?> lastConfirmedAt = const Value.absent(),
  }) => PlanMetaData(
    id: id ?? this.id,
    householdName: householdName ?? this.householdName,
    medication: medication ?? this.medication,
    devices: devices ?? this.devices,
    allergies: allergies ?? this.allergies,
    caregiving: caregiving ?? this.caregiving,
    documents: documents ?? this.documents,
    skipped: skipped ?? this.skipped,
    wizardStep: wizardStep ?? this.wizardStep,
    sharedVersion: sharedVersion ?? this.sharedVersion,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    lastSharedAt: lastSharedAt.present ? lastSharedAt.value : this.lastSharedAt,
    lastConfirmedAt: lastConfirmedAt.present
        ? lastConfirmedAt.value
        : this.lastConfirmedAt,
  );
  PlanMetaData copyWithCompanion(PlanMetaCompanion data) {
    return PlanMetaData(
      id: data.id.present ? data.id.value : this.id,
      householdName: data.householdName.present
          ? data.householdName.value
          : this.householdName,
      medication: data.medication.present
          ? data.medication.value
          : this.medication,
      devices: data.devices.present ? data.devices.value : this.devices,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      caregiving: data.caregiving.present
          ? data.caregiving.value
          : this.caregiving,
      documents: data.documents.present ? data.documents.value : this.documents,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      wizardStep: data.wizardStep.present
          ? data.wizardStep.value
          : this.wizardStep,
      sharedVersion: data.sharedVersion.present
          ? data.sharedVersion.value
          : this.sharedVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSharedAt: data.lastSharedAt.present
          ? data.lastSharedAt.value
          : this.lastSharedAt,
      lastConfirmedAt: data.lastConfirmedAt.present
          ? data.lastConfirmedAt.value
          : this.lastConfirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanMetaData(')
          ..write('id: $id, ')
          ..write('householdName: $householdName, ')
          ..write('medication: $medication, ')
          ..write('devices: $devices, ')
          ..write('allergies: $allergies, ')
          ..write('caregiving: $caregiving, ')
          ..write('documents: $documents, ')
          ..write('skipped: $skipped, ')
          ..write('wizardStep: $wizardStep, ')
          ..write('sharedVersion: $sharedVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSharedAt: $lastSharedAt, ')
          ..write('lastConfirmedAt: $lastConfirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdName,
    medication,
    devices,
    allergies,
    caregiving,
    documents,
    skipped,
    wizardStep,
    sharedVersion,
    createdAt,
    updatedAt,
    lastSharedAt,
    lastConfirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanMetaData &&
          other.id == this.id &&
          other.householdName == this.householdName &&
          other.medication == this.medication &&
          other.devices == this.devices &&
          other.allergies == this.allergies &&
          other.caregiving == this.caregiving &&
          other.documents == this.documents &&
          other.skipped == this.skipped &&
          other.wizardStep == this.wizardStep &&
          other.sharedVersion == this.sharedVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSharedAt == this.lastSharedAt &&
          other.lastConfirmedAt == this.lastConfirmedAt);
}

class PlanMetaCompanion extends UpdateCompanion<PlanMetaData> {
  final Value<int> id;
  final Value<String> householdName;
  final Value<String> medication;
  final Value<String> devices;
  final Value<String> allergies;
  final Value<String> caregiving;
  final Value<String> documents;
  final Value<String> skipped;
  final Value<int> wizardStep;
  final Value<int> sharedVersion;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> lastSharedAt;
  final Value<DateTime?> lastConfirmedAt;
  const PlanMetaCompanion({
    this.id = const Value.absent(),
    this.householdName = const Value.absent(),
    this.medication = const Value.absent(),
    this.devices = const Value.absent(),
    this.allergies = const Value.absent(),
    this.caregiving = const Value.absent(),
    this.documents = const Value.absent(),
    this.skipped = const Value.absent(),
    this.wizardStep = const Value.absent(),
    this.sharedVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSharedAt = const Value.absent(),
    this.lastConfirmedAt = const Value.absent(),
  });
  PlanMetaCompanion.insert({
    this.id = const Value.absent(),
    this.householdName = const Value.absent(),
    this.medication = const Value.absent(),
    this.devices = const Value.absent(),
    this.allergies = const Value.absent(),
    this.caregiving = const Value.absent(),
    this.documents = const Value.absent(),
    this.skipped = const Value.absent(),
    this.wizardStep = const Value.absent(),
    this.sharedVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSharedAt = const Value.absent(),
    this.lastConfirmedAt = const Value.absent(),
  });
  static Insertable<PlanMetaData> custom({
    Expression<int>? id,
    Expression<String>? householdName,
    Expression<String>? medication,
    Expression<String>? devices,
    Expression<String>? allergies,
    Expression<String>? caregiving,
    Expression<String>? documents,
    Expression<String>? skipped,
    Expression<int>? wizardStep,
    Expression<int>? sharedVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSharedAt,
    Expression<DateTime>? lastConfirmedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdName != null) 'household_name': householdName,
      if (medication != null) 'medication': medication,
      if (devices != null) 'devices': devices,
      if (allergies != null) 'allergies': allergies,
      if (caregiving != null) 'caregiving': caregiving,
      if (documents != null) 'documents': documents,
      if (skipped != null) 'skipped': skipped,
      if (wizardStep != null) 'wizard_step': wizardStep,
      if (sharedVersion != null) 'shared_version': sharedVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSharedAt != null) 'last_shared_at': lastSharedAt,
      if (lastConfirmedAt != null) 'last_confirmed_at': lastConfirmedAt,
    });
  }

  PlanMetaCompanion copyWith({
    Value<int>? id,
    Value<String>? householdName,
    Value<String>? medication,
    Value<String>? devices,
    Value<String>? allergies,
    Value<String>? caregiving,
    Value<String>? documents,
    Value<String>? skipped,
    Value<int>? wizardStep,
    Value<int>? sharedVersion,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? lastSharedAt,
    Value<DateTime?>? lastConfirmedAt,
  }) {
    return PlanMetaCompanion(
      id: id ?? this.id,
      householdName: householdName ?? this.householdName,
      medication: medication ?? this.medication,
      devices: devices ?? this.devices,
      allergies: allergies ?? this.allergies,
      caregiving: caregiving ?? this.caregiving,
      documents: documents ?? this.documents,
      skipped: skipped ?? this.skipped,
      wizardStep: wizardStep ?? this.wizardStep,
      sharedVersion: sharedVersion ?? this.sharedVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSharedAt: lastSharedAt ?? this.lastSharedAt,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdName.present) {
      map['household_name'] = Variable<String>(householdName.value);
    }
    if (medication.present) {
      map['medication'] = Variable<String>(medication.value);
    }
    if (devices.present) {
      map['devices'] = Variable<String>(devices.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (caregiving.present) {
      map['caregiving'] = Variable<String>(caregiving.value);
    }
    if (documents.present) {
      map['documents'] = Variable<String>(documents.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<String>(skipped.value);
    }
    if (wizardStep.present) {
      map['wizard_step'] = Variable<int>(wizardStep.value);
    }
    if (sharedVersion.present) {
      map['shared_version'] = Variable<int>(sharedVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSharedAt.present) {
      map['last_shared_at'] = Variable<DateTime>(lastSharedAt.value);
    }
    if (lastConfirmedAt.present) {
      map['last_confirmed_at'] = Variable<DateTime>(lastConfirmedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanMetaCompanion(')
          ..write('id: $id, ')
          ..write('householdName: $householdName, ')
          ..write('medication: $medication, ')
          ..write('devices: $devices, ')
          ..write('allergies: $allergies, ')
          ..write('caregiving: $caregiving, ')
          ..write('documents: $documents, ')
          ..write('skipped: $skipped, ')
          ..write('wizardStep: $wizardStep, ')
          ..write('sharedVersion: $sharedVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSharedAt: $lastSharedAt, ')
          ..write('lastConfirmedAt: $lastConfirmedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemRowsTable itemRows = $ItemRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  late final $PlanMembersTable planMembers = $PlanMembersTable(this);
  late final $PlanContactsTable planContacts = $PlanContactsTable(this);
  late final $PlanPlacesTable planPlaces = $PlanPlacesTable(this);
  late final $PlanAgreementsTable planAgreements = $PlanAgreementsTable(this);
  late final $PlanLocationsTable planLocations = $PlanLocationsTable(this);
  late final $PlanMetaTable planMeta = $PlanMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    itemRows,
    settingRows,
    planMembers,
    planContacts,
    planPlaces,
    planAgreements,
    planLocations,
    planMeta,
  ];
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
typedef $$PlanMembersTableCreateCompanionBuilder =
    PlanMembersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> kind,
      Value<String> ageGroup,
      Value<bool> needsHelp,
      Value<String> notes,
    });
typedef $$PlanMembersTableUpdateCompanionBuilder =
    PlanMembersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> kind,
      Value<String> ageGroup,
      Value<bool> needsHelp,
      Value<String> notes,
    });

class $$PlanMembersTableFilterComposer
    extends Composer<_$AppDatabase, $PlanMembersTable> {
  $$PlanMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageGroup => $composableBuilder(
    column: $table.ageGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsHelp => $composableBuilder(
    column: $table.needsHelp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanMembersTable> {
  $$PlanMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageGroup => $composableBuilder(
    column: $table.ageGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsHelp => $composableBuilder(
    column: $table.needsHelp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanMembersTable> {
  $$PlanMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ageGroup =>
      $composableBuilder(column: $table.ageGroup, builder: (column) => column);

  GeneratedColumn<bool> get needsHelp =>
      $composableBuilder(column: $table.needsHelp, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$PlanMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanMembersTable,
          PlanMember,
          $$PlanMembersTableFilterComposer,
          $$PlanMembersTableOrderingComposer,
          $$PlanMembersTableAnnotationComposer,
          $$PlanMembersTableCreateCompanionBuilder,
          $$PlanMembersTableUpdateCompanionBuilder,
          (
            PlanMember,
            BaseReferences<_$AppDatabase, $PlanMembersTable, PlanMember>,
          ),
          PlanMember,
          PrefetchHooks Function()
        > {
  $$PlanMembersTableTableManager(_$AppDatabase db, $PlanMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> ageGroup = const Value.absent(),
                Value<bool> needsHelp = const Value.absent(),
                Value<String> notes = const Value.absent(),
              }) => PlanMembersCompanion(
                id: id,
                name: name,
                kind: kind,
                ageGroup: ageGroup,
                needsHelp: needsHelp,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> ageGroup = const Value.absent(),
                Value<bool> needsHelp = const Value.absent(),
                Value<String> notes = const Value.absent(),
              }) => PlanMembersCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                ageGroup: ageGroup,
                needsHelp: needsHelp,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanMembersTable,
      PlanMember,
      $$PlanMembersTableFilterComposer,
      $$PlanMembersTableOrderingComposer,
      $$PlanMembersTableAnnotationComposer,
      $$PlanMembersTableCreateCompanionBuilder,
      $$PlanMembersTableUpdateCompanionBuilder,
      (
        PlanMember,
        BaseReferences<_$AppDatabase, $PlanMembersTable, PlanMember>,
      ),
      PlanMember,
      PrefetchHooks Function()
    >;
typedef $$PlanContactsTableCreateCompanionBuilder =
    PlanContactsCompanion Function({
      Value<int> id,
      required String role,
      Value<String> name,
      Value<String> relation,
      Value<String> phone,
    });
typedef $$PlanContactsTableUpdateCompanionBuilder =
    PlanContactsCompanion Function({
      Value<int> id,
      Value<String> role,
      Value<String> name,
      Value<String> relation,
      Value<String> phone,
    });

class $$PlanContactsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanContactsTable> {
  $$PlanContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanContactsTable> {
  $$PlanContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanContactsTable> {
  $$PlanContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);
}

class $$PlanContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanContactsTable,
          PlanContact,
          $$PlanContactsTableFilterComposer,
          $$PlanContactsTableOrderingComposer,
          $$PlanContactsTableAnnotationComposer,
          $$PlanContactsTableCreateCompanionBuilder,
          $$PlanContactsTableUpdateCompanionBuilder,
          (
            PlanContact,
            BaseReferences<_$AppDatabase, $PlanContactsTable, PlanContact>,
          ),
          PlanContact,
          PrefetchHooks Function()
        > {
  $$PlanContactsTableTableManager(_$AppDatabase db, $PlanContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> relation = const Value.absent(),
                Value<String> phone = const Value.absent(),
              }) => PlanContactsCompanion(
                id: id,
                role: role,
                name: name,
                relation: relation,
                phone: phone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String role,
                Value<String> name = const Value.absent(),
                Value<String> relation = const Value.absent(),
                Value<String> phone = const Value.absent(),
              }) => PlanContactsCompanion.insert(
                id: id,
                role: role,
                name: name,
                relation: relation,
                phone: phone,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanContactsTable,
      PlanContact,
      $$PlanContactsTableFilterComposer,
      $$PlanContactsTableOrderingComposer,
      $$PlanContactsTableAnnotationComposer,
      $$PlanContactsTableCreateCompanionBuilder,
      $$PlanContactsTableUpdateCompanionBuilder,
      (
        PlanContact,
        BaseReferences<_$AppDatabase, $PlanContactsTable, PlanContact>,
      ),
      PlanContact,
      PrefetchHooks Function()
    >;
typedef $$PlanPlacesTableCreateCompanionBuilder =
    PlanPlacesCompanion Function({
      required String kind,
      Value<String> address,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$PlanPlacesTableUpdateCompanionBuilder =
    PlanPlacesCompanion Function({
      Value<String> kind,
      Value<String> address,
      Value<String> notes,
      Value<int> rowid,
    });

class $$PlanPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanPlacesTable> {
  $$PlanPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanPlacesTable> {
  $$PlanPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanPlacesTable> {
  $$PlanPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$PlanPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanPlacesTable,
          PlanPlace,
          $$PlanPlacesTableFilterComposer,
          $$PlanPlacesTableOrderingComposer,
          $$PlanPlacesTableAnnotationComposer,
          $$PlanPlacesTableCreateCompanionBuilder,
          $$PlanPlacesTableUpdateCompanionBuilder,
          (
            PlanPlace,
            BaseReferences<_$AppDatabase, $PlanPlacesTable, PlanPlace>,
          ),
          PlanPlace,
          PrefetchHooks Function()
        > {
  $$PlanPlacesTableTableManager(_$AppDatabase db, $PlanPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanPlacesCompanion(
                kind: kind,
                address: address,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                Value<String> address = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanPlacesCompanion.insert(
                kind: kind,
                address: address,
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

typedef $$PlanPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanPlacesTable,
      PlanPlace,
      $$PlanPlacesTableFilterComposer,
      $$PlanPlacesTableOrderingComposer,
      $$PlanPlacesTableAnnotationComposer,
      $$PlanPlacesTableCreateCompanionBuilder,
      $$PlanPlacesTableUpdateCompanionBuilder,
      (PlanPlace, BaseReferences<_$AppDatabase, $PlanPlacesTable, PlanPlace>),
      PlanPlace,
      PrefetchHooks Function()
    >;
typedef $$PlanAgreementsTableCreateCompanionBuilder =
    PlanAgreementsCompanion Function({
      required String key,
      Value<String> body,
      Value<int> rowid,
    });
typedef $$PlanAgreementsTableUpdateCompanionBuilder =
    PlanAgreementsCompanion Function({
      Value<String> key,
      Value<String> body,
      Value<int> rowid,
    });

class $$PlanAgreementsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanAgreementsTable> {
  $$PlanAgreementsTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanAgreementsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanAgreementsTable> {
  $$PlanAgreementsTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanAgreementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanAgreementsTable> {
  $$PlanAgreementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$PlanAgreementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanAgreementsTable,
          PlanAgreement,
          $$PlanAgreementsTableFilterComposer,
          $$PlanAgreementsTableOrderingComposer,
          $$PlanAgreementsTableAnnotationComposer,
          $$PlanAgreementsTableCreateCompanionBuilder,
          $$PlanAgreementsTableUpdateCompanionBuilder,
          (
            PlanAgreement,
            BaseReferences<_$AppDatabase, $PlanAgreementsTable, PlanAgreement>,
          ),
          PlanAgreement,
          PrefetchHooks Function()
        > {
  $$PlanAgreementsTableTableManager(
    _$AppDatabase db,
    $PlanAgreementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanAgreementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanAgreementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanAgreementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanAgreementsCompanion(key: key, body: body, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanAgreementsCompanion.insert(
                key: key,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanAgreementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanAgreementsTable,
      PlanAgreement,
      $$PlanAgreementsTableFilterComposer,
      $$PlanAgreementsTableOrderingComposer,
      $$PlanAgreementsTableAnnotationComposer,
      $$PlanAgreementsTableCreateCompanionBuilder,
      $$PlanAgreementsTableUpdateCompanionBuilder,
      (
        PlanAgreement,
        BaseReferences<_$AppDatabase, $PlanAgreementsTable, PlanAgreement>,
      ),
      PlanAgreement,
      PrefetchHooks Function()
    >;
typedef $$PlanLocationsTableCreateCompanionBuilder =
    PlanLocationsCompanion Function({
      required String key,
      Value<String> body,
      Value<String?> photoPath,
      Value<int> rowid,
    });
typedef $$PlanLocationsTableUpdateCompanionBuilder =
    PlanLocationsCompanion Function({
      Value<String> key,
      Value<String> body,
      Value<String?> photoPath,
      Value<int> rowid,
    });

class $$PlanLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanLocationsTable> {
  $$PlanLocationsTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanLocationsTable> {
  $$PlanLocationsTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanLocationsTable> {
  $$PlanLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);
}

class $$PlanLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanLocationsTable,
          PlanLocation,
          $$PlanLocationsTableFilterComposer,
          $$PlanLocationsTableOrderingComposer,
          $$PlanLocationsTableAnnotationComposer,
          $$PlanLocationsTableCreateCompanionBuilder,
          $$PlanLocationsTableUpdateCompanionBuilder,
          (
            PlanLocation,
            BaseReferences<_$AppDatabase, $PlanLocationsTable, PlanLocation>,
          ),
          PlanLocation,
          PrefetchHooks Function()
        > {
  $$PlanLocationsTableTableManager(_$AppDatabase db, $PlanLocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanLocationsCompanion(
                key: key,
                body: body,
                photoPath: photoPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> body = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanLocationsCompanion.insert(
                key: key,
                body: body,
                photoPath: photoPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanLocationsTable,
      PlanLocation,
      $$PlanLocationsTableFilterComposer,
      $$PlanLocationsTableOrderingComposer,
      $$PlanLocationsTableAnnotationComposer,
      $$PlanLocationsTableCreateCompanionBuilder,
      $$PlanLocationsTableUpdateCompanionBuilder,
      (
        PlanLocation,
        BaseReferences<_$AppDatabase, $PlanLocationsTable, PlanLocation>,
      ),
      PlanLocation,
      PrefetchHooks Function()
    >;
typedef $$PlanMetaTableCreateCompanionBuilder =
    PlanMetaCompanion Function({
      Value<int> id,
      Value<String> householdName,
      Value<String> medication,
      Value<String> devices,
      Value<String> allergies,
      Value<String> caregiving,
      Value<String> documents,
      Value<String> skipped,
      Value<int> wizardStep,
      Value<int> sharedVersion,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> lastSharedAt,
      Value<DateTime?> lastConfirmedAt,
    });
typedef $$PlanMetaTableUpdateCompanionBuilder =
    PlanMetaCompanion Function({
      Value<int> id,
      Value<String> householdName,
      Value<String> medication,
      Value<String> devices,
      Value<String> allergies,
      Value<String> caregiving,
      Value<String> documents,
      Value<String> skipped,
      Value<int> wizardStep,
      Value<int> sharedVersion,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> lastSharedAt,
      Value<DateTime?> lastConfirmedAt,
    });

class $$PlanMetaTableFilterComposer
    extends Composer<_$AppDatabase, $PlanMetaTable> {
  $$PlanMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdName => $composableBuilder(
    column: $table.householdName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medication => $composableBuilder(
    column: $table.medication,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devices => $composableBuilder(
    column: $table.devices,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caregiving => $composableBuilder(
    column: $table.caregiving,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documents => $composableBuilder(
    column: $table.documents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wizardStep => $composableBuilder(
    column: $table.wizardStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sharedVersion => $composableBuilder(
    column: $table.sharedVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSharedAt => $composableBuilder(
    column: $table.lastSharedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastConfirmedAt => $composableBuilder(
    column: $table.lastConfirmedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanMetaTable> {
  $$PlanMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdName => $composableBuilder(
    column: $table.householdName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medication => $composableBuilder(
    column: $table.medication,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devices => $composableBuilder(
    column: $table.devices,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caregiving => $composableBuilder(
    column: $table.caregiving,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documents => $composableBuilder(
    column: $table.documents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wizardStep => $composableBuilder(
    column: $table.wizardStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sharedVersion => $composableBuilder(
    column: $table.sharedVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSharedAt => $composableBuilder(
    column: $table.lastSharedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastConfirmedAt => $composableBuilder(
    column: $table.lastConfirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanMetaTable> {
  $$PlanMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdName => $composableBuilder(
    column: $table.householdName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medication => $composableBuilder(
    column: $table.medication,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devices =>
      $composableBuilder(column: $table.devices, builder: (column) => column);

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get caregiving => $composableBuilder(
    column: $table.caregiving,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documents =>
      $composableBuilder(column: $table.documents, builder: (column) => column);

  GeneratedColumn<String> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<int> get wizardStep => $composableBuilder(
    column: $table.wizardStep,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sharedVersion => $composableBuilder(
    column: $table.sharedVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSharedAt => $composableBuilder(
    column: $table.lastSharedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastConfirmedAt => $composableBuilder(
    column: $table.lastConfirmedAt,
    builder: (column) => column,
  );
}

class $$PlanMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanMetaTable,
          PlanMetaData,
          $$PlanMetaTableFilterComposer,
          $$PlanMetaTableOrderingComposer,
          $$PlanMetaTableAnnotationComposer,
          $$PlanMetaTableCreateCompanionBuilder,
          $$PlanMetaTableUpdateCompanionBuilder,
          (
            PlanMetaData,
            BaseReferences<_$AppDatabase, $PlanMetaTable, PlanMetaData>,
          ),
          PlanMetaData,
          PrefetchHooks Function()
        > {
  $$PlanMetaTableTableManager(_$AppDatabase db, $PlanMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> householdName = const Value.absent(),
                Value<String> medication = const Value.absent(),
                Value<String> devices = const Value.absent(),
                Value<String> allergies = const Value.absent(),
                Value<String> caregiving = const Value.absent(),
                Value<String> documents = const Value.absent(),
                Value<String> skipped = const Value.absent(),
                Value<int> wizardStep = const Value.absent(),
                Value<int> sharedVersion = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> lastSharedAt = const Value.absent(),
                Value<DateTime?> lastConfirmedAt = const Value.absent(),
              }) => PlanMetaCompanion(
                id: id,
                householdName: householdName,
                medication: medication,
                devices: devices,
                allergies: allergies,
                caregiving: caregiving,
                documents: documents,
                skipped: skipped,
                wizardStep: wizardStep,
                sharedVersion: sharedVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSharedAt: lastSharedAt,
                lastConfirmedAt: lastConfirmedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> householdName = const Value.absent(),
                Value<String> medication = const Value.absent(),
                Value<String> devices = const Value.absent(),
                Value<String> allergies = const Value.absent(),
                Value<String> caregiving = const Value.absent(),
                Value<String> documents = const Value.absent(),
                Value<String> skipped = const Value.absent(),
                Value<int> wizardStep = const Value.absent(),
                Value<int> sharedVersion = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> lastSharedAt = const Value.absent(),
                Value<DateTime?> lastConfirmedAt = const Value.absent(),
              }) => PlanMetaCompanion.insert(
                id: id,
                householdName: householdName,
                medication: medication,
                devices: devices,
                allergies: allergies,
                caregiving: caregiving,
                documents: documents,
                skipped: skipped,
                wizardStep: wizardStep,
                sharedVersion: sharedVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSharedAt: lastSharedAt,
                lastConfirmedAt: lastConfirmedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanMetaTable,
      PlanMetaData,
      $$PlanMetaTableFilterComposer,
      $$PlanMetaTableOrderingComposer,
      $$PlanMetaTableAnnotationComposer,
      $$PlanMetaTableCreateCompanionBuilder,
      $$PlanMetaTableUpdateCompanionBuilder,
      (
        PlanMetaData,
        BaseReferences<_$AppDatabase, $PlanMetaTable, PlanMetaData>,
      ),
      PlanMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemRowsTableTableManager get itemRows =>
      $$ItemRowsTableTableManager(_db, _db.itemRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
  $$PlanMembersTableTableManager get planMembers =>
      $$PlanMembersTableTableManager(_db, _db.planMembers);
  $$PlanContactsTableTableManager get planContacts =>
      $$PlanContactsTableTableManager(_db, _db.planContacts);
  $$PlanPlacesTableTableManager get planPlaces =>
      $$PlanPlacesTableTableManager(_db, _db.planPlaces);
  $$PlanAgreementsTableTableManager get planAgreements =>
      $$PlanAgreementsTableTableManager(_db, _db.planAgreements);
  $$PlanLocationsTableTableManager get planLocations =>
      $$PlanLocationsTableTableManager(_db, _db.planLocations);
  $$PlanMetaTableTableManager get planMeta =>
      $$PlanMetaTableTableManager(_db, _db.planMeta);
}
