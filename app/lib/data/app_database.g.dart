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
    requiredDuringInsert: false,
    defaultValue: const Constant('KES'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _budgetCategoryMeta = const VerificationMeta(
    'budgetCategory',
  );
  @override
  late final GeneratedColumn<String> budgetCategory = GeneratedColumn<String>(
    'budget_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantCategoryMeta = const VerificationMeta(
    'merchantCategory',
  );
  @override
  late final GeneratedColumn<String> merchantCategory = GeneratedColumn<String>(
    'merchant_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipientMeta = const VerificationMeta(
    'recipient',
  );
  @override
  late final GeneratedColumn<String> recipient = GeneratedColumn<String>(
    'recipient',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountMinor,
    currency,
    type,
    description,
    category,
    goalId,
    date,
    isExpense,
    isPending,
    rawSms,
    profileId,
    budgetCategory,
    paymentMethod,
    merchantName,
    merchantCategory,
    tags,
    reference,
    recipient,
    status,
    isRecurring,
    isSynced,
    remoteId,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
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
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
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
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
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
    if (data.containsKey('budget_category')) {
      context.handle(
        _budgetCategoryMeta,
        budgetCategory.isAcceptableOrUnknown(
          data['budget_category']!,
          _budgetCategoryMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    }
    if (data.containsKey('merchant_category')) {
      context.handle(
        _merchantCategoryMeta,
        merchantCategory.isAcceptableOrUnknown(
          data['merchant_category']!,
          _merchantCategoryMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('recipient')) {
      context.handle(
        _recipientMeta,
        recipient.isAcceptableOrUnknown(data['recipient']!, _recipientMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
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
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expense'],
      )!,
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
      rawSms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sms'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      budgetCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_category'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      ),
      merchantCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_category'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      recipient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
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
  final String type;
  final String description;
  final String category;
  final String? goalId;
  final DateTime date;
  final bool isExpense;
  final bool isPending;
  final String? rawSms;
  final int profileId;
  final String? budgetCategory;
  final String? paymentMethod;
  final String? merchantName;
  final String? merchantCategory;
  final String? tags;
  final String? reference;
  final String? recipient;
  final String status;
  final bool isRecurring;
  final bool isSynced;
  final String? remoteId;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.description,
    required this.category,
    this.goalId,
    required this.date,
    required this.isExpense,
    required this.isPending,
    this.rawSms,
    required this.profileId,
    this.budgetCategory,
    this.paymentMethod,
    this.merchantName,
    this.merchantCategory,
    this.tags,
    this.reference,
    this.recipient,
    required this.status,
    required this.isRecurring,
    required this.isSynced,
    this.remoteId,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
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
    map['type'] = Variable<String>(type);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    map['date'] = Variable<DateTime>(date);
    map['is_expense'] = Variable<bool>(isExpense);
    map['is_pending'] = Variable<bool>(isPending);
    if (!nullToAbsent || rawSms != null) {
      map['raw_sms'] = Variable<String>(rawSms);
    }
    map['profile_id'] = Variable<int>(profileId);
    if (!nullToAbsent || budgetCategory != null) {
      map['budget_category'] = Variable<String>(budgetCategory);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || merchantName != null) {
      map['merchant_name'] = Variable<String>(merchantName);
    }
    if (!nullToAbsent || merchantCategory != null) {
      map['merchant_category'] = Variable<String>(merchantCategory);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || recipient != null) {
      map['recipient'] = Variable<String>(recipient);
    }
    map['status'] = Variable<String>(status);
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      type: Value(type),
      description: Value(description),
      category: Value(category),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      date: Value(date),
      isExpense: Value(isExpense),
      isPending: Value(isPending),
      rawSms: rawSms == null && nullToAbsent
          ? const Value.absent()
          : Value(rawSms),
      profileId: Value(profileId),
      budgetCategory: budgetCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetCategory),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      merchantName: merchantName == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantName),
      merchantCategory: merchantCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantCategory),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      recipient: recipient == null && nullToAbsent
          ? const Value.absent()
          : Value(recipient),
      status: Value(status),
      isRecurring: Value(isRecurring),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      date: serializer.fromJson<DateTime>(json['date']),
      isExpense: serializer.fromJson<bool>(json['isExpense']),
      isPending: serializer.fromJson<bool>(json['isPending']),
      rawSms: serializer.fromJson<String?>(json['rawSms']),
      profileId: serializer.fromJson<int>(json['profileId']),
      budgetCategory: serializer.fromJson<String?>(json['budgetCategory']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      merchantName: serializer.fromJson<String?>(json['merchantName']),
      merchantCategory: serializer.fromJson<String?>(json['merchantCategory']),
      tags: serializer.fromJson<String?>(json['tags']),
      reference: serializer.fromJson<String?>(json['reference']),
      recipient: serializer.fromJson<String?>(json['recipient']),
      status: serializer.fromJson<String>(json['status']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMinor': serializer.toJson<double>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'goalId': serializer.toJson<String?>(goalId),
      'date': serializer.toJson<DateTime>(date),
      'isExpense': serializer.toJson<bool>(isExpense),
      'isPending': serializer.toJson<bool>(isPending),
      'rawSms': serializer.toJson<String?>(rawSms),
      'profileId': serializer.toJson<int>(profileId),
      'budgetCategory': serializer.toJson<String?>(budgetCategory),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'merchantName': serializer.toJson<String?>(merchantName),
      'merchantCategory': serializer.toJson<String?>(merchantCategory),
      'tags': serializer.toJson<String?>(tags),
      'reference': serializer.toJson<String?>(reference),
      'recipient': serializer.toJson<String?>(recipient),
      'status': serializer.toJson<String>(status),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith({
    int? id,
    double? amountMinor,
    String? currency,
    String? type,
    String? description,
    String? category,
    Value<String?> goalId = const Value.absent(),
    DateTime? date,
    bool? isExpense,
    bool? isPending,
    Value<String?> rawSms = const Value.absent(),
    int? profileId,
    Value<String?> budgetCategory = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> merchantName = const Value.absent(),
    Value<String?> merchantCategory = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    Value<String?> recipient = const Value.absent(),
    String? status,
    bool? isRecurring,
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    description: description ?? this.description,
    category: category ?? this.category,
    goalId: goalId.present ? goalId.value : this.goalId,
    date: date ?? this.date,
    isExpense: isExpense ?? this.isExpense,
    isPending: isPending ?? this.isPending,
    rawSms: rawSms.present ? rawSms.value : this.rawSms,
    profileId: profileId ?? this.profileId,
    budgetCategory: budgetCategory.present
        ? budgetCategory.value
        : this.budgetCategory,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    merchantName: merchantName.present ? merchantName.value : this.merchantName,
    merchantCategory: merchantCategory.present
        ? merchantCategory.value
        : this.merchantCategory,
    tags: tags.present ? tags.value : this.tags,
    reference: reference.present ? reference.value : this.reference,
    recipient: recipient.present ? recipient.value : this.recipient,
    status: status ?? this.status,
    isRecurring: isRecurring ?? this.isRecurring,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      isExpense: data.isExpense.present ? data.isExpense.value : this.isExpense,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
      rawSms: data.rawSms.present ? data.rawSms.value : this.rawSms,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      budgetCategory: data.budgetCategory.present
          ? data.budgetCategory.value
          : this.budgetCategory,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      merchantCategory: data.merchantCategory.present
          ? data.merchantCategory.value
          : this.merchantCategory,
      tags: data.tags.present ? data.tags.value : this.tags,
      reference: data.reference.present ? data.reference.value : this.reference,
      recipient: data.recipient.present ? data.recipient.value : this.recipient,
      status: data.status.present ? data.status.value : this.status,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('isExpense: $isExpense, ')
          ..write('isPending: $isPending, ')
          ..write('rawSms: $rawSms, ')
          ..write('profileId: $profileId, ')
          ..write('budgetCategory: $budgetCategory, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('merchantName: $merchantName, ')
          ..write('merchantCategory: $merchantCategory, ')
          ..write('tags: $tags, ')
          ..write('reference: $reference, ')
          ..write('recipient: $recipient, ')
          ..write('status: $status, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    amountMinor,
    currency,
    type,
    description,
    category,
    goalId,
    date,
    isExpense,
    isPending,
    rawSms,
    profileId,
    budgetCategory,
    paymentMethod,
    merchantName,
    merchantCategory,
    tags,
    reference,
    recipient,
    status,
    isRecurring,
    isSynced,
    remoteId,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.type == this.type &&
          other.description == this.description &&
          other.category == this.category &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.isExpense == this.isExpense &&
          other.isPending == this.isPending &&
          other.rawSms == this.rawSms &&
          other.profileId == this.profileId &&
          other.budgetCategory == this.budgetCategory &&
          other.paymentMethod == this.paymentMethod &&
          other.merchantName == this.merchantName &&
          other.merchantCategory == this.merchantCategory &&
          other.tags == this.tags &&
          other.reference == this.reference &&
          other.recipient == this.recipient &&
          other.status == this.status &&
          other.isRecurring == this.isRecurring &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<double> amountMinor;
  final Value<String> currency;
  final Value<String> type;
  final Value<String> description;
  final Value<String> category;
  final Value<String?> goalId;
  final Value<DateTime> date;
  final Value<bool> isExpense;
  final Value<bool> isPending;
  final Value<String?> rawSms;
  final Value<int> profileId;
  final Value<String?> budgetCategory;
  final Value<String?> paymentMethod;
  final Value<String?> merchantName;
  final Value<String?> merchantCategory;
  final Value<String?> tags;
  final Value<String?> reference;
  final Value<String?> recipient;
  final Value<String> status;
  final Value<bool> isRecurring;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.isExpense = const Value.absent(),
    this.isPending = const Value.absent(),
    this.rawSms = const Value.absent(),
    this.profileId = const Value.absent(),
    this.budgetCategory = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.merchantCategory = const Value.absent(),
    this.tags = const Value.absent(),
    this.reference = const Value.absent(),
    this.recipient = const Value.absent(),
    this.status = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amountMinor,
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.goalId = const Value.absent(),
    required DateTime date,
    this.isExpense = const Value.absent(),
    this.isPending = const Value.absent(),
    this.rawSms = const Value.absent(),
    required int profileId,
    this.budgetCategory = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.merchantCategory = const Value.absent(),
    this.tags = const Value.absent(),
    this.reference = const Value.absent(),
    this.recipient = const Value.absent(),
    this.status = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : amountMinor = Value(amountMinor),
       date = Value(date),
       profileId = Value(profileId);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<double>? amountMinor,
    Expression<String>? currency,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? goalId,
    Expression<DateTime>? date,
    Expression<bool>? isExpense,
    Expression<bool>? isPending,
    Expression<String>? rawSms,
    Expression<int>? profileId,
    Expression<String>? budgetCategory,
    Expression<String>? paymentMethod,
    Expression<String>? merchantName,
    Expression<String>? merchantCategory,
    Expression<String>? tags,
    Expression<String>? reference,
    Expression<String>? recipient,
    Expression<String>? status,
    Expression<bool>? isRecurring,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (isExpense != null) 'is_expense': isExpense,
      if (isPending != null) 'is_pending': isPending,
      if (rawSms != null) 'raw_sms': rawSms,
      if (profileId != null) 'profile_id': profileId,
      if (budgetCategory != null) 'budget_category': budgetCategory,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (merchantName != null) 'merchant_name': merchantName,
      if (merchantCategory != null) 'merchant_category': merchantCategory,
      if (tags != null) 'tags': tags,
      if (reference != null) 'reference': reference,
      if (recipient != null) 'recipient': recipient,
      if (status != null) 'status': status,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amountMinor,
    Value<String>? currency,
    Value<String>? type,
    Value<String>? description,
    Value<String>? category,
    Value<String?>? goalId,
    Value<DateTime>? date,
    Value<bool>? isExpense,
    Value<bool>? isPending,
    Value<String?>? rawSms,
    Value<int>? profileId,
    Value<String?>? budgetCategory,
    Value<String?>? paymentMethod,
    Value<String?>? merchantName,
    Value<String?>? merchantCategory,
    Value<String?>? tags,
    Value<String?>? reference,
    Value<String?>? recipient,
    Value<String>? status,
    Value<bool>? isRecurring,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      description: description ?? this.description,
      category: category ?? this.category,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      isPending: isPending ?? this.isPending,
      rawSms: rawSms ?? this.rawSms,
      profileId: profileId ?? this.profileId,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      merchantName: merchantName ?? this.merchantName,
      merchantCategory: merchantCategory ?? this.merchantCategory,
      tags: tags ?? this.tags,
      reference: reference ?? this.reference,
      recipient: recipient ?? this.recipient,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isExpense.present) {
      map['is_expense'] = Variable<bool>(isExpense.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    if (rawSms.present) {
      map['raw_sms'] = Variable<String>(rawSms.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (budgetCategory.present) {
      map['budget_category'] = Variable<String>(budgetCategory.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (merchantCategory.present) {
      map['merchant_category'] = Variable<String>(merchantCategory.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (recipient.present) {
      map['recipient'] = Variable<String>(recipient.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('isExpense: $isExpense, ')
          ..write('isPending: $isPending, ')
          ..write('rawSms: $rawSms, ')
          ..write('profileId: $profileId, ')
          ..write('budgetCategory: $budgetCategory, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('merchantName: $merchantName, ')
          ..write('merchantCategory: $merchantCategory, ')
          ..write('tags: $tags, ')
          ..write('reference: $reference, ')
          ..write('recipient: $recipient, ')
          ..write('status: $status, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalTypeMeta = const VerificationMeta(
    'goalType',
  );
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
    'goal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('savings'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    targetMinor,
    currentMinor,
    currency,
    dueDate,
    completed,
    profileId,
    isSynced,
    remoteId,
    goalType,
    status,
    description,
    createdAt,
    updatedAt,
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
    if (data.containsKey('current_minor')) {
      context.handle(
        _currentMinorMeta,
        currentMinor.isAcceptableOrUnknown(
          data['current_minor']!,
          _currentMinorMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
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
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('goal_type')) {
      context.handle(
        _goalTypeMeta,
        goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
      currentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_minor'],
      )!,
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
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      goalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
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
  final double currentMinor;
  final String currency;
  final DateTime dueDate;
  final bool completed;
  final int profileId;
  final bool isSynced;
  final String? remoteId;
  final String goalType;
  final String status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal({
    required this.id,
    required this.title,
    required this.targetMinor,
    required this.currentMinor,
    required this.currency,
    required this.dueDate,
    required this.completed,
    required this.profileId,
    required this.isSynced,
    this.remoteId,
    required this.goalType,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
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
    map['current_minor'] = Variable<double>(currentMinor);
    map['currency'] = Variable<String>(currency);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['completed'] = Variable<bool>(completed);
    map['profile_id'] = Variable<int>(profileId);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['goal_type'] = Variable<String>(goalType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      targetMinor: Value(targetMinor),
      currentMinor: Value(currentMinor),
      currency: Value(currency),
      dueDate: Value(dueDate),
      completed: Value(completed),
      profileId: Value(profileId),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      goalType: Value(goalType),
      status: Value(status),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      currentMinor: serializer.fromJson<double>(json['currentMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      completed: serializer.fromJson<bool>(json['completed']),
      profileId: serializer.fromJson<int>(json['profileId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      goalType: serializer.fromJson<String>(json['goalType']),
      status: serializer.fromJson<String>(json['status']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'targetMinor': serializer.toJson<double>(targetMinor),
      'currentMinor': serializer.toJson<double>(currentMinor),
      'currency': serializer.toJson<String>(currency),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'completed': serializer.toJson<bool>(completed),
      'profileId': serializer.toJson<int>(profileId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
      'goalType': serializer.toJson<String>(goalType),
      'status': serializer.toJson<String>(status),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith({
    int? id,
    String? title,
    double? targetMinor,
    double? currentMinor,
    String? currency,
    DateTime? dueDate,
    bool? completed,
    int? profileId,
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
    String? goalType,
    String? status,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    title: title ?? this.title,
    targetMinor: targetMinor ?? this.targetMinor,
    currentMinor: currentMinor ?? this.currentMinor,
    currency: currency ?? this.currency,
    dueDate: dueDate ?? this.dueDate,
    completed: completed ?? this.completed,
    profileId: profileId ?? this.profileId,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    goalType: goalType ?? this.goalType,
    status: status ?? this.status,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetMinor: data.targetMinor.present
          ? data.targetMinor.value
          : this.targetMinor,
      currentMinor: data.currentMinor.present
          ? data.currentMinor.value
          : this.currentMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      completed: data.completed.present ? data.completed.value : this.completed,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      status: data.status.present ? data.status.value : this.status,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('currentMinor: $currentMinor, ')
          ..write('currency: $currency, ')
          ..write('dueDate: $dueDate, ')
          ..write('completed: $completed, ')
          ..write('profileId: $profileId, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId, ')
          ..write('goalType: $goalType, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    targetMinor,
    currentMinor,
    currency,
    dueDate,
    completed,
    profileId,
    isSynced,
    remoteId,
    goalType,
    status,
    description,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetMinor == this.targetMinor &&
          other.currentMinor == this.currentMinor &&
          other.currency == this.currency &&
          other.dueDate == this.dueDate &&
          other.completed == this.completed &&
          other.profileId == this.profileId &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId &&
          other.goalType == this.goalType &&
          other.status == this.status &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> title;
  final Value<double> targetMinor;
  final Value<double> currentMinor;
  final Value<String> currency;
  final Value<DateTime> dueDate;
  final Value<bool> completed;
  final Value<int> profileId;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  final Value<String> goalType;
  final Value<String> status;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetMinor = const Value.absent(),
    this.currentMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completed = const Value.absent(),
    this.profileId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.goalType = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required double targetMinor,
    this.currentMinor = const Value.absent(),
    this.currency = const Value.absent(),
    required DateTime dueDate,
    this.completed = const Value.absent(),
    required int profileId,
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.goalType = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       targetMinor = Value(targetMinor),
       dueDate = Value(dueDate),
       profileId = Value(profileId);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<double>? targetMinor,
    Expression<double>? currentMinor,
    Expression<String>? currency,
    Expression<DateTime>? dueDate,
    Expression<bool>? completed,
    Expression<int>? profileId,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
    Expression<String>? goalType,
    Expression<String>? status,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetMinor != null) 'target_minor': targetMinor,
      if (currentMinor != null) 'current_minor': currentMinor,
      if (currency != null) 'currency': currency,
      if (dueDate != null) 'due_date': dueDate,
      if (completed != null) 'completed': completed,
      if (profileId != null) 'profile_id': profileId,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
      if (goalType != null) 'goal_type': goalType,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<double>? targetMinor,
    Value<double>? currentMinor,
    Value<String>? currency,
    Value<DateTime>? dueDate,
    Value<bool>? completed,
    Value<int>? profileId,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
    Value<String>? goalType,
    Value<String>? status,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetMinor: targetMinor ?? this.targetMinor,
      currentMinor: currentMinor ?? this.currentMinor,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      profileId: profileId ?? this.profileId,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
      goalType: goalType ?? this.goalType,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (currentMinor.present) {
      map['current_minor'] = Variable<double>(currentMinor.value);
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
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('currentMinor: $currentMinor, ')
          ..write('currency: $currency, ')
          ..write('dueDate: $dueDate, ')
          ..write('completed: $completed, ')
          ..write('profileId: $profileId, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId, ')
          ..write('goalType: $goalType, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalAmountMeta = const VerificationMeta(
    'principalAmount',
  );
  @override
  late final GeneratedColumn<double> principalAmount = GeneratedColumn<double>(
    'principal_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestModelMeta = const VerificationMeta(
    'interestModel',
  );
  @override
  late final GeneratedColumn<String> interestModel = GeneratedColumn<String>(
    'interest_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('simple'),
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    principalAmount,
    currency,
    interestRate,
    interestModel,
    startDate,
    endDate,
    profileId,
    description,
    isSynced,
    isDeleted,
    deletedAt,
    remoteId,
    createdAt,
    updatedAt,
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
    if (data.containsKey('principal_amount')) {
      context.handle(
        _principalAmountMeta,
        principalAmount.isAcceptableOrUnknown(
          data['principal_amount']!,
          _principalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalAmountMeta);
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
    } else if (isInserting) {
      context.missing(_interestRateMeta);
    }
    if (data.containsKey('interest_model')) {
      context.handle(
        _interestModelMeta,
        interestModel.isAcceptableOrUnknown(
          data['interest_model']!,
          _interestModelMeta,
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
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
      principalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}principal_amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      )!,
      interestModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_model'],
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
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
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
  final double principalAmount;
  final String currency;
  final double interestRate;
  final String interestModel;
  final DateTime startDate;
  final DateTime endDate;
  final int profileId;
  final String? description;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Loan({
    required this.id,
    required this.name,
    required this.principalAmount,
    required this.currency,
    required this.interestRate,
    required this.interestModel,
    required this.startDate,
    required this.endDate,
    required this.profileId,
    this.description,
    required this.isSynced,
    required this.isDeleted,
    this.deletedAt,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['principal_amount'] = Variable<double>(principalAmount);
    map['currency'] = Variable<String>(currency);
    map['interest_rate'] = Variable<double>(interestRate);
    map['interest_model'] = Variable<String>(interestModel);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['profile_id'] = Variable<int>(profileId);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      name: Value(name),
      principalAmount: Value(principalAmount),
      currency: Value(currency),
      interestRate: Value(interestRate),
      interestModel: Value(interestModel),
      startDate: Value(startDate),
      endDate: Value(endDate),
      profileId: Value(profileId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      principalAmount: serializer.fromJson<double>(json['principalAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      interestRate: serializer.fromJson<double>(json['interestRate']),
      interestModel: serializer.fromJson<String>(json['interestModel']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      profileId: serializer.fromJson<int>(json['profileId']),
      description: serializer.fromJson<String?>(json['description']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'principalAmount': serializer.toJson<double>(principalAmount),
      'currency': serializer.toJson<String>(currency),
      'interestRate': serializer.toJson<double>(interestRate),
      'interestModel': serializer.toJson<String>(interestModel),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'profileId': serializer.toJson<int>(profileId),
      'description': serializer.toJson<String?>(description),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Loan copyWith({
    int? id,
    String? name,
    double? principalAmount,
    String? currency,
    double? interestRate,
    String? interestModel,
    DateTime? startDate,
    DateTime? endDate,
    int? profileId,
    Value<String?> description = const Value.absent(),
    bool? isSynced,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Loan(
    id: id ?? this.id,
    name: name ?? this.name,
    principalAmount: principalAmount ?? this.principalAmount,
    currency: currency ?? this.currency,
    interestRate: interestRate ?? this.interestRate,
    interestModel: interestModel ?? this.interestModel,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    profileId: profileId ?? this.profileId,
    description: description.present ? description.value : this.description,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      principalAmount: data.principalAmount.present
          ? data.principalAmount.value
          : this.principalAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      interestModel: data.interestModel.present
          ? data.interestModel.value
          : this.interestModel,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      description: data.description.present
          ? data.description.value
          : this.description,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('principalAmount: $principalAmount, ')
          ..write('currency: $currency, ')
          ..write('interestRate: $interestRate, ')
          ..write('interestModel: $interestModel, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('profileId: $profileId, ')
          ..write('description: $description, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    principalAmount,
    currency,
    interestRate,
    interestModel,
    startDate,
    endDate,
    profileId,
    description,
    isSynced,
    isDeleted,
    deletedAt,
    remoteId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.name == this.name &&
          other.principalAmount == this.principalAmount &&
          other.currency == this.currency &&
          other.interestRate == this.interestRate &&
          other.interestModel == this.interestModel &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.profileId == this.profileId &&
          other.description == this.description &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> principalAmount;
  final Value<String> currency;
  final Value<double> interestRate;
  final Value<String> interestModel;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<int> profileId;
  final Value<String?> description;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.principalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.interestModel = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.profileId = const Value.absent(),
    this.description = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LoansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double principalAmount,
    this.currency = const Value.absent(),
    required double interestRate,
    this.interestModel = const Value.absent(),
    required DateTime startDate,
    required DateTime endDate,
    required int profileId,
    this.description = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       principalAmount = Value(principalAmount),
       interestRate = Value(interestRate),
       startDate = Value(startDate),
       endDate = Value(endDate),
       profileId = Value(profileId);
  static Insertable<Loan> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? principalAmount,
    Expression<String>? currency,
    Expression<double>? interestRate,
    Expression<String>? interestModel,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? profileId,
    Expression<String>? description,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (principalAmount != null) 'principal_amount': principalAmount,
      if (currency != null) 'currency': currency,
      if (interestRate != null) 'interest_rate': interestRate,
      if (interestModel != null) 'interest_model': interestModel,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (profileId != null) 'profile_id': profileId,
      if (description != null) 'description': description,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LoansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? principalAmount,
    Value<String>? currency,
    Value<double>? interestRate,
    Value<String>? interestModel,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<int>? profileId,
    Value<String?>? description,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      principalAmount: principalAmount ?? this.principalAmount,
      currency: currency ?? this.currency,
      interestRate: interestRate ?? this.interestRate,
      interestModel: interestModel ?? this.interestModel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      profileId: profileId ?? this.profileId,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (principalAmount.present) {
      map['principal_amount'] = Variable<double>(principalAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (interestModel.present) {
      map['interest_model'] = Variable<String>(interestModel.value);
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('principalAmount: $principalAmount, ')
          ..write('currency: $currency, ')
          ..write('interestRate: $interestRate, ')
          ..write('interestModel: $interestModel, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('profileId: $profileId, ')
          ..write('description: $description, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    type,
    category,
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
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
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
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
  final String type;
  final String category;
  const PendingTransaction({
    required this.id,
    required this.amountMinor,
    required this.currency,
    this.description,
    required this.date,
    required this.isExpense,
    this.rawSms,
    required this.profileId,
    required this.type,
    required this.category,
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
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
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
      type: Value(type),
      category: Value(category),
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
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
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
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
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
    String? type,
    String? category,
  }) => PendingTransaction(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    description: description.present ? description.value : this.description,
    date: date ?? this.date,
    isExpense: isExpense ?? this.isExpense,
    rawSms: rawSms.present ? rawSms.value : this.rawSms,
    profileId: profileId ?? this.profileId,
    type: type ?? this.type,
    category: category ?? this.category,
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
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
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
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('category: $category')
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
    type,
    category,
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
          other.profileId == this.profileId &&
          other.type == this.type &&
          other.category == this.category);
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
  final Value<String> type;
  final Value<String> category;
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
    this.type = const Value.absent(),
    this.category = const Value.absent(),
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
    this.type = const Value.absent(),
    this.category = const Value.absent(),
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
    Expression<String>? type,
    Expression<String>? category,
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
      if (type != null) 'type': type,
      if (category != null) 'category': category,
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
    Value<String>? type,
    Value<String>? category,
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
      type: type ?? this.type,
      category: category ?? this.category,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
          ..write('type: $type, ')
          ..write('category: $category, ')
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
    defaultValue: const Constant(50.0),
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
        defaultValue: const Constant(50.0),
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
    defaultValue: const Constant(5),
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
    defaultValue: const Constant(3),
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
    defaultValue: const Constant(0.0),
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
      Value<String> currency,
      Value<String> type,
      Value<String> description,
      Value<String> category,
      Value<String?> goalId,
      required DateTime date,
      Value<bool> isExpense,
      Value<bool> isPending,
      Value<String?> rawSms,
      required int profileId,
      Value<String?> budgetCategory,
      Value<String?> paymentMethod,
      Value<String?> merchantName,
      Value<String?> merchantCategory,
      Value<String?> tags,
      Value<String?> reference,
      Value<String?> recipient,
      Value<String> status,
      Value<bool> isRecurring,
      Value<bool> isSynced,
      Value<String?> remoteId,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<double> amountMinor,
      Value<String> currency,
      Value<String> type,
      Value<String> description,
      Value<String> category,
      Value<String?> goalId,
      Value<DateTime> date,
      Value<bool> isExpense,
      Value<bool> isPending,
      Value<String?> rawSms,
      Value<int> profileId,
      Value<String?> budgetCategory,
      Value<String?> paymentMethod,
      Value<String?> merchantName,
      Value<String?> merchantCategory,
      Value<String?> tags,
      Value<String?> reference,
      Value<String?> recipient,
      Value<String> status,
      Value<bool> isRecurring,
      Value<bool> isSynced,
      Value<String?> remoteId,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
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

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
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

  ColumnFilters<String> get budgetCategory => $composableBuilder(
    column: $table.budgetCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantCategory => $composableBuilder(
    column: $table.merchantCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipient => $composableBuilder(
    column: $table.recipient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
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

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
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

  ColumnOrderings<String> get budgetCategory => $composableBuilder(
    column: $table.budgetCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantCategory => $composableBuilder(
    column: $table.merchantCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipient => $composableBuilder(
    column: $table.recipient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isExpense =>
      $composableBuilder(column: $table.isExpense, builder: (column) => column);

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);

  GeneratedColumn<String> get rawSms =>
      $composableBuilder(column: $table.rawSms, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get budgetCategory => $composableBuilder(
    column: $table.budgetCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantCategory => $composableBuilder(
    column: $table.merchantCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get recipient =>
      $composableBuilder(column: $table.recipient, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
                Value<String> type = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isExpense = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
                Value<String?> rawSms = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String?> budgetCategory = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> merchantName = const Value.absent(),
                Value<String?> merchantCategory = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> recipient = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                type: type,
                description: description,
                category: category,
                goalId: goalId,
                date: date,
                isExpense: isExpense,
                isPending: isPending,
                rawSms: rawSms,
                profileId: profileId,
                budgetCategory: budgetCategory,
                paymentMethod: paymentMethod,
                merchantName: merchantName,
                merchantCategory: merchantCategory,
                tags: tags,
                reference: reference,
                recipient: recipient,
                status: status,
                isRecurring: isRecurring,
                isSynced: isSynced,
                remoteId: remoteId,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amountMinor,
                Value<String> currency = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                required DateTime date,
                Value<bool> isExpense = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
                Value<String?> rawSms = const Value.absent(),
                required int profileId,
                Value<String?> budgetCategory = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> merchantName = const Value.absent(),
                Value<String?> merchantCategory = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> recipient = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                type: type,
                description: description,
                category: category,
                goalId: goalId,
                date: date,
                isExpense: isExpense,
                isPending: isPending,
                rawSms: rawSms,
                profileId: profileId,
                budgetCategory: budgetCategory,
                paymentMethod: paymentMethod,
                merchantName: merchantName,
                merchantCategory: merchantCategory,
                tags: tags,
                reference: reference,
                recipient: recipient,
                status: status,
                isRecurring: isRecurring,
                isSynced: isSynced,
                remoteId: remoteId,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
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
      Value<double> currentMinor,
      Value<String> currency,
      required DateTime dueDate,
      Value<bool> completed,
      required int profileId,
      Value<bool> isSynced,
      Value<String?> remoteId,
      Value<String> goalType,
      Value<String> status,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<double> targetMinor,
      Value<double> currentMinor,
      Value<String> currency,
      Value<DateTime> dueDate,
      Value<bool> completed,
      Value<int> profileId,
      Value<bool> isSynced,
      Value<String?> remoteId,
      Value<String> goalType,
      Value<String> status,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
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

  ColumnFilters<double> get currentMinor => $composableBuilder(
    column: $table.currentMinor,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
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

  ColumnOrderings<double> get currentMinor => $composableBuilder(
    column: $table.currentMinor,
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

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
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

  GeneratedColumn<double> get currentMinor => $composableBuilder(
    column: $table.currentMinor,
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

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
                Value<double> currentMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> goalType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                title: title,
                targetMinor: targetMinor,
                currentMinor: currentMinor,
                currency: currency,
                dueDate: dueDate,
                completed: completed,
                profileId: profileId,
                isSynced: isSynced,
                remoteId: remoteId,
                goalType: goalType,
                status: status,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required double targetMinor,
                Value<double> currentMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                required DateTime dueDate,
                Value<bool> completed = const Value.absent(),
                required int profileId,
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> goalType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                title: title,
                targetMinor: targetMinor,
                currentMinor: currentMinor,
                currency: currency,
                dueDate: dueDate,
                completed: completed,
                profileId: profileId,
                isSynced: isSynced,
                remoteId: remoteId,
                goalType: goalType,
                status: status,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
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
      required double principalAmount,
      Value<String> currency,
      required double interestRate,
      Value<String> interestModel,
      required DateTime startDate,
      required DateTime endDate,
      required int profileId,
      Value<String?> description,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$LoansTableUpdateCompanionBuilder =
    LoansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> principalAmount,
      Value<String> currency,
      Value<double> interestRate,
      Value<String> interestModel,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<int> profileId,
      Value<String?> description,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
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

  ColumnFilters<double> get principalAmount => $composableBuilder(
    column: $table.principalAmount,
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

  ColumnFilters<String> get interestModel => $composableBuilder(
    column: $table.interestModel,
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
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

  ColumnOrderings<double> get principalAmount => $composableBuilder(
    column: $table.principalAmount,
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

  ColumnOrderings<String> get interestModel => $composableBuilder(
    column: $table.interestModel,
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
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

  GeneratedColumn<double> get principalAmount => $composableBuilder(
    column: $table.principalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interestModel => $composableBuilder(
    column: $table.interestModel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
                Value<double> principalAmount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> interestRate = const Value.absent(),
                Value<String> interestModel = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                name: name,
                principalAmount: principalAmount,
                currency: currency,
                interestRate: interestRate,
                interestModel: interestModel,
                startDate: startDate,
                endDate: endDate,
                profileId: profileId,
                description: description,
                isSynced: isSynced,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double principalAmount,
                Value<String> currency = const Value.absent(),
                required double interestRate,
                Value<String> interestModel = const Value.absent(),
                required DateTime startDate,
                required DateTime endDate,
                required int profileId,
                Value<String?> description = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                name: name,
                principalAmount: principalAmount,
                currency: currency,
                interestRate: interestRate,
                interestModel: interestModel,
                startDate: startDate,
                endDate: endDate,
                profileId: profileId,
                description: description,
                isSynced: isSynced,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
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
      Value<String> type,
      Value<String> category,
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
      Value<String> type,
      Value<String> category,
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
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
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
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
                type: type,
                category: category,
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
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
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
                type: type,
                category: category,
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
