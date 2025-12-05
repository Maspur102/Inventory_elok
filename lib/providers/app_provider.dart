import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../database/db_helper.dart';

class AppProvider with ChangeNotifier {
  final DbHelper _db = DbHelper();
  
  List<BahanBaku> _bahanList = [];
  List<Produk> _produkList = [];
  List<Transaksi> _transaksiList = [];
  
  List<BahanBaku> get bahanList => _bahanList;
  List<Produk> get produkList => _produkList;
  List<Transaksi> get transaksiList => _transaksiList;

  int get totalPemasukan => _transaksiList.where((t) => t.tipe == 'MASUK').fold(0, (sum, t) => sum + t.nominal);
  int get totalPengeluaran => _transaksiList.where((t) => t.tipe == 'KELUAR').fold(0, (sum, t) => sum + t.nominal);
  int get saldoBersih => totalPemasukan - totalPengeluaran;

  Future<void> loadData() async {
    if (kIsWeb) {
      if (_produkList.isEmpty) {
        _produkList = [
          Produk(id: 1, nama: "Kripik Coklat", kategori: "Manis", hargaModal: 3000, hargaJual: 5000, stok: 20),
          Produk(id: 2, nama: "Kripik Balado", kategori: "Pedas", hargaModal: 3000, hargaJual: 5000, stok: 15),
        ];
        _bahanList = [
          BahanBaku(id: 1, nama: "Pisang Mentah", satuan: "Sisir", stok: 20, hargaBeliTerakhir: 15000),
        ];
      }
    } else {
      _bahanList = await _db.getBahan();
      _produkList = await _db.getProduk();
      // PENTING: Ambil data transaksi terbaru dari DB
      _transaksiList = await _db.getTransaksi();
    }
    notifyListeners();
  }

  // --- CRUD PRODUK ---
  Future<void> simpanProduk(Produk p, bool isEdit) async {
    if (isEdit) {
      int index = _produkList.indexWhere((element) => element.id == p.id);
      if (index != -1) {
        if (!kIsWeb) await _db.updateProduk(p);
      }
    } else {
      if (!kIsWeb) {
        await _db.insertProduk(p);
      } else {
        // Dummy web logic
        int newId = DateTime.now().millisecondsSinceEpoch;
        Produk baru = Produk(id: newId, nama: p.nama, kategori: p.kategori, hargaModal: p.hargaModal, hargaJual: p.hargaJual, stok: p.stok);
        _produkList.add(baru);
      }
    }
    // Refresh semua data untuk memastikan ID sinkron
    await loadData();
  }

  Future<void> hapusProduk(int id) async {
    if (!kIsWeb) await _db.deleteProduk(id);
    await loadData();
  }

  // --- CRUD BAHAN ---
  Future<void> belanjaBahan(String nama, String satuan, int jumlah, int totalHarga) async {
    // 1. Simpan Transaksi
    Transaksi trxDraft = Transaksi(
      tipe: 'KELUAR', 
      deskripsi: 'Beli $jumlah $satuan $nama', 
      nominal: totalHarga, 
      tanggal: DateTime.now().toString(),
      metodeBayar: 'Tunai',
      uangDiterima: totalHarga
    );

    if (!kIsWeb) await _db.insertTransaksi(trxDraft);
    
    // 2. Update Stok Bahan
    // Kita load dulu bahan terbaru dari DB agar tidak duplikat
    await loadData(); 
    
    int index = _bahanList.indexWhere((b) => b.nama.toLowerCase() == nama.toLowerCase());
    if (index != -1) {
      BahanBaku update = _bahanList[index];
      update.stok += jumlah;
      update.hargaBeliTerakhir = (totalHarga / jumlah).round();
      if (!kIsWeb) await _db.updateBahan(update);
    } else {
      BahanBaku baru = BahanBaku(id: null, nama: nama, satuan: satuan, stok: jumlah, hargaBeliTerakhir: (totalHarga / jumlah).round());
      if (!kIsWeb) await _db.insertBahan(baru);
    }

    // 3. FORCE REFRESH agar tampil di history
    await loadData();
  }

  Future<void> hapusBahan(int id) async {
    if (!kIsWeb) await _db.deleteBahan(id);
    await loadData();
  }

  // --- TRANSAKSI KASIR (FIX HISTORY KOSONG) ---
  Future<void> bayarTransaksi(Map<Produk, int> cart, String metode, int uangDiterima, String? buktiFoto) async {
    int totalUang = 0;
    List<String> detailItems = [];

    for (var entry in cart.entries) {
      Produk p = entry.key;
      int qty = entry.value;
      
      // Update stok produk
      p.stok -= qty;
      if (!kIsWeb) await _db.updateProduk(p);
      
      totalUang += (p.hargaJual * qty);
      detailItems.add("${p.nama} x$qty");
    }

    String deskripsi = detailItems.join(", ");

    Transaksi trx = Transaksi(
      tipe: 'MASUK', 
      deskripsi: deskripsi, 
      nominal: totalUang, 
      tanggal: DateTime.now().toString(),
      metodeBayar: metode,
      uangDiterima: uangDiterima,
      buktiFoto: buktiFoto
    );

    // Simpan ke DB
    if (!kIsWeb) await _db.insertTransaksi(trx);

    // KUNCI PERBAIKAN: Panggil loadData() untuk menarik ulang data dari DB ke Layar
    await loadData();
  }

  // --- EDIT & HAPUS TRANSAKSI ---
  Future<void> hapusTransaksi(int id) async {
    if (!kIsWeb) await _db.deleteTransaksi(id);
    await loadData();
  }

  Future<void> updateTransaksi(Transaksi t) async {
    if (!kIsWeb) await _db.updateTransaksi(t);
    await loadData();
  }
}