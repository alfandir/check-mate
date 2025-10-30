import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task_model.dart';

class DBService {
  static late final Isar? isar;

  static Future<void> init() async {
    if (Isar.instanceNames.isNotEmpty) {
      isar = Isar.getInstance();
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([TaskModelSchema], directory: dir.path);
  }

  static Future<List<TaskModel>> getAll() async {
    return await isar?.taskModels.where().findAll() ?? [];
  }

  static Future<List<TaskModel>> getByDate(DateTime date) async {
    final key = DateTime(date.year, date.month, date.day);
    return await isar?.taskModels.filter().dateEqualTo(key).findAll() ?? [];
  }

  static Future<int> insert(TaskModel t) async {
    return await isar!.writeTxn(() async {
      return await isar!.taskModels.put(t);
    });
  }

  static Future<void> update(TaskModel t) async {
    await isar?.writeTxn(() async {
      await isar?.taskModels.put(t);
    });
  }

  static Future<void> deleteById(int id) async {
    await isar?.writeTxn(() async {
      await isar?.taskModels.delete(id);
    });
  }
}
