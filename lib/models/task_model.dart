import 'package:isar/isar.dart';

part 'task_model.g.dart';

@Collection()
class TaskModel {
  Id id = Isar.autoIncrement;

  late String activity;
  String note = '';
  late String startTime; // "HH:mm"
  late String endTime;   // "HH:mm"
  late int duration; // minutes
  late DateTime date; // the date this entry belongs to
  bool done = false;

  // optional JSON for multi-date selection when creating
  String? repeatDatesJson; // JSON encoded list of yyyy-MM-dd strings
}