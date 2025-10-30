import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/db_service.dart';
import 'task_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  List<TaskModel> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadForDate(selectedDate);
  }

  Future<void> _loadForDate(DateTime d) async {
    setState(() => loading = true);
    final all = await DBService.getAll();
    final key = DateFormat('yyyy-MM-dd').format(d);
    final list = <TaskModel>[];
    for (var t in all) {
      if (t.repeatDatesJson != null) {
        final arr = (jsonDecode(t.repeatDatesJson!) as List)
            .map((e) => e.toString())
            .toList();
        if (arr.contains(key)) {
          list.add(t);
          continue;
        }
      }
      if (DateFormat('yyyy-MM-dd').format(t.date) == key) {
        list.add(t);
      }
    }
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    setState(() {
      tasks = list;
      loading = false;
    });
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      _loadForDate(picked);
    }
  }

  void addTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(onSave: (task) async {
          if (task.repeatDatesJson != null) {
            final arr = (jsonDecode(task.repeatDatesJson!) as List)
                .map((e) => e.toString())
                .toList();
            for (var d in arr) {
              final dt = DateFormat('yyyy-MM-dd').parse(d);
              final newTask = TaskModel()
                ..activity = task.activity
                ..note = task.note
                ..startTime = task.startTime
                ..endTime = task.endTime
                ..duration = task.duration
                ..date = dt;
              await DBService.insert(newTask);
            }
          } else {
            await DBService.insert(task);
          }
          _loadForDate(selectedDate);
        }),
      ),
    );
  }

  void editTask(int index) {
    final t = tasks[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          task: t,
          onSave: (newTask) async {
            await DBService.deleteById(t.id);
            if (newTask.repeatDatesJson != null) {
              final arr = (jsonDecode(newTask.repeatDatesJson!) as List)
                  .map((e) => e.toString())
                  .toList();
              for (var d in arr) {
                final dt = DateFormat('yyyy-MM-dd').parse(d);
                final nt = TaskModel()
                  ..activity = newTask.activity
                  ..note = newTask.note
                  ..startTime = newTask.startTime
                  ..endTime = newTask.endTime
                  ..duration = newTask.duration
                  ..date = dt;
                await DBService.insert(nt);
              }
            } else {
              newTask.id = t.id;
              await DBService.insert(newTask);
            }
            _loadForDate(selectedDate);
          },
        ),
      ),
    );
  }

  void deleteTask(int index) async {
    final t = tasks[index];
    await DBService.deleteById(t.id);
    _loadForDate(selectedDate);
  }

  void toggleDone(int index) async {
    final t = tasks[index];
    t.done = !t.done;
    await DBService.update(t);
    _loadForDate(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final formattedHeader =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinitas Harian'),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_today), onPressed: pickDate)
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedHeader,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  Text('${tasks.length} aktivitas',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? const Center(
                          child: Text('Belum ada aktivitas',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: tasks.length,
                          itemBuilder: (c, i) {
                            final t = tasks[i];
                            final timeText =
                                '${t.startTime} - ${t.endTime} • ${t.duration} menit';
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: GestureDetector(
                                  onTap: () => toggleDone(i),
                                  child: CircleAvatar(
                                    backgroundColor: t.done
                                        ? Colors.green
                                        : Colors.grey[300],
                                    child: t.done
                                        ? const Icon(Icons.check,
                                            color: Colors.white)
                                        : const Icon(Icons.circle_outlined,
                                            color: Colors.black45),
                                  ),
                                ),
                                title: Text(
                                  t.activity,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: t.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.access_time, size: 14),
                                      const SizedBox(width: 4),
                                      Text(timeText,
                                          style: const TextStyle(fontSize: 13)),
                                    ]),
                                    if (t.note.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.note_alt_outlined,
                                            size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(t.note,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') editTask(i);
                                    if (v == 'delete') deleteTask(i);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit')
                                        ])),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline, size: 18),
                                          SizedBox(width: 8),
                                          Text('Hapus')
                                        ])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aktivitas'),
      ),
    );
  }
}
