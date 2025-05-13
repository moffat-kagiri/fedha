import 'package:hive/hive.dart';

part 'profile.g.dart'; // Generated file

@HiveType(typeId: 0)
class Profile {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final bool isBusiness;
  
  Profile({required this.id, required this.isBusiness});
}