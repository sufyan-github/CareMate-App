import 'dart:io';
import 'dart:math';

import 'package:caremate/features/sync/data/caremate_local_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class EncryptedLocalDatabaseFactory {
  EncryptedLocalDatabaseFactory({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _databaseKeyName = 'caremate.local-database-key';
  final FlutterSecureStorage _secureStorage;

  Future<CareMateLocalDatabase> open() async {
    final key = await _databaseKey();
    final supportDirectory = await getApplicationSupportDirectory();
    final file = File(
      path.join(supportDirectory.path, 'caremate-local.sqlite'),
    );
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (database) {
        if (database.select('PRAGMA cipher;').isEmpty) {
          throw StateError(
            'The CareMate local database requires an encrypted SQLite build.',
          );
        }
        database.execute('PRAGMA key = "x\'$key\'";');
        database.execute('PRAGMA foreign_keys = ON;');
      },
    );
    return CareMateLocalDatabase(executor);
  }

  Future<String> _databaseKey() async {
    final existing = await _secureStorage.read(key: _databaseKeyName);
    if (existing != null && existing.length == 64) return existing;
    final random = Random.secure();
    final generated = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _secureStorage.write(key: _databaseKeyName, value: generated);
    return generated;
  }
}
