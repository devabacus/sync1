import '../database.dart';

abstract class IDatabaseService{
  Future<void> close();
  AppDatabase get database;
} 

