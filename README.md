Routine Isar App (sample)
=========================

This is a minimal sample Flutter app that uses Isar to store routine tasks.
Each task has:
- activity, note, startTime (HH:mm), endTime (HH:mm), duration (minutes), date (yyyy-MM-dd), done flag

Features:
- Add task with multiple chosen dates (form returns repeatDatesJson which is expanded into separate TaskModel entries)
- Edit/Delete/Toggle done
- View tasks per selected date (calendar picker in app bar)

How to run:
1. Unzip the project into a Flutter project directory (or replace lib/ and pubspec.yaml).
2. Run `flutter pub get`
3. Run code generation for Isar:

   flutter pub run build_runner build --delete-conflicting-outputs

4. Run on device/emulator: `flutter run`

Notes:
- Generated file lib/models/task_model.g.dart is required by Isar. Run build_runner to produce it.
- This sample uses isar & isar_flutter_libs; make sure you use compatible versions for your Flutter SDK.