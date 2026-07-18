import 'dart:html' as html;
import 'dart:convert';
import 'package:drift/drift.dart';
// ignore: experimental_member_use
import 'package:drift/web.dart';

class SafeWebMockExecutor implements QueryExecutor {
  static bool _seeded = false;

  static final Map<String, List<Map<String, Object?>>> _tables = {
    'patients': [],
    'vaccinations': [],
    'inventory': [],
    'sync_queue': [],
    'sms_history': [],
  };

  SafeWebMockExecutor() {
    _seedData();
  }

  void _seedData() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();

    // 1. Try to load existing persisted data from browser LocalStorage
    try {
      final storedData = html.window.localStorage['asha_care_local_tables'];
      if (storedData != null) {
        final Map<String, dynamic> decoded = jsonDecode(storedData);
        decoded.forEach((key, value) {
          if (_tables.containsKey(key) && value is List) {
            _tables[key] = List<Map<String, Object?>>.from(
              value.map((item) => Map<String, Object?>.from(item as Map)),
            );
          }
        });
        return;
      }
    } catch (e) {
      print('LocalStorage load failed, falling back to clean seed: $e');
    }

    // Default Seed lists
    _tables['patients'] = [];
    _tables['vaccinations'] = [];
    _tables['sms_history'] = [];

    // Seed Inventory (clinic medicine stock, non-patient data)
    _tables['inventory'] = [
      {
        'id': 'INV001',
        'medicine_name': 'Albendazole',
        'stock_count': 5,
        'expiry_date': now.add(const Duration(days: 180)).millisecondsSinceEpoch ~/ 1000,
        'min_threshold': 10,
      },
      {
        'id': 'INV002',
        'medicine_name': 'Iron & Folic Acid',
        'stock_count': 150,
        'expiry_date': now.add(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000,
        'min_threshold': 50,
      },
      {
        'id': 'INV003',
        'medicine_name': 'Calcium',
        'stock_count': 80,
        'expiry_date': now.add(const Duration(days: 240)).millisecondsSinceEpoch ~/ 1000,
        'min_threshold': 30,
      },
      {
        'id': 'INV004',
        'medicine_name': 'Paracetamol',
        'stock_count': 8,
        'expiry_date': now.add(const Duration(days: 90)).millisecondsSinceEpoch ~/ 1000,
        'min_threshold': 15,
      },
    ];

    _saveToLocalStorage();
  }

