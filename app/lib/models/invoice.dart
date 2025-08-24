import 'package:json_annotation/json_annotation.dart';
part 'budget.g.dart';

@JsonSerializable()
class Budget {
  String id;
  String name;
  String? description;
  double budgetAmount;
  // … other fields, getters, constructors, toJson/fromJson, etc.
}
