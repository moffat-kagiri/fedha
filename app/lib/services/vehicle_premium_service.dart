import 'dart:math';

// This function estimates the annual comprehensive insurance premium in KES.
double _placeholder_keep_original_comment() {
  return 0;
}

/// --- CONFIGURATION ---

const int CURRENT_YEAR = 2025;
const int MAX_COMPREHENSIVE_VEHICLE_AGE = 15;
const double TPO_MINIMUM = 7500.0;

const double DEFAULT_LEVIES = 1000.0;
const double CATEGORY_WEIGHT = 0.075;

const double BASE_MIN_LOW = 37500.0;
const double BASE_MIN_MID = 60000.0;
const double BASE_MIN_HIGH = 87500.0;

final Map<String, List<String>> makeCategoryMap = {
  'generic': [
    'toyota',
    'mazda',
    'nissan',
    'honda',
    'subaru',
    'mitsubishi',
    'kia',
    'hyundai'
  ],
  'premium': [
    'bmw',
    'mercedes',
    'audi',
    'range rover',
    'jaguar',
    'volvo'
  ],
  'luxury': [
    'porsche',
    'maserati',
    'tesla',
    'rolls-royce',
    'bentley'
  ],
};

enum VehicleCategory { generic, premium, luxury }

String vehicleCategoryToString(VehicleCategory c) {
  return c.name;
}

List<int> generateYearOptions({int spanYears = 30}) {
  return List.generate(spanYears + 1, (i) => CURRENT_YEAR - i);
}

VehicleCategory categoryFromMake(String make) {
  final lc = make.toLowerCase();
  if (_matches(lc, makeCategoryMap['luxury']!)) return VehicleCategory.luxury;
  if (_matches(lc, makeCategoryMap['premium']!)) return VehicleCategory.premium;
  return VehicleCategory.generic;
}

bool _matches(String makeLower, List<String> list) {
  for (var v in list) {
    if (makeLower.contains(v.toLowerCase())) return true;
  }
  return false;
}

/// Premium Breakdown Output Model
class PremiumBreakdown {
  final double basePremium;
  final double claimsLoadingAmount;
  final double preMinimumPremium;
  final double minimumPremiumApplied;
  final bool isMinimumEnforced;
  final double levies;
  final double totalPremium;
  final VehicleCategory category;
  final double repairToValueRatio;
  final bool tpoFallback;

  PremiumBreakdown({
    required this.basePremium,
    required this.claimsLoadingAmount,
    required this.preMinimumPremium,
    required this.minimumPremiumApplied,
    required this.isMinimumEnforced,
    required this.levies,
    required this.totalPremium,
    required this.category,
    required this.repairToValueRatio,
    required this.tpoFallback,
  });
}

/// --- MAIN CALCULATION ENGINE ---
PremiumBreakdown estimatePremiumDetailed({
  required double vehicleValue,
  required String make,
  required int yearOfManufacture,
  required double totalRepairCostsLast3Years,
  double categoryWeight = CATEGORY_WEIGHT,
  double levies = DEFAULT_LEVIES,
}) {
  // Ineligible → TPO fallback
  if (CURRENT_YEAR - yearOfManufacture >= MAX_COMPREHENSIVE_VEHICLE_AGE ||
      vehicleValue < 500000) {
    return PremiumBreakdown(
      basePremium: 0,
      claimsLoadingAmount: 0,
      preMinimumPremium: TPO_MINIMUM,
      minimumPremiumApplied: TPO_MINIMUM,
      isMinimumEnforced: true,
      levies: 0,
      totalPremium: TPO_MINIMUM,
      category: categoryFromMake(make),
      repairToValueRatio: 0,
      tpoFallback: true,
    );
  }

  // Base rate logic (preserved from your script)
  double baseRate;
  final lower = make.toLowerCase();
  if (lower.contains('bmw') ||
      lower.contains('mercedes') ||
      lower.contains('range rover')) {
    baseRate = 4.5;
  } else if (lower.contains('toyota') ||
      lower.contains('mazda') ||
      lower.contains('subaru')) {
    baseRate = 3.8;
  } else {
    baseRate = 4.0;
  }

  if (vehicleValue >= 2500000) {
    baseRate = min(baseRate, 3.5);
  } else if (vehicleValue >= 1500000) {
    baseRate = min(baseRate, 4.0);
  }

  final basePremium = vehicleValue * (baseRate / 100);

  // Claims loading – Option A (your custom intervals)
  double ratio = totalRepairCostsLast3Years / vehicleValue;
  double loading = 0;
  if (ratio <= 0.35) {
    loading = 0;
  } else if (ratio <= 0.50) {
    loading = basePremium * 0.05;
  } else if (ratio <= 0.65) {
    loading = basePremium * 0.10;
  } else {
    loading = basePremium * 0.20;
  }

  final preMin = basePremium + loading;

  // Minimum premium logic (value bracket + category multiplier)
  double baseMin = BASE_MIN_LOW;
  if (vehicleValue >= 1500000 && vehicleValue < 2500000) {
    baseMin = BASE_MIN_MID;
  } else if (vehicleValue >= 2500000) {
    baseMin = BASE_MIN_HIGH;
  }

  final category = categoryFromMake(make);
  final weightedMin = baseMin * (1 + category.index * categoryWeight);

  bool enforced = false;
  double appliedMin = 0;
  double postMin = preMin;

  if (preMin < weightedMin) {
    enforced = true;
    appliedMin = weightedMin;
    postMin = weightedMin;
  }

  final total = postMin + levies;

  return PremiumBreakdown(
    basePremium: basePremium,
    claimsLoadingAmount: loading,
    preMinimumPremium: preMin,
    minimumPremiumApplied: appliedMin,
    isMinimumEnforced: enforced,
    levies: levies,
    totalPremium: total,
    category: category,
    repairToValueRatio: ratio,
    tpoFallback: false,
  );
}