  static void _saveToLocalStorage() {
    try {
      final jsonStr = jsonEncode(_tables);
      html.window.localStorage['asha_care_local_tables'] = jsonStr;
    } catch (e) {
      print('LocalStorage save failed: $e');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #ensureOpen) {
      return Future.value(true);
    }
    if (name == #dialect) {
      return SqlDialect.sqlite;
    }
    if (name == #beginTransaction || name == #beginExclusive) {
      return _SafeMockTransactionExecutor(this);
    }
    return Future.value(null);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(String statement, List<Object?> args) async {
    final table = _getTableFromStatement(statement);
    if (table == null || !_tables.containsKey(table)) {
      return [];
    }

    var list = List<Map<String, Object?>>.from(_tables[table]!);

    if (statement.contains('WHERE')) {
      final whereClause = statement.split('WHERE')[1].split('ORDER')[0].split('LIMIT')[0];
      final reg = RegExp(r'(\w+)\s*=\s*\?');
      final matches = reg.allMatches(whereClause).toList();
      for (var i = 0; i < matches.length && i < args.length; i++) {
        final colName = matches[i].group(1);
        final val = args[i];
        if (colName != null) {
          list = list.where((row) {
            final rowVal = row[colName];
            if (rowVal == null && val == null) return true;
            if (rowVal == null || val == null) return false;
            return rowVal.toString() == val.toString();
          }).toList();
        }
      }
    }

    if (statement.contains('ORDER BY')) {
      final orderClause = statement.split('ORDER BY')[1].split('LIMIT')[0];
      if (orderClause.contains('sent_at') && orderClause.contains('DESC')) {
        list.sort((a, b) {
          final aTime = a['sent_at'] as int? ?? 0;
          final bTime = b['sent_at'] as int? ?? 0;
          return bTime.compareTo(aTime);
        });
      }
    }

    if (statement.contains('LIMIT 1')) {
      if (list.isNotEmpty) {
        return [list.first];
      } else {
        return [];
      }
    }

    return list;
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final table = _getTableFromStatement(statement);
    if (table == null || !_tables.containsKey(table)) {
      return 0;
    }

    final colsStart = statement.indexOf('(');
    final colsEnd = statement.indexOf(')');
    if (colsStart == -1 || colsEnd == -1) return 0;
    final colsStr = statement.substring(colsStart + 1, colsEnd);
    final cols = colsStr.split(',').map((s) => s.trim().replaceAll('"', '')).toList();

    final row = <String, Object?>{};
    for (var i = 0; i < cols.length && i < args.length; i++) {
      row[cols[i]] = args[i];
    }

    final id = row['id'] ?? row['patient_id'];
    if (id != null) {
      _tables[table]!.removeWhere((r) => (r['id'] ?? r['patient_id']) == id);
    } else {
      final nextId = _tables[table]!.length + 1;
      row['id'] = nextId;
    }

    _tables[table]!.add(row);
    _saveToLocalStorage();
    return 1;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final table = _getTableFromStatement(statement);
    if (table == null || !_tables.containsKey(table)) {
      return 0;
    }
    if (args.isNotEmpty) {
      final id = args.last;
      final existingIndex = _tables[table]!.indexWhere((r) => r['id'] == id || r['patient_id'] == id);
      if (existingIndex != -1) {
        final existingRow = Map<String, Object?>.from(_tables[table]![existingIndex]);
        final setPart = statement.split('SET')[1].split('WHERE')[0];
        final reg = RegExp(r'(\w+)\s*=\s*\?');
        final matches = reg.allMatches(setPart).toList();
        for (var i = 0; i < matches.length && i < args.length - 1; i++) {
          final colName = matches[i].group(1);
          if (colName != null) {
            existingRow[colName] = args[i];
          }
        }
        _tables[table]![existingIndex] = existingRow;
        _saveToLocalStorage();
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async {
    final table = _getTableFromStatement(statement);
    if (table == null || !_tables.containsKey(table)) {
      return 0;
    }
    if (statement.contains('WHERE id = ?') && args.isNotEmpty) {
      final id = args.first;
      final lenBefore = _tables[table]!.length;
      _tables[table]!.removeWhere((r) => r['id'] == id || r['patient_id'] == id);
      _saveToLocalStorage();
      return lenBefore - _tables[table]!.length;
    }
    return 0;
  }

  String? _getTableFromStatement(String statement) {
    final lower = statement.toLowerCase();
    if (lower.contains('patients')) return 'patients';
    if (lower.contains('vaccinations')) return 'vaccinations';
    if (lower.contains('inventory')) return 'inventory';
    if (lower.contains('sync_queue')) return 'sync_queue';
    if (lower.contains('sms_history')) return 'sms_history';
    return null;
  }
}

class _SafeMockTransactionExecutor implements TransactionExecutor {
  final SafeWebMockExecutor _parent;
  _SafeMockTransactionExecutor(this._parent);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #ensureOpen) {
      return Future.value(true);
    }
    if (name == #dialect) {
      return SqlDialect.sqlite;
    }
    if (name == #runSelect) {
      return _parent.runSelect(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as List<Object?>,
      );
    }
    if (name == #runInsert) {
      return _parent.runInsert(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as List<Object?>,
      );
    }
    if (name == #runUpdate) {
      return _parent.runUpdate(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as List<Object?>,
      );
    }
    if (name == #runDelete) {
      return _parent.runDelete(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as List<Object?>,
      );
    }
    return Future.value(null);
  }
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    try {
      final req = await html.HttpRequest.request('sql-wasm.js', method: 'HEAD');
      if (req.status == 200) {
        return WebDatabase('asha_care_db', logStatements: true);
      }
    } catch (e) {
      print('sql-wasm.js check failed: $e');
    }
    print('sql-wasm.js is missing. Falling back to SafeWebMockExecutor.');
    return SafeWebMockExecutor();
  });
}
