// risk_assessment_service.dart
import 'dart:convert';
import 'package:drift/drift.dart'; // Add this import
import '../data/app_database.dart';

class RiskAssessmentService {
  final AppDatabase db;

  RiskAssessmentService(this.db);

  static const lossToleranceOptions = [
    {'label': 'I cannot accept any loss; I would sell', 'score': 10.0},
    {'label': 'I would be worried and likely sell', 'score': 25.0},
    {'label': 'I would hold and reassess', 'score': 50.0},
    {'label': 'I would buy more on dips', 'score': 75.0},
    {'label': 'I welcome volatility for higher returns', 'score': 90.0},
  ];

  static const experienceOptions = [
    {'label': 'No experience', 'score': 10.0},
    {'label': 'Limited experience (savings accounts / fixed deposits)', 'score': 30.0},
    {'label': 'Some experience (mutual funds / bonds)', 'score': 50.0},
    {'label': 'Experienced investor (equities, ETFs)', 'score': 70.0},
    {'label': 'Professional / frequent investor', 'score': 90.0},
  ];

  static const volatilityReactionOptions = [
    {'label': 'Sell immediately at first sign of drop', 'score': 10.0},
    {'label': 'Sell if loss exceeds 10%', 'score': 30.0},
    {'label': 'Hold and wait out short-term volatility', 'score': 50.0},
    {'label': 'Buy more on temporary dips', 'score': 75.0},
    {'label': 'Take advantage of volatility actively', 'score': 90.0},
  ];

  static const liquidityNeedOptions = [
    {'label': 'Need within 0-3 months', 'score': 10.0},
    {'label': '4-6 months', 'score': 30.0},
    {'label': '7-12 months', 'score': 50.0},
    {'label': '1-3 years', 'score': 70.0},
    {'label': '3+ years', 'score': 90.0},
  ];

  static const goalScores = {
    'Wealth Preservation': 15.0,
    'Short-term Income': 25.0,
    'Moderate Growth': 50.0,
    'Retirement Planning': 55.0,
    'Aggressive Growth': 85.0,
  };

  static const weights = {
    'goal': 0.12,
    'lossTolerance': 0.20,
    'experience': 0.12,
    'volatilityReaction': 0.12,
    'timeHorizon': 0.12,
    'desiredReturn': 0.08,
    'incomeRatio': 0.06,
    'liquidityNeed': 0.10,
    'emergencyFund': 0.08,
  };

