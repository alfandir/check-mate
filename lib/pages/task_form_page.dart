import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class TaskFormPage extends StatefulWidget {
  final TaskModel? task;
  final Function(TaskModel) onSave;

  const TaskFormPage({super.key, this.task, required this.onSave});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<DateTime> selectedDates = [];
  late TextEditingController activityCtrl;
  late TextEditingController noteCtrl;

  @override
  void initState() {
    super.initState();
    activityCtrl = TextEditingController(text: widget.task?.activity ?? '');
    noteCtrl = TextEditingController(text: widget.task?.note ?? '');

    if (widget.task != null) {
      startTime = _parseTime(widget.task!.startTime);
      endTime = _parseTime(widget.task!.endTime);

      if (widget.task!.repeatDatesJson != null) {
        selectedDates = (jsonDecode(widget.task!.repeatDatesJson!) as List)
            .map((e) => DateTime.parse(e))
            .toList();
      } else {
        selectedDates = [widget.task!.date];
      }
    } else {
      selectedDates = [DateTime.now()];
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && !_isDateSelected(picked)) {
      setState(() => selectedDates.add(picked));
    }
  }

  bool _isDateSelected(DateTime date) {
    return selectedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (startTime ?? TimeOfDay.now())
          : (endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          startTime = picked;
        else
          endTime = picked;
      });
    }
  }

  void _removeDate(DateTime date) {
    setState(() {
      selectedDates.removeWhere((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);
    });
  }

  int _durationInMinutes() {
    if (startTime == null || endTime == null) return 0;
    final s = startTime!.hour * 60 + startTime!.minute;
    final e = endTime!.hour * 60 + endTime!.minute;
    int diff = e - s;
    if (diff < 0) diff += 24 * 60;
    return diff;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu mulai dan selesai')),
      );
      return;
    }

    final start =
        "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
    final end =
        "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";
    final duration = _durationInMinutes();

    final model = TaskModel()
      ..activity = activityCtrl.text.trim()
      ..note = noteCtrl.text.trim()
      ..startTime = start
      ..endTime = end
      ..duration = duration
      ..date = selectedDates.first
      ..repeatDatesJson = jsonEncode(selectedDates
          .map((d) => DateFormat('yyyy-MM-dd').format(d))
          .toList());

    widget.onSave(model);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final duration = _durationInMinutes();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.task == null ? "Tambah Aktivitas" : "Edit Aktivitas"),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika aktivitas ini berulang, tambahkan lebih dari satu tanggal di bawah.',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bagian tanggal
              Text("Tanggal Aktivitas", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: -6,
                children: selectedDates.map((d) {
                  return Chip(
                    label:
                        Text(DateFormat('EEE, dd MMM yyyy', 'id_ID').format(d)),
                    backgroundColor: Colors.blue.shade50,
                    onDeleted: () => _removeDate(d),
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Tambah Tanggal"),
                ),
              ),
              const Divider(height: 32),

              // Bagian waktu
              Text("Waktu Aktivitas", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(startTime == null
                          ? "Mulai"
                          : startTime!.format(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.stop),
                      label: Text(endTime == null
                          ? "Selesai"
                          : endTime!.format(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                duration > 0
                    ? "Durasi: $duration menit"
                    : "Durasi belum dihitung",
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                    fontSize: 13),
              ),
              const Divider(height: 32),

              // Aktivitas
              TextFormField(
                controller: activityCtrl,
                decoration: InputDecoration(
                  labelText: "Nama Aktivitas",
                  prefixIcon: const Icon(Icons.task_alt_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // Catatan
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: "Catatan (opsional)",
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text("Simpan Aktivitas"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
