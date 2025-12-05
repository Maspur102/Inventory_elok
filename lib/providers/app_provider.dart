import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asumsi Anda memiliki file db_helper.dart
import '../database/db_helper.dart'; 
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
  // Asumsi DBHelper sudah diimplementasikan di lib/database/db_helper.dart
  final DBHelper _dbHelper = DBHelper();
  
  List<Produk> _produkList = [];
  List<BahanBaku> _bahanList = [];
  List<Transaksi> _transaksiList = [];

  List<Produk> get produkList => _produkList;
  List<BahanBaku> get bahanList => _bahanList;
  List<Transaksi> get transaksiList => _transaksiList.reversed.toList(); 

  int get totalPemasukan => _transaksiList.where((t) => t.tipe == 'MASUK').fold(0, (sum, item) => sum + item.nominal);
  int get totalPengeluaran => _transaksiList.where((t) => t.tipe == 'KELUAR').fold(0, (sum, item) => sum + item.nominal);
  int get saldoBersih => totalPemasukan - totalPengeluaran;

  Future<void> loadData() async {
    // Pastikan _dbHelper.openDb() ada dan berfungsi
    await _dbHelper.openDb();
    _produkList = await _dbHelper.getProdukList();
    _bahanList = await _dbHelper.getBahanList();
    _transaksiList = await _dbHelper.getTransaksiList();
    notifyListeners();
  }

  // --- CRUD PRODUK ---
  Future<void> simpanProduk(Produk produk, bool isEdit) async {
    if (isEdit) {
      await _dbHelper.updateProduk(produk);
    } else {
      produk.id = DateTime.now().millisecondsSinceEpoch.toString();
      await _dbHelper.insertProduk(produk);
    }
    await loadData(); 
  }

  Future<void> hapusProduk(String id) async {
    await _dbHelper.deleteProduk(id);
    await loadData();
  }
  
  // --- CRUD BAHAN ---
  Future<void> hapusBahan(String id) async {
    await _dbHelper.deleteBahan(id);
    await loadData();
  }

  Future<void> belanjaBahan(String nama, String satuan, int jumlah, int totalHarga) async {
    // FIX NULL SAFETY: Gunakan where/firstWhere yang mengembalikan elemen null, 
    // lalu periksa secara eksplisit sebelum mengakses properti.
    final existingBahan = _bahanList.where((b) => b.nama.toLowerCase() == nama.toLowerCase()).toList();
    
    if (existingBahan.isNotEmpty) {
      final bahanToUpdate = existingBahan.first;
      bahanToUpdate.stok += jumlah.toDouble();
      bahanToUpdate.hargaBeliTerakhir = totalHarga;
      await _dbHelper.updateBahan(bahanToUpdate);
    } else {
      final newBahan = BahanBaku(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nama: nama,
        satuan: satuan,
        stok: jumlah.toDouble(),
        hargaBeliTerakhir: totalHarga,
      );
      await _dbHelper.insertBahan(newBahan);
    }
    
    // Mencatat transaksi pembelian bahan (KELUAR)
    final transaksi = Transaksi(
      tipe: 'KELUAR',
      deskripsi: 'Pembelian Bahan: $nama ($jumlah $satuan)',
      nominal: totalHarga,
      tanggal: DateTime.now().toIso8601String(),
      metodeBayar: 'Tunai', 
    );
    await _dbHelper.insertTransaksi(transaksi);

    await loadData();
  }

  // --- CRUD TRANSAKSI ---
  Future<void> updateTransaksi(Transaksi t) async {
    await _dbHelper.updateTransaksi(t);
    await loadData();
  }

  Future<void> hapusTransaksi(String id) async {
    await _dbHelper.deleteTransaksi(id);
    await loadData();
  }
  
  // --- LOGIC PEMBAYARAN KASIR ---
  Future<void> bayarTransaksi(Map<Produk, int> cart, String metode, int uangDiterima, String? buktiPath) async {
    if (cart.isEmpty) return;

    int totalTagihan = 0;
    List<String> deskripsiItems = [];

    // 1. Hitung total dan update stok produk
    for (var entry in cart.entries) {
      final produk = entry.key;
      final quantity = entry.value;
      totalTagihan += (produk.hargaJual * quantity);
      deskripsiItems.add("${produk.nama} (${quantity}x)");

      // Update stok
      produk.stok -= quantity;
      await _dbHelper.updateProduk(produk);
    }
    
    // 2. Buat objek Transaksi (TIPE MASUK)
    final Transaksi transaksiBaru = Transaksi(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipe: 'MASUK', // Pemasukan dari Penjualan
      deskripsi: deskripsiItems.join(", "), // Contoh: "Keripik (2x), Saus (1x)"
      nominal: totalTagihan,
      tanggal: DateTime.now().toIso8601String(),
      metodeBayar: metode,
      uangDiterima: (metode == 'Tunai') ? uangDiterima : totalTagihan,
      buktiFoto: buktiPath,
    );
    
    // 3. Simpan transaksi ke database
    await _dbHelper.insertTransaksi(transaksiBaru);

    // 4. Reload data untuk update UI (Kasir & Laporan)
    await loadData();
  }
}

// --- Asumsi Implementasi DBHelper (TIDAK PERLU DI SALIN) ---
// Pastikan Anda memiliki implementasi yang benar di lib/database/db_helper.dart
class DBHelper {
  DBHelper._internal();
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  Future<void> openDb() async {}
  Future<void> insertProduk(Produk p) async {}
  Future<void> updateProduk(Produk p) async {}
  Future<void> deleteProduk(String id) async {}
  Future<List<Produk>> getProdukList() async => []; 

  Future<void> insertBahan(BahanBaku b) async {}
  Future<void> updateBahan(BahanBaku b) async {}
  Future<void> deleteBahan(String id) async {}
  Future<List<BahanBaku>> getBahanList() async => [];

  Future<void> insertTransaksi(Transaksi t) async {}
  Future<void> updateTransaksi(Transaksi t) async {}
  Future<void> deleteTransaksi(String id) async {}
  Future<List<Transaksi>> getTransaksiList() async => [];
}