  static double computeScore({
    String? selectedGoal,
    double incomeRatio = 50,
    double desiredReturnRatio = 50,
    double timeHorizon = 5,
    int? lossToleranceIndex,
    int? experienceIndex,
    int? volatilityReactionIndex,
    int? liquidityNeedIndex,
    int emergencyFundMonths = 3,
  }) {
    double goalComponent = (selectedGoal != null) ? (goalScores[selectedGoal] ?? 50.0) : 50.0;

    double lossComponent = (lossToleranceIndex != null)
        ? (lossToleranceOptions[lossToleranceIndex]['score'] as double)
        : 50.0;
    double expComponent = (experienceIndex != null)
        ? (experienceOptions[experienceIndex]['score'] as double)
        : 50.0;
    double volComponent = (volatilityReactionIndex != null)
        ? (volatilityReactionOptions[volatilityReactionIndex]['score'] as double)
        : 50.0;
    double liqComponent = (liquidityNeedIndex != null)
        ? (liquidityNeedOptions[liquidityNeedIndex]['score'] as double)
        : 50.0;

    double horizonComponent = (timeHorizon / 30.0) * 100.0;
    double desiredReturnComponent = desiredReturnRatio.clamp(0, 100);
    double incomeComponent = (100 - incomeRatio).clamp(0, 100);

    double emergencyComponent;
    if (emergencyFundMonths <= 1)
      emergencyComponent = 90.0;
    else if (emergencyFundMonths <= 3)
      emergencyComponent = 70.0;
    else if (emergencyFundMonths <= 6)
      emergencyComponent = 50.0;
    else if (emergencyFundMonths <= 12)
      emergencyComponent = 30.0;
    else
      emergencyComponent = 10.0;

    double score = 0.0;
    score += (goalComponent * (weights['goal']!));
    score += (lossComponent * (weights['lossTolerance']!));
    score += (expComponent * (weights['experience']!));
    score += (volComponent * (weights['volatilityReaction']!));
    score += (horizonComponent * (weights['timeHorizon']!));
    score += (desiredReturnComponent * (weights['desiredReturn']!));
    score += (incomeComponent * (weights['incomeRatio']!));
    score += (liqComponent * (weights['liquidityNeed']!));
    score += (emergencyComponent * (weights['emergencyFund']!));

    return double.parse(score.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  static String profileFromScore(double s) {
    if (s < 34) return 'Conservative';
    if (s < 67) return 'Moderate';
    return 'Aggressive';
  }

  static Map<String, int> recommendedAllocation(String profile) {
    switch (profile) {
      case 'Conservative':
        return {'Bonds/Cash': 70, 'Equities': 20, 'Alternatives': 10};
      case 'Moderate':
        return {'Bonds/Cash': 40, 'Equities': 50, 'Alternatives': 10};
      case 'Aggressive':
      default:
        return {'Bonds/Cash': 15, 'Equities': 75, 'Alternatives': 10};
    }
  }

  Future<int> saveAssessment({
    String? userId,
    String? goal,
    double incomeRatio = 50,
    double desiredReturnRatio = 50,
    int timeHorizon = 5,
    int? lossToleranceIndex,
    int? experienceIndex,
    int? volatilityReactionIndex,
    int? liquidityNeedIndex,
    int emergencyFundMonths = 3,
  }) async {
    final score = computeScore(
      selectedGoal: goal,
      incomeRatio: incomeRatio,
      desiredReturnRatio: desiredReturnRatio,
      timeHorizon: timeHorizon.toDouble(),
      lossToleranceIndex: lossToleranceIndex,
      experienceIndex: experienceIndex,
      volatilityReactionIndex: volatilityReactionIndex,
      liquidityNeedIndex: liquidityNeedIndex,
      emergencyFundMonths: emergencyFundMonths,
    );

    final profile = profileFromScore(score);
    final allocation = recommendedAllocation(profile);

    final answers = {
      'lossToleranceIndex': lossToleranceIndex,
      'experienceIndex': experienceIndex,
      'volatilityReactionIndex': volatilityReactionIndex,
      'liquidityNeedIndex': liquidityNeedIndex,
      'emergencyFundMonths': emergencyFundMonths,
    };

    final companion = RiskAssessmentsCompanion(
      userId: Value(userId),
      goal: Value(goal),
      incomeRatio: Value(incomeRatio),
      desiredReturnRatio: Value(desiredReturnRatio),
      timeHorizon: Value(timeHorizon),
      lossToleranceIndex: Value(lossToleranceIndex),
      experienceIndex: Value(experienceIndex),
      volatilityReactionIndex: Value(volatilityReactionIndex),
      liquidityNeedIndex: Value(liquidityNeedIndex),
      emergencyFundMonths: Value(emergencyFundMonths),
      riskScore: Value(score),
      profile: Value(profile),
      allocationJson: Value(allocation.isNotEmpty ? jsonEncode(allocation) : null),
      answersJson: Value(jsonEncode(answers)),
    );

    return await db.into(db.riskAssessments).insert(companion);
  }

  Future<RiskAssessment?> getLatestForUser(String? userId) async {
    final query = (db.select(db.riskAssessments)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(1));

    if (userId != null) query.where((tbl) => tbl.userId.equals(userId));

    final row = await query.getSingleOrNull();
    return row;
  }

  Future<RiskAssessment?> getDetailedLatest(String? userId) async {
    final row = await getLatestForUser(userId);
    if (row == null) return null;
    
    final allocation = row.allocationJson != null
      ? Map<String, int>.from(jsonDecode(row.allocationJson!))
      : recommendedAllocation(row.profile!);
      
    final answers = row.answersJson != null
      ? Map<String, dynamic>.from(jsonDecode(row.answersJson!))
      : {};
      
    return row;
  }
}