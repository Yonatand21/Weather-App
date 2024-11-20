import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cities.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertCity(String name) async {
    final db = await database;
    await db.insert('cities', {'name': name});
  }

  Future<List<String>> getCities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cities');
    return List.generate(maps.length, (i) {
      return maps[i]['name'];
    });
  }

  Future<List<String>> getCitySuggestions(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cities',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) {
      return maps[i]['name'];
    });
  }
}


class CSVHelper {
  Future<List<Map<String, String>>> getCitySuggestions(String query) async {
    final csvData = await _loadCSV();
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
    return rows
        .where((row) => row[3].toString().toLowerCase().startsWith(query.toLowerCase()))
        .map((row) => {
      'state_name': row[2].toString(),
      'city': row[3].toString(),
    })
        .toList();
  }

  Future<String> _loadCSV() async {
    return await rootBundle.loadString('assets/us_cities.csv');
  }
}