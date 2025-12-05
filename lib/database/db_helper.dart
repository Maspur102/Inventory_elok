import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  DbHelper._internal();
  factory DbHelper() => _instance;

  Future<Database?> get database async {
    if (kIsWeb) return null; 
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'elok_alfa_v4.db'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE bahan(id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, satuan TEXT, stok INTEGER, harga_beli INTEGER)');
        await db.execute('CREATE TABLE produk(id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, kategori TEXT, harga_modal INTEGER, harga_jual INTEGER, stok INTEGER)');
        await db.execute('CREATE TABLE transaksi(id INTEGER PRIMARY KEY AUTOINCREMENT, tipe TEXT, deskripsi TEXT, nominal INTEGER, tanggal TEXT, metode_bayar TEXT, uang_diterima INTEGER, bukti_foto TEXT)');
      },
    );
  }

  // --- CRUD BAHAN ---
  // Ubah return void jadi Future<int> agar kita tahu ID barunya
  Future<int> insertBahan(BahanBaku b) async {
    final db = await database;
    if (db != null) return await db.insert('bahan', b.toMap());
    return 0;
  }
  Future<void> updateBahan(BahanBaku b) async {
    final db = await database;
    if (db != null) await db.update('bahan', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }
  Future<void> deleteBahan(int id) async {
    final db = await database;
    if (db != null) await db.delete('bahan', where: 'id = ?', whereArgs: [id]);
  }
  Future<List<BahanBaku>> getBahan() async {
    final db = await database;
    if (db == null) return [];
    final maps = await db.query('bahan');
    return List.generate(maps.length, (i) => BahanBaku.fromMap(maps[i]));
  }

  // --- CRUD PRODUK ---
  Future<int> insertProduk(Produk p) async {
    final db = await database;
    if (db != null) return await db.insert('produk', p.toMap());
    return 0;
  }
  Future<void> updateProduk(Produk p) async {
    final db = await database;
    if (db != null) await db.update('produk', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }
  Future<void> deleteProduk(int id) async {
    final db = await database;
    if (db != null) await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }
  Future<List<Produk>> getProduk() async {
    final db = await database;
    if (db == null) return [];
    final maps = await db.query('produk');
    return List.generate(maps.length, (i) => Produk.fromMap(maps[i]));
  }

  // --- CRUD TRANSAKSI ---
  // Ubah return jadi Future<int> (PENTING)
  Future<int> insertTransaksi(Transaksi t) async {
    final db = await database;
    if (db != null) return await db.insert('transaksi', t.toMap());
    return 0;
  }
  Future<List<Transaksi>> getTransaksi() async {
    final db = await database;
    if (db == null) return [];
    final maps = await db.query('transaksi', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Transaksi.fromMap(maps[i]));
  }
  Future<void> deleteTransaksi(int id) async {
    final db = await database;
    if (db != null) await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> updateTransaksi(Transaksi t) async {
    final db = await database;
    if (db != null) await db.update('transaksi', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }
}