// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_assessment_service.dart';

// ignore_for_file: type=lint
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
  late final $RiskAssessmentsTable riskAssessments = $RiskAssessmentsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [riskAssessments];
}

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
  $$RiskAssessmentsTableTableManager get riskAssessments =>
      $$RiskAssessmentsTableTableManager(_db, _db.riskAssessments);
}
