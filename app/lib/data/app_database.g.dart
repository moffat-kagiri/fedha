// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<double, double> amountMinor =
      GeneratedColumn<double>(
        'amount_minor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      ).withConverter<double>($TransactionsTable.$converteramountMinor);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isExpenseMeta = const VerificationMeta(
    'isExpense',
  );
  @override
  late final GeneratedColumn<bool> isExpense = GeneratedColumn<bool>(
    'is_expense',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expense" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _rawSmsMeta = const VerificationMeta('rawSms');
  @override
  late final GeneratedColumn<String> rawSms = GeneratedColumn<String>(
    'raw_sms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountMinor,
    currency,
    description,
    categoryId,
    date,
    isExpense,
    rawSms,
    profileId,
    goalId,
    transactionType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_expense')) {
      context.handle(
        _isExpenseMeta,
        isExpense.isAcceptableOrUnknown(data['is_expense']!, _isExpenseMeta),
      );
    }
    if (data.containsKey('raw_sms')) {
      context.handle(
        _rawSmsMeta,
        rawSms.isAcceptableOrUnknown(data['raw_sms']!, _rawSmsMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountMinor: $TransactionsTable.$converteramountMinor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}amount_minor'],
        )!,
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expense'],
      )!,
      rawSms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sms'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<double, double> $converteramountMinor =
      const _DecimalConverter();
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final double amountMinor;
  final String currency;
  final String description;
  final String categoryId;
  final DateTime date;
  final bool isExpense;
  final String? rawSms;
  final int profileId;
  final String? goalId;
  final String transactionType;
  const Transaction({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.description,
    required this.categoryId,
    required this.date,
    required this.isExpense,
    this.rawSms,
    required this.profileId,
    this.goalId,
    required this.transactionType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['amount_minor'] = Variable<double>(
        $TransactionsTable.$converteramountMinor.toSql(amountMinor),
      );
    }
    map['currency'] = Variable<String>(currency);
    map['description'] = Variable<String>(description);
    map['category_id'] = Variable<String>(categoryId);
    map['date'] = Variable<DateTime>(date);
    map['is_expense'] = Variable<bool>(isExpense);
    if (!nullToAbsent || rawSms != null) {
      map['raw_sms'] = Variable<String>(rawSms);
    }
    map['profile_id'] = Variable<int>(profileId);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    map['transaction_type'] = Variable<String>(transactionType);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      description: Value(description),
      categoryId: Value(categoryId),
      date: Value(date),
      isExpense: Value(isExpense),
      rawSms: rawSms == null && nullToAbsent
          ? const Value.absent()
          : Value(rawSms),
      profileId: Value(profileId),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      transactionType: Value(transactionType),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      amountMinor: serializer.fromJson<double>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      description: serializer.fromJson<String>(json['description']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      date: serializer.fromJson<DateTime>(json['date']),
      isExpense: serializer.fromJson<bool>(json['isExpense']),
      rawSms: serializer.fromJson<String?>(json['rawSms']),
      profileId: serializer.fromJson<int>(json['profileId']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMinor': serializer.toJson<double>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'description': serializer.toJson<String>(description),
      'categoryId': serializer.toJson<String>(categoryId),
      'date': serializer.toJson<DateTime>(date),
      'isExpense': serializer.toJson<bool>(isExpense),
      'rawSms': serializer.toJson<String?>(rawSms),
      'profileId': serializer.toJson<int>(profileId),
      'goalId': serializer.toJson<String?>(goalId),
      'transactionType': serializer.toJson<String>(transactionType),
    };
  }

  Transaction copyWith({
    int? id,
    double? amountMinor,
    String? currency,
    String? description,
    String? categoryId,
    DateTime? date,
    bool? isExpense,
    Value<String?> rawSms = const Value.absent(),
    int? profileId,
    Value<String?> goalId = const Value.absent(),
    String? transactionType,
  }) => Transaction(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    date: date ?? this.date,
    isExpense: isExpense ?? this.isExpense,
    rawSms: rawSms.present ? rawSms.value : this.rawSms,
    profileId: profileId ?? this.profileId,
    goalId: goalId.present ? goalId.value : this.goalId,
    transactionType: transactionType ?? this.transactionType,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      description: data.description.present
          ? data.description.value
          : this.description,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      date: data.date.present ? data.date.value : this.date,
      isExpense: data.isExpense.present ? data.isExpense.value : this.isExpense,
      rawSms: data.rawSms.present ? data.rawSms.value : this.rawSms,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('isExpense: $isExpense, ')
          ..write('rawSms: $rawSms, ')
          ..write('profileId: $profileId, ')
          ..write('goalId: $goalId, ')
          ..write('transactionType: $transactionType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountMinor,
    currency,
    description,
    categoryId,
    date,
    isExpense,
    rawSms,
    profileId,
    goalId,
    transactionType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.date == this.date &&
          other.isExpense == this.isExpense &&
          other.rawSms == this.rawSms &&
          other.profileId == this.profileId &&
          other.goalId == this.goalId &&
          other.transactionType == this.transactionType);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<double> amountMinor;
  final Value<String> currency;
  final Value<String> description;
  final Value<String> categoryId;
  final Value<DateTime> date;
  final Value<bool> isExpense;
  final Value<String?> rawSms;
  final Value<int> profileId;
  final Value<String?> goalId;
  final Value<String> transactionType;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.date = const Value.absent(),
    this.isExpense = const Value.absent(),
    this.rawSms = const Value.absent(),
    this.profileId = const Value.absent(),
    this.goalId = const Value.absent(),
    this.transactionType = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amountMinor,
    required String currency,
    required String description,
    this.categoryId = const Value.absent(),
    required DateTime date,
    this.isExpense = const Value.absent(),
    this.rawSms = const Value.absent(),
    required int profileId,
    this.goalId = const Value.absent(),
    this.transactionType = const Value.absent(),
  }) : amountMinor = Value(amountMinor),
       currency = Value(currency),
       description = Value(description),
       date = Value(date),
       profileId = Value(profileId);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<double>? amountMinor,
    Expression<String>? currency,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<DateTime>? date,
    Expression<bool>? isExpense,
    Expression<String>? rawSms,
    Expression<int>? profileId,
    Expression<String>? goalId,
    Expression<String>? transactionType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (date != null) 'date': date,
      if (isExpense != null) 'is_expense': isExpense,
      if (rawSms != null) 'raw_sms': rawSms,
      if (profileId != null) 'profile_id': profileId,
      if (goalId != null) 'goal_id': goalId,
      if (transactionType != null) 'transaction_type': transactionType,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amountMinor,
    Value<String>? currency,
    Value<String>? description,
    Value<String>? categoryId,
    Value<DateTime>? date,
    Value<bool>? isExpense,
    Value<String?>? rawSms,
    Value<int>? profileId,
    Value<String?>? goalId,
    Value<String>? transactionType,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      rawSms: rawSms ?? this.rawSms,
      profileId: profileId ?? this.profileId,
      goalId: goalId ?? this.goalId,
      transactionType: transactionType ?? this.transactionType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<double>(
        $TransactionsTable.$converteramountMinor.toSql(amountMinor.value),
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isExpense.present) {
      map['is_expense'] = Variable<bool>(isExpense.value);
    }
    if (rawSms.present) {
      map['raw_sms'] = Variable<String>(rawSms.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('isExpense: $isExpense, ')
          ..write('rawSms: $rawSms, ')
          ..write('profileId: $profileId, ')
          ..write('goalId: $goalId, ')
          ..write('transactionType: $transactionType')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<double, double> targetMinor =
      GeneratedColumn<double>(
        'target_minor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      ).withConverter<double>($GoalsTable.$convertertargetMinor);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentMinorMeta = const VerificationMeta(
    'currentMinor',
  );
  @override
  late final GeneratedColumn<double> currentMinor = GeneratedColumn<double>(
    'current_minor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    targetMinor,
    currency,
    dueDate,
    completed,
    profileId,
    currentMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('current_minor')) {
      context.handle(
        _currentMinorMeta,
        currentMinor.isAcceptableOrUnknown(
          data['current_minor']!,
          _currentMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetMinor: $GoalsTable.$convertertargetMinor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}target_minor'],
        )!,
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      currentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_minor'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<double, double> $convertertargetMinor =
      const _DecimalConverter();
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String title;
  final double targetMinor;
  final String currency;
  final DateTime dueDate;
  final bool completed;
  final int profileId;
  final double currentMinor;
  const Goal({
    required this.id,
    required this.title,
    required this.targetMinor,
    required this.currency,
    required this.dueDate,
    required this.completed,
    required this.profileId,
    required this.currentMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    {
      map['target_minor'] = Variable<double>(
        $GoalsTable.$convertertargetMinor.toSql(targetMinor),
      );
    }
    map['currency'] = Variable<String>(currency);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['completed'] = Variable<bool>(completed);
    map['profile_id'] = Variable<int>(profileId);
    map['current_minor'] = Variable<double>(currentMinor);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      targetMinor: Value(targetMinor),
      currency: Value(currency),
      dueDate: Value(dueDate),
      completed: Value(completed),
      profileId: Value(profileId),
      currentMinor: Value(currentMinor),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetMinor: serializer.fromJson<double>(json['targetMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      completed: serializer.fromJson<bool>(json['completed']),
      profileId: serializer.fromJson<int>(json['profileId']),
      currentMinor: serializer.fromJson<double>(json['currentMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'targetMinor': serializer.toJson<double>(targetMinor),
      'currency': serializer.toJson<String>(currency),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'completed': serializer.toJson<bool>(completed),
      'profileId': serializer.toJson<int>(profileId),
      'currentMinor': serializer.toJson<double>(currentMinor),
    };
  }

  Goal copyWith({
    int? id,
    String? title,
    double? targetMinor,
    String? currency,
    DateTime? dueDate,
    bool? completed,
    int? profileId,
    double? currentMinor,
  }) => Goal(
    id: id ?? this.id,
    title: title ?? this.title,
    targetMinor: targetMinor ?? this.targetMinor,
    currency: currency ?? this.currency,
    dueDate: dueDate ?? this.dueDate,
    completed: completed ?? this.completed,
    profileId: profileId ?? this.profileId,
    currentMinor: currentMinor ?? this.currentMinor,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetMinor: data.targetMinor.present
          ? data.targetMinor.value
          : this.targetMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      completed: data.completed.present ? data.completed.value : this.completed,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      currentMinor: data.currentMinor.present
          ? data.currentMinor.value
          : this.currentMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('currency: $currency, ')
          ..write('dueDate: $dueDate, ')
          ..write('completed: $completed, ')
          ..write('profileId: $profileId, ')
          ..write('currentMinor: $currentMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    targetMinor,
    currency,
    dueDate,
    completed,
    profileId,
    currentMinor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetMinor == this.targetMinor &&
          other.currency == this.currency &&
          other.dueDate == this.dueDate &&
          other.completed == this.completed &&
          other.profileId == this.profileId &&
          other.currentMinor == this.currentMinor);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> title;
  final Value<double> targetMinor;
  final Value<String> currency;
  final Value<DateTime> dueDate;
  final Value<bool> completed;
  final Value<int> profileId;
  final Value<double> currentMinor;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completed = const Value.absent(),
    this.profileId = const Value.absent(),
    this.currentMinor = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required double targetMinor,
    required String currency,
    required DateTime dueDate,
    this.completed = const Value.absent(),
    required int profileId,
    this.currentMinor = const Value.absent(),
  }) : title = Value(title),
       targetMinor = Value(targetMinor),
       currency = Value(currency),
       dueDate = Value(dueDate),
       profileId = Value(profileId);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<double>? targetMinor,
    Expression<String>? currency,
    Expression<DateTime>? dueDate,
    Expression<bool>? completed,
    Expression<int>? profileId,
    Expression<double>? currentMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetMinor != null) 'target_minor': targetMinor,
      if (currency != null) 'currency': currency,
      if (dueDate != null) 'due_date': dueDate,
      if (completed != null) 'completed': completed,
      if (profileId != null) 'profile_id': profileId,
      if (currentMinor != null) 'current_minor': currentMinor,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<double>? targetMinor,
    Value<String>? currency,
    Value<DateTime>? dueDate,
    Value<bool>? completed,
    Value<int>? profileId,
    Value<double>? currentMinor,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetMinor: targetMinor ?? this.targetMinor,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      profileId: profileId ?? this.profileId,
      currentMinor: currentMinor ?? this.currentMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetMinor.present) {
      map['target_minor'] = Variable<double>(
        $GoalsTable.$convertertargetMinor.toSql(targetMinor.value),
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (currentMinor.present) {
      map['current_minor'] = Variable<double>(currentMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('currency: $currency, ')
          ..write('dueDate: $dueDate, ')
          ..write('completed: $completed, ')
          ..write('profileId: $profileId, ')
          ..write('currentMinor: $currentMinor')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalMinorMeta = const VerificationMeta(
    'principalMinor',
  );
  @override
  late final GeneratedColumn<int> principalMinor = GeneratedColumn<int>(
    'principal_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KES'),
  );
  static const VerificationMeta _interestRateMeta = const VerificationMeta(
    'interestRate',
  );
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    principalMinor,
    currency,
    interestRate,
    startDate,
    endDate,
    profileId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Loan> instance, {
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
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('principal_minor')) {
      context.handle(
        _principalMinorMeta,
        principalMinor.isAcceptableOrUnknown(
          data['principal_minor']!,
          _principalMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
        _interestRateMeta,
        interestRate.isAcceptableOrUnknown(
          data['interest_rate']!,
          _interestRateMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      principalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class Loan extends DataClass implements Insertable<Loan> {
  final int id;
  final String name;
  final int principalMinor;
  final String currency;
  final double interestRate;
  final DateTime startDate;
  final DateTime endDate;
  final int profileId;
  const Loan({
    required this.id,
    required this.name,
    required this.principalMinor,
    required this.currency,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['principal_minor'] = Variable<int>(principalMinor);
    map['currency'] = Variable<String>(currency);
    map['interest_rate'] = Variable<double>(interestRate);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['profile_id'] = Variable<int>(profileId);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      name: Value(name),
      principalMinor: Value(principalMinor),
      currency: Value(currency),
      interestRate: Value(interestRate),
      startDate: Value(startDate),
      endDate: Value(endDate),
      profileId: Value(profileId),
    );
  }

  factory Loan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      principalMinor: serializer.fromJson<int>(json['principalMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      interestRate: serializer.fromJson<double>(json['interestRate']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      profileId: serializer.fromJson<int>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'principalMinor': serializer.toJson<int>(principalMinor),
      'currency': serializer.toJson<String>(currency),
      'interestRate': serializer.toJson<double>(interestRate),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'profileId': serializer.toJson<int>(profileId),
    };
  }

  Loan copyWith({
    int? id,
    String? name,
    int? principalMinor,
    String? currency,
    double? interestRate,
    DateTime? startDate,
    DateTime? endDate,
    int? profileId,
  }) => Loan(
    id: id ?? this.id,
    name: name ?? this.name,
    principalMinor: principalMinor ?? this.principalMinor,
    currency: currency ?? this.currency,
    interestRate: interestRate ?? this.interestRate,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    profileId: profileId ?? this.profileId,
  );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      principalMinor: data.principalMinor.present
          ? data.principalMinor.value
          : this.principalMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('principalMinor: $principalMinor, ')
          ..write('currency: $currency, ')
          ..write('interestRate: $interestRate, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    principalMinor,
    currency,
    interestRate,
    startDate,
    endDate,
    profileId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.name == this.name &&
          other.principalMinor == this.principalMinor &&
          other.currency == this.currency &&
          other.interestRate == this.interestRate &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.profileId == this.profileId);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> principalMinor;
  final Value<String> currency;
  final Value<double> interestRate;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<int> profileId;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.principalMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.profileId = const Value.absent(),
  });
  LoansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int principalMinor,
    this.currency = const Value.absent(),
    this.interestRate = const Value.absent(),
    required DateTime startDate,
    required DateTime endDate,
    required int profileId,
  }) : name = Value(name),
       principalMinor = Value(principalMinor),
       startDate = Value(startDate),
       endDate = Value(endDate),
       profileId = Value(profileId);
  static Insertable<Loan> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? principalMinor,
    Expression<String>? currency,
    Expression<double>? interestRate,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? profileId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (principalMinor != null) 'principal_minor': principalMinor,
      if (currency != null) 'currency': currency,
      if (interestRate != null) 'interest_rate': interestRate,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (profileId != null) 'profile_id': profileId,
    });
  }

  LoansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? principalMinor,
    Value<String>? currency,
    Value<double>? interestRate,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<int>? profileId,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      principalMinor: principalMinor ?? this.principalMinor,
      currency: currency ?? this.currency,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      profileId: profileId ?? this.profileId,
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
    if (principalMinor.present) {
      map['principal_minor'] = Variable<int>(principalMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('principalMinor: $principalMinor, ')
          ..write('currency: $currency, ')
          ..write('interestRate: $interestRate, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }
}

class $PendingTransactionsTable extends PendingTransactions
    with TableInfo<$PendingTransactionsTable, PendingTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<double, double> amountMinor =
      GeneratedColumn<double>(
        'amount_minor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      ).withConverter<double>($PendingTransactionsTable.$converteramountMinor);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KES'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isExpenseMeta = const VerificationMeta(
    'isExpense',
  );
  @override
  late final GeneratedColumn<bool> isExpense = GeneratedColumn<bool>(
    'is_expense',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expense" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _rawSmsMeta = const VerificationMeta('rawSms');
  @override
  late final GeneratedColumn<String> rawSms = GeneratedColumn<String>(
    'raw_sms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountMinor,
    currency,
    description,
    date,
    isExpense,
    rawSms,
    profileId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_expense')) {
      context.handle(
        _isExpenseMeta,
        isExpense.isAcceptableOrUnknown(data['is_expense']!, _isExpenseMeta),
      );
    }
    if (data.containsKey('raw_sms')) {
      context.handle(
        _rawSmsMeta,
        rawSms.isAcceptableOrUnknown(data['raw_sms']!, _rawSmsMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amountMinor: $PendingTransactionsTable.$converteramountMinor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}amount_minor'],
        )!,
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expense'],
      )!,
      rawSms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sms'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
    );
  }

  @override
  $PendingTransactionsTable createAlias(String alias) {
    return $PendingTransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<double, double> $converteramountMinor =
      const _DecimalConverter();
}

class PendingTransaction extends DataClass
    implements Insertable<PendingTransaction> {
  final String id;
  final double amountMinor;
  final String currency;
  final String? description;
  final DateTime date;
  final bool isExpense;
  final String? rawSms;
  final int profileId;
  const PendingTransaction({
    required this.id,
    required this.amountMinor,
    required this.currency,
    this.description,
    required this.date,
    required this.isExpense,
    this.rawSms,
    required this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['amount_minor'] = Variable<double>(
        $PendingTransactionsTable.$converteramountMinor.toSql(amountMinor),
      );
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['date'] = Variable<DateTime>(date);
    map['is_expense'] = Variable<bool>(isExpense);
    if (!nullToAbsent || rawSms != null) {
      map['raw_sms'] = Variable<String>(rawSms);
    }
    map['profile_id'] = Variable<int>(profileId);
    return map;
  }

  PendingTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PendingTransactionsCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      date: Value(date),
      isExpense: Value(isExpense),
      rawSms: rawSms == null && nullToAbsent
          ? const Value.absent()
          : Value(rawSms),
      profileId: Value(profileId),
    );
  }

  factory PendingTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingTransaction(
      id: serializer.fromJson<String>(json['id']),
      amountMinor: serializer.fromJson<double>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      description: serializer.fromJson<String?>(json['description']),
      date: serializer.fromJson<DateTime>(json['date']),
      isExpense: serializer.fromJson<bool>(json['isExpense']),
      rawSms: serializer.fromJson<String?>(json['rawSms']),
      profileId: serializer.fromJson<int>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amountMinor': serializer.toJson<double>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'description': serializer.toJson<String?>(description),
      'date': serializer.toJson<DateTime>(date),
      'isExpense': serializer.toJson<bool>(isExpense),
      'rawSms': serializer.toJson<String?>(rawSms),
      'profileId': serializer.toJson<int>(profileId),
    };
  }

  PendingTransaction copyWith({
    String? id,
    double? amountMinor,
    String? currency,
    Value<String?> description = const Value.absent(),
    DateTime? date,
    bool? isExpense,
    Value<String?> rawSms = const Value.absent(),
    int? profileId,
  }) => PendingTransaction(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    description: description.present ? description.value : this.description,
    date: date ?? this.date,
    isExpense: isExpense ?? this.isExpense,
    rawSms: rawSms.present ? rawSms.value : this.rawSms,
    profileId: profileId ?? this.profileId,
  );
  PendingTransaction copyWithCompanion(PendingTransactionsCompanion data) {
    return PendingTransaction(
      id: data.id.present ? data.id.value : this.id,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      description: data.description.present
          ? data.description.value
          : this.description,
      date: data.date.present ? data.date.value : this.date,
      isExpense: data.isExpense.present ? data.isExpense.value : this.isExpense,
      rawSms: data.rawSms.present ? data.rawSms.value : this.rawSms,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransaction(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('isExpense: $isExpense, ')
          ..write('rawSms: $rawSms, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountMinor,
    currency,
    description,
    date,
    isExpense,
    rawSms,
    profileId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingTransaction &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.description == this.description &&
          other.date == this.date &&
          other.isExpense == this.isExpense &&
          other.rawSms == this.rawSms &&
          other.profileId == this.profileId);
}

class PendingTransactionsCompanion extends UpdateCompanion<PendingTransaction> {
  final Value<String> id;
  final Value<double> amountMinor;
  final Value<String> currency;
  final Value<String?> description;
  final Value<DateTime> date;
  final Value<bool> isExpense;
  final Value<String?> rawSms;
  final Value<int> profileId;
  final Value<int> rowid;
  const PendingTransactionsCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.date = const Value.absent(),
    this.isExpense = const Value.absent(),
    this.rawSms = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingTransactionsCompanion.insert({
    required String id,
    required double amountMinor,
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime date,
    this.isExpense = const Value.absent(),
    this.rawSms = const Value.absent(),
    required int profileId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountMinor = Value(amountMinor),
       date = Value(date),
       profileId = Value(profileId);
  static Insertable<PendingTransaction> custom({
    Expression<String>? id,
    Expression<double>? amountMinor,
    Expression<String>? currency,
    Expression<String>? description,
    Expression<DateTime>? date,
    Expression<bool>? isExpense,
    Expression<String>? rawSms,
    Expression<int>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (isExpense != null) 'is_expense': isExpense,
      if (rawSms != null) 'raw_sms': rawSms,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingTransactionsCompanion copyWith({
    Value<String>? id,
    Value<double>? amountMinor,
    Value<String>? currency,
    Value<String?>? description,
    Value<DateTime>? date,
    Value<bool>? isExpense,
    Value<String?>? rawSms,
    Value<int>? profileId,
    Value<int>? rowid,
  }) {
    return PendingTransactionsCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      rawSms: rawSms ?? this.rawSms,
      profileId: profileId ?? this.profileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<double>(
        $PendingTransactionsTable.$converteramountMinor.toSql(
          amountMinor.value,
        ),
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isExpense.present) {
      map['is_expense'] = Variable<bool>(isExpense.value);
    }
    if (rawSms.present) {
      map['raw_sms'] = Variable<String>(rawSms.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('isExpense: $isExpense, ')
          ..write('rawSms: $rawSms, ')
          ..write('profileId: $profileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RiskAssessmentsTable extends RiskAssessments
    with TableInfo<$RiskAssessmentsTable, RiskAssessment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RiskAssessmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeRatioMeta = const VerificationMeta(
    'incomeRatio',
  );
  @override
  late final GeneratedColumn<double> incomeRatio = GeneratedColumn<double>(
    'income_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: Constant(50.0),
  );
  static const VerificationMeta _desiredReturnRatioMeta =
      const VerificationMeta('desiredReturnRatio');
  @override
  late final GeneratedColumn<double> desiredReturnRatio =
      GeneratedColumn<double>(
        'desired_return_ratio',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: Constant(50.0),
      );
  static const VerificationMeta _timeHorizonMeta = const VerificationMeta(
    'timeHorizon',
  );
  @override
  late final GeneratedColumn<int> timeHorizon = GeneratedColumn<int>(
    'time_horizon',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(5),
  );
  static const VerificationMeta _lossToleranceIndexMeta =
      const VerificationMeta('lossToleranceIndex');
  @override
  late final GeneratedColumn<int> lossToleranceIndex = GeneratedColumn<int>(
    'loss_tolerance_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _experienceIndexMeta = const VerificationMeta(
    'experienceIndex',
  );
  @override
  late final GeneratedColumn<int> experienceIndex = GeneratedColumn<int>(
    'experience_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volatilityReactionIndexMeta =
      const VerificationMeta('volatilityReactionIndex');
  @override
  late final GeneratedColumn<int> volatilityReactionIndex =
      GeneratedColumn<int>(
        'volatility_reaction_index',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _liquidityNeedIndexMeta =
      const VerificationMeta('liquidityNeedIndex');
  @override
  late final GeneratedColumn<int> liquidityNeedIndex = GeneratedColumn<int>(
    'liquidity_need_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyFundMonthsMeta =
      const VerificationMeta('emergencyFundMonths');
  @override
  late final GeneratedColumn<int> emergencyFundMonths = GeneratedColumn<int>(
    'emergency_fund_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(3),
  );
  static const VerificationMeta _riskScoreMeta = const VerificationMeta(
    'riskScore',
  );
  @override
  late final GeneratedColumn<double> riskScore = GeneratedColumn<double>(
    'risk_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: Constant(0.0),
  );
  static const VerificationMeta _profileMeta = const VerificationMeta(
    'profile',
  );
  @override
  late final GeneratedColumn<String> profile = GeneratedColumn<String>(
    'profile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allocationJsonMeta = const VerificationMeta(
    'allocationJson',
  );
  @override
  late final GeneratedColumn<String> allocationJson = GeneratedColumn<String>(
    'allocation_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answersJsonMeta = const VerificationMeta(
    'answersJson',
  );
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
    'answers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    userId,
    goal,
    incomeRatio,
    desiredReturnRatio,
    timeHorizon,
    lossToleranceIndex,
    experienceIndex,
    volatilityReactionIndex,
    liquidityNeedIndex,
    emergencyFundMonths,
    riskScore,
    profile,
    allocationJson,
    answersJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'risk_assessments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RiskAssessment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    }
    if (data.containsKey('income_ratio')) {
      context.handle(
        _incomeRatioMeta,
        incomeRatio.isAcceptableOrUnknown(
          data['income_ratio']!,
          _incomeRatioMeta,
        ),
      );
    }
    if (data.containsKey('desired_return_ratio')) {
      context.handle(
        _desiredReturnRatioMeta,
        desiredReturnRatio.isAcceptableOrUnknown(
          data['desired_return_ratio']!,
          _desiredReturnRatioMeta,
        ),
      );
    }
    if (data.containsKey('time_horizon')) {
      context.handle(
        _timeHorizonMeta,
        timeHorizon.isAcceptableOrUnknown(
          data['time_horizon']!,
          _timeHorizonMeta,
        ),
      );
    }
    if (data.containsKey('loss_tolerance_index')) {
      context.handle(
        _lossToleranceIndexMeta,
        lossToleranceIndex.isAcceptableOrUnknown(
          data['loss_tolerance_index']!,
          _lossToleranceIndexMeta,
        ),
      );
    }
    if (data.containsKey('experience_index')) {
      context.handle(
        _experienceIndexMeta,
        experienceIndex.isAcceptableOrUnknown(
          data['experience_index']!,
          _experienceIndexMeta,
        ),
      );
    }
    if (data.containsKey('volatility_reaction_index')) {
      context.handle(
        _volatilityReactionIndexMeta,
        volatilityReactionIndex.isAcceptableOrUnknown(
          data['volatility_reaction_index']!,
          _volatilityReactionIndexMeta,
        ),
      );
    }
    if (data.containsKey('liquidity_need_index')) {
      context.handle(
        _liquidityNeedIndexMeta,
        liquidityNeedIndex.isAcceptableOrUnknown(
          data['liquidity_need_index']!,
          _liquidityNeedIndexMeta,
        ),
      );
    }
    if (data.containsKey('emergency_fund_months')) {
      context.handle(
        _emergencyFundMonthsMeta,
        emergencyFundMonths.isAcceptableOrUnknown(
          data['emergency_fund_months']!,
          _emergencyFundMonthsMeta,
        ),
      );
    }
    if (data.containsKey('risk_score')) {
      context.handle(
        _riskScoreMeta,
        riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta),
      );
    }
    if (data.containsKey('profile')) {
      context.handle(
        _profileMeta,
        profile.isAcceptableOrUnknown(data['profile']!, _profileMeta),
      );
    }
    if (data.containsKey('allocation_json')) {
      context.handle(
        _allocationJsonMeta,
        allocationJson.isAcceptableOrUnknown(
          data['allocation_json']!,
          _allocationJsonMeta,
        ),
      );
    }
    if (data.containsKey('answers_json')) {
      context.handle(
        _answersJsonMeta,
        answersJson.isAcceptableOrUnknown(
          data['answers_json']!,
          _answersJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RiskAssessment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RiskAssessment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      ),
      incomeRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}income_ratio'],
      )!,
      desiredReturnRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}desired_return_ratio'],
      )!,
      timeHorizon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_horizon'],
      )!,
      lossToleranceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loss_tolerance_index'],
      ),
      experienceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}experience_index'],
      ),
      volatilityReactionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volatility_reaction_index'],
      ),
      liquidityNeedIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}liquidity_need_index'],
      ),
      emergencyFundMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}emergency_fund_months'],
      )!,
      riskScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk_score'],
      )!,
      profile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile'],
      ),
      allocationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allocation_json'],
      ),
      answersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers_json'],
      ),
    );
  }

  @override
  $RiskAssessmentsTable createAlias(String alias) {
    return $RiskAssessmentsTable(attachedDatabase, alias);
  }
}

class RiskAssessment extends DataClass implements Insertable<RiskAssessment> {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final String? goal;
  final double incomeRatio;
  final double desiredReturnRatio;
  final int timeHorizon;
  final int? lossToleranceIndex;
  final int? experienceIndex;
  final int? volatilityReactionIndex;
  final int? liquidityNeedIndex;
  final int emergencyFundMonths;
  final double riskScore;
  final String? profile;
  final String? allocationJson;
  final String? answersJson;
  const RiskAssessment({
    required this.id,
    required this.createdAt,
    this.userId,
    this.goal,
    required this.incomeRatio,
    required this.desiredReturnRatio,
    required this.timeHorizon,
    this.lossToleranceIndex,
    this.experienceIndex,
    this.volatilityReactionIndex,
    this.liquidityNeedIndex,
    required this.emergencyFundMonths,
    required this.riskScore,
    this.profile,
    this.allocationJson,
    this.answersJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || goal != null) {
      map['goal'] = Variable<String>(goal);
    }
    map['income_ratio'] = Variable<double>(incomeRatio);
    map['desired_return_ratio'] = Variable<double>(desiredReturnRatio);
    map['time_horizon'] = Variable<int>(timeHorizon);
    if (!nullToAbsent || lossToleranceIndex != null) {
      map['loss_tolerance_index'] = Variable<int>(lossToleranceIndex);
    }
    if (!nullToAbsent || experienceIndex != null) {
      map['experience_index'] = Variable<int>(experienceIndex);
    }
    if (!nullToAbsent || volatilityReactionIndex != null) {
      map['volatility_reaction_index'] = Variable<int>(volatilityReactionIndex);
    }
    if (!nullToAbsent || liquidityNeedIndex != null) {
      map['liquidity_need_index'] = Variable<int>(liquidityNeedIndex);
    }
    map['emergency_fund_months'] = Variable<int>(emergencyFundMonths);
    map['risk_score'] = Variable<double>(riskScore);
    if (!nullToAbsent || profile != null) {
      map['profile'] = Variable<String>(profile);
    }
    if (!nullToAbsent || allocationJson != null) {
      map['allocation_json'] = Variable<String>(allocationJson);
    }
    if (!nullToAbsent || answersJson != null) {
      map['answers_json'] = Variable<String>(answersJson);
    }
    return map;
  }

  RiskAssessmentsCompanion toCompanion(bool nullToAbsent) {
    return RiskAssessmentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      goal: goal == null && nullToAbsent ? const Value.absent() : Value(goal),
      incomeRatio: Value(incomeRatio),
      desiredReturnRatio: Value(desiredReturnRatio),
      timeHorizon: Value(timeHorizon),
      lossToleranceIndex: lossToleranceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(lossToleranceIndex),
      experienceIndex: experienceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(experienceIndex),
      volatilityReactionIndex: volatilityReactionIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(volatilityReactionIndex),
      liquidityNeedIndex: liquidityNeedIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(liquidityNeedIndex),
      emergencyFundMonths: Value(emergencyFundMonths),
      riskScore: Value(riskScore),
      profile: profile == null && nullToAbsent
          ? const Value.absent()
          : Value(profile),
      allocationJson: allocationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(allocationJson),
      answersJson: answersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(answersJson),
    );
  }

  factory RiskAssessment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RiskAssessment(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      goal: serializer.fromJson<String?>(json['goal']),
      incomeRatio: serializer.fromJson<double>(json['incomeRatio']),
      desiredReturnRatio: serializer.fromJson<double>(
        json['desiredReturnRatio'],
      ),
      timeHorizon: serializer.fromJson<int>(json['timeHorizon']),
      lossToleranceIndex: serializer.fromJson<int?>(json['lossToleranceIndex']),
      experienceIndex: serializer.fromJson<int?>(json['experienceIndex']),
      volatilityReactionIndex: serializer.fromJson<int?>(
        json['volatilityReactionIndex'],
      ),
      liquidityNeedIndex: serializer.fromJson<int?>(json['liquidityNeedIndex']),
      emergencyFundMonths: serializer.fromJson<int>(
        json['emergencyFundMonths'],
      ),
      riskScore: serializer.fromJson<double>(json['riskScore']),
      profile: serializer.fromJson<String?>(json['profile']),
      allocationJson: serializer.fromJson<String?>(json['allocationJson']),
      answersJson: serializer.fromJson<String?>(json['answersJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'userId': serializer.toJson<String?>(userId),
      'goal': serializer.toJson<String?>(goal),
      'incomeRatio': serializer.toJson<double>(incomeRatio),
      'desiredReturnRatio': serializer.toJson<double>(desiredReturnRatio),
      'timeHorizon': serializer.toJson<int>(timeHorizon),
      'lossToleranceIndex': serializer.toJson<int?>(lossToleranceIndex),
      'experienceIndex': serializer.toJson<int?>(experienceIndex),
      'volatilityReactionIndex': serializer.toJson<int?>(
        volatilityReactionIndex,
      ),
      'liquidityNeedIndex': serializer.toJson<int?>(liquidityNeedIndex),
      'emergencyFundMonths': serializer.toJson<int>(emergencyFundMonths),
      'riskScore': serializer.toJson<double>(riskScore),
      'profile': serializer.toJson<String?>(profile),
      'allocationJson': serializer.toJson<String?>(allocationJson),
      'answersJson': serializer.toJson<String?>(answersJson),
    };
  }

  RiskAssessment copyWith({
    int? id,
    DateTime? createdAt,
    Value<String?> userId = const Value.absent(),
    Value<String?> goal = const Value.absent(),
    double? incomeRatio,
    double? desiredReturnRatio,
    int? timeHorizon,
    Value<int?> lossToleranceIndex = const Value.absent(),
    Value<int?> experienceIndex = const Value.absent(),
    Value<int?> volatilityReactionIndex = const Value.absent(),
    Value<int?> liquidityNeedIndex = const Value.absent(),
    int? emergencyFundMonths,
    double? riskScore,
    Value<String?> profile = const Value.absent(),
    Value<String?> allocationJson = const Value.absent(),
    Value<String?> answersJson = const Value.absent(),
  }) => RiskAssessment(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    userId: userId.present ? userId.value : this.userId,
    goal: goal.present ? goal.value : this.goal,
    incomeRatio: incomeRatio ?? this.incomeRatio,
    desiredReturnRatio: desiredReturnRatio ?? this.desiredReturnRatio,
    timeHorizon: timeHorizon ?? this.timeHorizon,
    lossToleranceIndex: lossToleranceIndex.present
        ? lossToleranceIndex.value
        : this.lossToleranceIndex,
    experienceIndex: experienceIndex.present
        ? experienceIndex.value
        : this.experienceIndex,
    volatilityReactionIndex: volatilityReactionIndex.present
        ? volatilityReactionIndex.value
        : this.volatilityReactionIndex,
    liquidityNeedIndex: liquidityNeedIndex.present
        ? liquidityNeedIndex.value
        : this.liquidityNeedIndex,
    emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
    riskScore: riskScore ?? this.riskScore,
    profile: profile.present ? profile.value : this.profile,
    allocationJson: allocationJson.present
        ? allocationJson.value
        : this.allocationJson,
    answersJson: answersJson.present ? answersJson.value : this.answersJson,
  );
  RiskAssessment copyWithCompanion(RiskAssessmentsCompanion data) {
    return RiskAssessment(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      goal: data.goal.present ? data.goal.value : this.goal,
      incomeRatio: data.incomeRatio.present
          ? data.incomeRatio.value
          : this.incomeRatio,
      desiredReturnRatio: data.desiredReturnRatio.present
          ? data.desiredReturnRatio.value
          : this.desiredReturnRatio,
      timeHorizon: data.timeHorizon.present
          ? data.timeHorizon.value
          : this.timeHorizon,
      lossToleranceIndex: data.lossToleranceIndex.present
          ? data.lossToleranceIndex.value
          : this.lossToleranceIndex,
      experienceIndex: data.experienceIndex.present
          ? data.experienceIndex.value
          : this.experienceIndex,
      volatilityReactionIndex: data.volatilityReactionIndex.present
          ? data.volatilityReactionIndex.value
          : this.volatilityReactionIndex,
      liquidityNeedIndex: data.liquidityNeedIndex.present
          ? data.liquidityNeedIndex.value
          : this.liquidityNeedIndex,
      emergencyFundMonths: data.emergencyFundMonths.present
          ? data.emergencyFundMonths.value
          : this.emergencyFundMonths,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      profile: data.profile.present ? data.profile.value : this.profile,
      allocationJson: data.allocationJson.present
          ? data.allocationJson.value
          : this.allocationJson,
      answersJson: data.answersJson.present
          ? data.answersJson.value
          : this.answersJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RiskAssessment(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('goal: $goal, ')
          ..write('incomeRatio: $incomeRatio, ')
          ..write('desiredReturnRatio: $desiredReturnRatio, ')
          ..write('timeHorizon: $timeHorizon, ')
          ..write('lossToleranceIndex: $lossToleranceIndex, ')
          ..write('experienceIndex: $experienceIndex, ')
          ..write('volatilityReactionIndex: $volatilityReactionIndex, ')
          ..write('liquidityNeedIndex: $liquidityNeedIndex, ')
          ..write('emergencyFundMonths: $emergencyFundMonths, ')
          ..write('riskScore: $riskScore, ')
          ..write('profile: $profile, ')
          ..write('allocationJson: $allocationJson, ')
          ..write('answersJson: $answersJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    userId,
    goal,
    incomeRatio,
    desiredReturnRatio,
    timeHorizon,
    lossToleranceIndex,
    experienceIndex,
    volatilityReactionIndex,
    liquidityNeedIndex,
    emergencyFundMonths,
    riskScore,
    profile,
    allocationJson,
    answersJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RiskAssessment &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId &&
          other.goal == this.goal &&
          other.incomeRatio == this.incomeRatio &&
          other.desiredReturnRatio == this.desiredReturnRatio &&
          other.timeHorizon == this.timeHorizon &&
          other.lossToleranceIndex == this.lossToleranceIndex &&
          other.experienceIndex == this.experienceIndex &&
          other.volatilityReactionIndex == this.volatilityReactionIndex &&
          other.liquidityNeedIndex == this.liquidityNeedIndex &&
          other.emergencyFundMonths == this.emergencyFundMonths &&
          other.riskScore == this.riskScore &&
          other.profile == this.profile &&
          other.allocationJson == this.allocationJson &&
          other.answersJson == this.answersJson);
}

class RiskAssessmentsCompanion extends UpdateCompanion<RiskAssessment> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String?> userId;
  final Value<String?> goal;
  final Value<double> incomeRatio;
  final Value<double> desiredReturnRatio;
  final Value<int> timeHorizon;
  final Value<int?> lossToleranceIndex;
  final Value<int?> experienceIndex;
  final Value<int?> volatilityReactionIndex;
  final Value<int?> liquidityNeedIndex;
  final Value<int> emergencyFundMonths;
  final Value<double> riskScore;
  final Value<String?> profile;
  final Value<String?> allocationJson;
  final Value<String?> answersJson;
  const RiskAssessmentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.goal = const Value.absent(),
    this.incomeRatio = const Value.absent(),
    this.desiredReturnRatio = const Value.absent(),
    this.timeHorizon = const Value.absent(),
    this.lossToleranceIndex = const Value.absent(),
    this.experienceIndex = const Value.absent(),
    this.volatilityReactionIndex = const Value.absent(),
    this.liquidityNeedIndex = const Value.absent(),
    this.emergencyFundMonths = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.profile = const Value.absent(),
    this.allocationJson = const Value.absent(),
    this.answersJson = const Value.absent(),
  });
  RiskAssessmentsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.goal = const Value.absent(),
    this.incomeRatio = const Value.absent(),
    this.desiredReturnRatio = const Value.absent(),
    this.timeHorizon = const Value.absent(),
    this.lossToleranceIndex = const Value.absent(),
    this.experienceIndex = const Value.absent(),
    this.volatilityReactionIndex = const Value.absent(),
    this.liquidityNeedIndex = const Value.absent(),
    this.emergencyFundMonths = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.profile = const Value.absent(),
    this.allocationJson = const Value.absent(),
    this.answersJson = const Value.absent(),
  });
  static Insertable<RiskAssessment> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? userId,
    Expression<String>? goal,
    Expression<double>? incomeRatio,
    Expression<double>? desiredReturnRatio,
    Expression<int>? timeHorizon,
    Expression<int>? lossToleranceIndex,
    Expression<int>? experienceIndex,
    Expression<int>? volatilityReactionIndex,
    Expression<int>? liquidityNeedIndex,
    Expression<int>? emergencyFundMonths,
    Expression<double>? riskScore,
    Expression<String>? profile,
    Expression<String>? allocationJson,
    Expression<String>? answersJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (userId != null) 'user_id': userId,
      if (goal != null) 'goal': goal,
      if (incomeRatio != null) 'income_ratio': incomeRatio,
      if (desiredReturnRatio != null)
        'desired_return_ratio': desiredReturnRatio,
      if (timeHorizon != null) 'time_horizon': timeHorizon,
      if (lossToleranceIndex != null)
        'loss_tolerance_index': lossToleranceIndex,
      if (experienceIndex != null) 'experience_index': experienceIndex,
      if (volatilityReactionIndex != null)
        'volatility_reaction_index': volatilityReactionIndex,
      if (liquidityNeedIndex != null)
        'liquidity_need_index': liquidityNeedIndex,
      if (emergencyFundMonths != null)
        'emergency_fund_months': emergencyFundMonths,
      if (riskScore != null) 'risk_score': riskScore,
      if (profile != null) 'profile': profile,
      if (allocationJson != null) 'allocation_json': allocationJson,
      if (answersJson != null) 'answers_json': answersJson,
    });
  }

  RiskAssessmentsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String?>? userId,
    Value<String?>? goal,
    Value<double>? incomeRatio,
    Value<double>? desiredReturnRatio,
    Value<int>? timeHorizon,
    Value<int?>? lossToleranceIndex,
    Value<int?>? experienceIndex,
    Value<int?>? volatilityReactionIndex,
    Value<int?>? liquidityNeedIndex,
    Value<int>? emergencyFundMonths,
    Value<double>? riskScore,
    Value<String?>? profile,
    Value<String?>? allocationJson,
    Value<String?>? answersJson,
  }) {
    return RiskAssessmentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      goal: goal ?? this.goal,
      incomeRatio: incomeRatio ?? this.incomeRatio,
      desiredReturnRatio: desiredReturnRatio ?? this.desiredReturnRatio,
      timeHorizon: timeHorizon ?? this.timeHorizon,
      lossToleranceIndex: lossToleranceIndex ?? this.lossToleranceIndex,
      experienceIndex: experienceIndex ?? this.experienceIndex,
      volatilityReactionIndex:
          volatilityReactionIndex ?? this.volatilityReactionIndex,
      liquidityNeedIndex: liquidityNeedIndex ?? this.liquidityNeedIndex,
      emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
      riskScore: riskScore ?? this.riskScore,
      profile: profile ?? this.profile,
      allocationJson: allocationJson ?? this.allocationJson,
      answersJson: answersJson ?? this.answersJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (incomeRatio.present) {
      map['income_ratio'] = Variable<double>(incomeRatio.value);
    }
    if (desiredReturnRatio.present) {
      map['desired_return_ratio'] = Variable<double>(desiredReturnRatio.value);
    }
    if (timeHorizon.present) {
      map['time_horizon'] = Variable<int>(timeHorizon.value);
    }
    if (lossToleranceIndex.present) {
      map['loss_tolerance_index'] = Variable<int>(lossToleranceIndex.value);
    }
    if (experienceIndex.present) {
      map['experience_index'] = Variable<int>(experienceIndex.value);
    }
    if (volatilityReactionIndex.present) {
      map['volatility_reaction_index'] = Variable<int>(
        volatilityReactionIndex.value,
      );
    }
    if (liquidityNeedIndex.present) {
      map['liquidity_need_index'] = Variable<int>(liquidityNeedIndex.value);
    }
    if (emergencyFundMonths.present) {
      map['emergency_fund_months'] = Variable<int>(emergencyFundMonths.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<double>(riskScore.value);
    }
    if (profile.present) {
      map['profile'] = Variable<String>(profile.value);
    }
    if (allocationJson.present) {
      map['allocation_json'] = Variable<String>(allocationJson.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RiskAssessmentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('goal: $goal, ')
          ..write('incomeRatio: $incomeRatio, ')
          ..write('desiredReturnRatio: $desiredReturnRatio, ')
          ..write('timeHorizon: $timeHorizon, ')
          ..write('lossToleranceIndex: $lossToleranceIndex, ')
          ..write('experienceIndex: $experienceIndex, ')
          ..write('volatilityReactionIndex: $volatilityReactionIndex, ')
          ..write('liquidityNeedIndex: $liquidityNeedIndex, ')
          ..write('emergencyFundMonths: $emergencyFundMonths, ')
          ..write('riskScore: $riskScore, ')
          ..write('profile: $profile, ')
          ..write('allocationJson: $allocationJson, ')
          ..write('answersJson: $answersJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $PendingTransactionsTable pendingTransactions =
      $PendingTransactionsTable(this);
  late final $RiskAssessmentsTable riskAssessments = $RiskAssessmentsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    goals,
    loans,
    pendingTransactions,
    riskAssessments,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required double amountMinor,
      required String currency,
      required String description,
      Value<String> categoryId,
      required DateTime date,
      Value<bool> isExpense,
      Value<String?> rawSms,
      required int profileId,
      Value<String?> goalId,
      Value<String> transactionType,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<double> amountMinor,
      Value<String> currency,
      Value<String> description,
      Value<String> categoryId,
      Value<DateTime> date,
      Value<bool> isExpense,
      Value<String?> rawSms,
      Value<int> profileId,
      Value<String?> goalId,
      Value<String> transactionType,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<double, double, double> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExpense => $composableBuilder(
    column: $table.isExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSms => $composableBuilder(
    column: $table.rawSms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<double> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExpense => $composableBuilder(
    column: $table.isExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSms => $composableBuilder(
    column: $table.rawSms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<double, double> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isExpense =>
      $composableBuilder(column: $table.isExpense, builder: (column) => column);

  GeneratedColumn<String> get rawSms =>
      $composableBuilder(column: $table.rawSms, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isExpense = const Value.absent(),
                Value<String?> rawSms = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                description: description,
                categoryId: categoryId,
                date: date,
                isExpense: isExpense,
                rawSms: rawSms,
                profileId: profileId,
                goalId: goalId,
                transactionType: transactionType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amountMinor,
                required String currency,
                required String description,
                Value<String> categoryId = const Value.absent(),
                required DateTime date,
                Value<bool> isExpense = const Value.absent(),
                Value<String?> rawSms = const Value.absent(),
                required int profileId,
                Value<String?> goalId = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                description: description,
                categoryId: categoryId,
                date: date,
                isExpense: isExpense,
                rawSms: rawSms,
                profileId: profileId,
                goalId: goalId,
                transactionType: transactionType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required String title,
      required double targetMinor,
      required String currency,
      required DateTime dueDate,
      Value<bool> completed,
      required int profileId,
      Value<double> currentMinor,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<double> targetMinor,
      Value<String> currency,
      Value<DateTime> dueDate,
      Value<bool> completed,
      Value<int> profileId,
      Value<double> currentMinor,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<double, double, double> get targetMinor =>
      $composableBuilder(
        column: $table.targetMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentMinor => $composableBuilder(
    column: $table.currentMinor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetMinor => $composableBuilder(
    column: $table.targetMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentMinor => $composableBuilder(
    column: $table.currentMinor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<double, double> get targetMinor =>
      $composableBuilder(
        column: $table.targetMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<double> get currentMinor => $composableBuilder(
    column: $table.currentMinor,
    builder: (column) => column,
  );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> targetMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<double> currentMinor = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                title: title,
                targetMinor: targetMinor,
                currency: currency,
                dueDate: dueDate,
                completed: completed,
                profileId: profileId,
                currentMinor: currentMinor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required double targetMinor,
                required String currency,
                required DateTime dueDate,
                Value<bool> completed = const Value.absent(),
                required int profileId,
                Value<double> currentMinor = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                title: title,
                targetMinor: targetMinor,
                currency: currency,
                dueDate: dueDate,
                completed: completed,
                profileId: profileId,
                currentMinor: currentMinor,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$LoansTableCreateCompanionBuilder =
    LoansCompanion Function({
      Value<int> id,
      required String name,
      required int principalMinor,
      Value<String> currency,
      Value<double> interestRate,
      required DateTime startDate,
      required DateTime endDate,
      required int profileId,
    });
typedef $$LoansTableUpdateCompanionBuilder =
    LoansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> principalMinor,
      Value<String> currency,
      Value<double> interestRate,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<int> profileId,
    });

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
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

  ColumnFilters<int> get principalMinor => $composableBuilder(
    column: $table.principalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
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

  ColumnOrderings<int> get principalMinor => $composableBuilder(
    column: $table.principalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
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

  GeneratedColumn<int> get principalMinor => $composableBuilder(
    column: $table.principalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          Loan,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
          Loan,
          PrefetchHooks Function()
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> principalMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> interestRate = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<int> profileId = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                name: name,
                principalMinor: principalMinor,
                currency: currency,
                interestRate: interestRate,
                startDate: startDate,
                endDate: endDate,
                profileId: profileId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int principalMinor,
                Value<String> currency = const Value.absent(),
                Value<double> interestRate = const Value.absent(),
                required DateTime startDate,
                required DateTime endDate,
                required int profileId,
              }) => LoansCompanion.insert(
                id: id,
                name: name,
                principalMinor: principalMinor,
                currency: currency,
                interestRate: interestRate,
                startDate: startDate,
                endDate: endDate,
                profileId: profileId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      Loan,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
      Loan,
      PrefetchHooks Function()
    >;
typedef $$PendingTransactionsTableCreateCompanionBuilder =
    PendingTransactionsCompanion Function({
      required String id,
      required double amountMinor,
      Value<String> currency,
      Value<String?> description,
      required DateTime date,
      Value<bool> isExpense,
      Value<String?> rawSms,
      required int profileId,
      Value<int> rowid,
    });
typedef $$PendingTransactionsTableUpdateCompanionBuilder =
    PendingTransactionsCompanion Function({
      Value<String> id,
      Value<double> amountMinor,
      Value<String> currency,
      Value<String?> description,
      Value<DateTime> date,
      Value<bool> isExpense,
      Value<String?> rawSms,
      Value<int> profileId,
      Value<int> rowid,
    });

class $$PendingTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<double, double, double> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExpense => $composableBuilder(
    column: $table.isExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSms => $composableBuilder(
    column: $table.rawSms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableOrderingComposer({
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

  ColumnOrderings<double> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExpense => $composableBuilder(
    column: $table.isExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSms => $composableBuilder(
    column: $table.rawSms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<double, double> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isExpense =>
      $composableBuilder(column: $table.isExpense, builder: (column) => column);

  GeneratedColumn<String> get rawSms =>
      $composableBuilder(column: $table.rawSms, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);
}

class $$PendingTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingTransactionsTable,
          PendingTransaction,
          $$PendingTransactionsTableFilterComposer,
          $$PendingTransactionsTableOrderingComposer,
          $$PendingTransactionsTableAnnotationComposer,
          $$PendingTransactionsTableCreateCompanionBuilder,
          $$PendingTransactionsTableUpdateCompanionBuilder,
          (
            PendingTransaction,
            BaseReferences<
              _$AppDatabase,
              $PendingTransactionsTable,
              PendingTransaction
            >,
          ),
          PendingTransaction,
          PrefetchHooks Function()
        > {
  $$PendingTransactionsTableTableManager(
    _$AppDatabase db,
    $PendingTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isExpense = const Value.absent(),
                Value<String?> rawSms = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingTransactionsCompanion(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                description: description,
                date: date,
                isExpense: isExpense,
                rawSms: rawSms,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double amountMinor,
                Value<String> currency = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime date,
                Value<bool> isExpense = const Value.absent(),
                Value<String?> rawSms = const Value.absent(),
                required int profileId,
                Value<int> rowid = const Value.absent(),
              }) => PendingTransactionsCompanion.insert(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                description: description,
                date: date,
                isExpense: isExpense,
                rawSms: rawSms,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingTransactionsTable,
      PendingTransaction,
      $$PendingTransactionsTableFilterComposer,
      $$PendingTransactionsTableOrderingComposer,
      $$PendingTransactionsTableAnnotationComposer,
      $$PendingTransactionsTableCreateCompanionBuilder,
      $$PendingTransactionsTableUpdateCompanionBuilder,
      (
        PendingTransaction,
        BaseReferences<
          _$AppDatabase,
          $PendingTransactionsTable,
          PendingTransaction
        >,
      ),
      PendingTransaction,
      PrefetchHooks Function()
    >;
typedef $$RiskAssessmentsTableCreateCompanionBuilder =
    RiskAssessmentsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String?> userId,
      Value<String?> goal,
      Value<double> incomeRatio,
      Value<double> desiredReturnRatio,
      Value<int> timeHorizon,
      Value<int?> lossToleranceIndex,
      Value<int?> experienceIndex,
      Value<int?> volatilityReactionIndex,
      Value<int?> liquidityNeedIndex,
      Value<int> emergencyFundMonths,
      Value<double> riskScore,
      Value<String?> profile,
      Value<String?> allocationJson,
      Value<String?> answersJson,
    });
typedef $$RiskAssessmentsTableUpdateCompanionBuilder =
    RiskAssessmentsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String?> userId,
      Value<String?> goal,
      Value<double> incomeRatio,
      Value<double> desiredReturnRatio,
      Value<int> timeHorizon,
      Value<int?> lossToleranceIndex,
      Value<int?> experienceIndex,
      Value<int?> volatilityReactionIndex,
      Value<int?> liquidityNeedIndex,
      Value<int> emergencyFundMonths,
      Value<double> riskScore,
      Value<String?> profile,
      Value<String?> allocationJson,
      Value<String?> answersJson,
    });

class $$RiskAssessmentsTableFilterComposer
    extends Composer<_$AppDatabase, $RiskAssessmentsTable> {
  $$RiskAssessmentsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get incomeRatio => $composableBuilder(
    column: $table.incomeRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get desiredReturnRatio => $composableBuilder(
    column: $table.desiredReturnRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeHorizon => $composableBuilder(
    column: $table.timeHorizon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lossToleranceIndex => $composableBuilder(
    column: $table.lossToleranceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get experienceIndex => $composableBuilder(
    column: $table.experienceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volatilityReactionIndex => $composableBuilder(
    column: $table.volatilityReactionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get liquidityNeedIndex => $composableBuilder(
    column: $table.liquidityNeedIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get emergencyFundMonths => $composableBuilder(
    column: $table.emergencyFundMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allocationJson => $composableBuilder(
    column: $table.allocationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RiskAssessmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RiskAssessmentsTable> {
  $$RiskAssessmentsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get incomeRatio => $composableBuilder(
    column: $table.incomeRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get desiredReturnRatio => $composableBuilder(
    column: $table.desiredReturnRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeHorizon => $composableBuilder(
    column: $table.timeHorizon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lossToleranceIndex => $composableBuilder(
    column: $table.lossToleranceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get experienceIndex => $composableBuilder(
    column: $table.experienceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volatilityReactionIndex => $composableBuilder(
    column: $table.volatilityReactionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get liquidityNeedIndex => $composableBuilder(
    column: $table.liquidityNeedIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get emergencyFundMonths => $composableBuilder(
    column: $table.emergencyFundMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allocationJson => $composableBuilder(
    column: $table.allocationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RiskAssessmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RiskAssessmentsTable> {
  $$RiskAssessmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<double> get incomeRatio => $composableBuilder(
    column: $table.incomeRatio,
    builder: (column) => column,
  );

  GeneratedColumn<double> get desiredReturnRatio => $composableBuilder(
    column: $table.desiredReturnRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeHorizon => $composableBuilder(
    column: $table.timeHorizon,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lossToleranceIndex => $composableBuilder(
    column: $table.lossToleranceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get experienceIndex => $composableBuilder(
    column: $table.experienceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get volatilityReactionIndex => $composableBuilder(
    column: $table.volatilityReactionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get liquidityNeedIndex => $composableBuilder(
    column: $table.liquidityNeedIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get emergencyFundMonths => $composableBuilder(
    column: $table.emergencyFundMonths,
    builder: (column) => column,
  );

  GeneratedColumn<double> get riskScore =>
      $composableBuilder(column: $table.riskScore, builder: (column) => column);

  GeneratedColumn<String> get profile =>
      $composableBuilder(column: $table.profile, builder: (column) => column);

  GeneratedColumn<String> get allocationJson => $composableBuilder(
    column: $table.allocationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => column,
  );
}

class $$RiskAssessmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RiskAssessmentsTable,
          RiskAssessment,
          $$RiskAssessmentsTableFilterComposer,
          $$RiskAssessmentsTableOrderingComposer,
          $$RiskAssessmentsTableAnnotationComposer,
          $$RiskAssessmentsTableCreateCompanionBuilder,
          $$RiskAssessmentsTableUpdateCompanionBuilder,
          (
            RiskAssessment,
            BaseReferences<
              _$AppDatabase,
              $RiskAssessmentsTable,
              RiskAssessment
            >,
          ),
          RiskAssessment,
          PrefetchHooks Function()
        > {
  $$RiskAssessmentsTableTableManager(
    _$AppDatabase db,
    $RiskAssessmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RiskAssessmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RiskAssessmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RiskAssessmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> goal = const Value.absent(),
                Value<double> incomeRatio = const Value.absent(),
                Value<double> desiredReturnRatio = const Value.absent(),
                Value<int> timeHorizon = const Value.absent(),
                Value<int?> lossToleranceIndex = const Value.absent(),
                Value<int?> experienceIndex = const Value.absent(),
                Value<int?> volatilityReactionIndex = const Value.absent(),
                Value<int?> liquidityNeedIndex = const Value.absent(),
                Value<int> emergencyFundMonths = const Value.absent(),
                Value<double> riskScore = const Value.absent(),
                Value<String?> profile = const Value.absent(),
                Value<String?> allocationJson = const Value.absent(),
                Value<String?> answersJson = const Value.absent(),
              }) => RiskAssessmentsCompanion(
                id: id,
                createdAt: createdAt,
                userId: userId,
                goal: goal,
                incomeRatio: incomeRatio,
                desiredReturnRatio: desiredReturnRatio,
                timeHorizon: timeHorizon,
                lossToleranceIndex: lossToleranceIndex,
                experienceIndex: experienceIndex,
                volatilityReactionIndex: volatilityReactionIndex,
                liquidityNeedIndex: liquidityNeedIndex,
                emergencyFundMonths: emergencyFundMonths,
                riskScore: riskScore,
                profile: profile,
                allocationJson: allocationJson,
                answersJson: answersJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> goal = const Value.absent(),
                Value<double> incomeRatio = const Value.absent(),
                Value<double> desiredReturnRatio = const Value.absent(),
                Value<int> timeHorizon = const Value.absent(),
                Value<int?> lossToleranceIndex = const Value.absent(),
                Value<int?> experienceIndex = const Value.absent(),
                Value<int?> volatilityReactionIndex = const Value.absent(),
                Value<int?> liquidityNeedIndex = const Value.absent(),
                Value<int> emergencyFundMonths = const Value.absent(),
                Value<double> riskScore = const Value.absent(),
                Value<String?> profile = const Value.absent(),
                Value<String?> allocationJson = const Value.absent(),
                Value<String?> answersJson = const Value.absent(),
              }) => RiskAssessmentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                userId: userId,
                goal: goal,
                incomeRatio: incomeRatio,
                desiredReturnRatio: desiredReturnRatio,
                timeHorizon: timeHorizon,
                lossToleranceIndex: lossToleranceIndex,
                experienceIndex: experienceIndex,
                volatilityReactionIndex: volatilityReactionIndex,
                liquidityNeedIndex: liquidityNeedIndex,
                emergencyFundMonths: emergencyFundMonths,
                riskScore: riskScore,
                profile: profile,
                allocationJson: allocationJson,
                answersJson: answersJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RiskAssessmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RiskAssessmentsTable,
      RiskAssessment,
      $$RiskAssessmentsTableFilterComposer,
      $$RiskAssessmentsTableOrderingComposer,
      $$RiskAssessmentsTableAnnotationComposer,
      $$RiskAssessmentsTableCreateCompanionBuilder,
      $$RiskAssessmentsTableUpdateCompanionBuilder,
      (
        RiskAssessment,
        BaseReferences<_$AppDatabase, $RiskAssessmentsTable, RiskAssessment>,
      ),
      RiskAssessment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$PendingTransactionsTableTableManager get pendingTransactions =>
      $$PendingTransactionsTableTableManager(_db, _db.pendingTransactions);
  $$RiskAssessmentsTableTableManager get riskAssessments =>
      $$RiskAssessmentsTableTableManager(_db, _db.riskAssessments);
}
