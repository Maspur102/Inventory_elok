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

  void loadData() async {
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
      _transaksiList = await _db.getTransaksi();
    }
    notifyListeners();
  }

  // --- CRUD PRODUK ---
  Future<void> simpanProduk(Produk p, bool isEdit) async {
    if (isEdit) {
      int index = _produkList.indexWhere((element) => element.id == p.id);
      if (index != -1) {
        _produkList[index] = p;
        if (!kIsWeb) await _db.updateProduk(p);
      }
    } else {
      // Logic ID Baru
      int newId = kIsWeb ? DateTime.now().millisecondsSinceEpoch : 0;
      if (!kIsWeb) {
        newId = await _db.insertProduk(p); // Dapat ID dari DB
      }
      
      Produk produkBaru = Produk(
        id: newId, 
        nama: p.nama, 
        kategori: p.kategori, 
        hargaModal: p.hargaModal, 
        hargaJual: p.hargaJual, 
        stok: p.stok
      );
      _produkList.add(produkBaru);
    }
    notifyListeners();
  }

  Future<void> hapusProduk(int id) async {
    _produkList.removeWhere((p) => p.id == id);
    if (!kIsWeb) await _db.deleteProduk(id);
    notifyListeners();
  }

  // --- CRUD BAHAN ---
  Future<void> belanjaBahan(String nama, String satuan, int jumlah, int totalHarga) async {
    // Siapkan data transaksi (tanpa ID dulu)
    Transaksi trxDraft = Transaksi(
      tipe: 'KELUAR', 
      deskripsi: 'Beli $jumlah $satuan $nama', 
      nominal: totalHarga, 
      tanggal: DateTime.now().toString(),
      metodeBayar: 'Tunai',
      uangDiterima: totalHarga
    );

    // INSERT & DAPATKAN ID
    int trxId = kIsWeb ? DateTime.now().millisecondsSinceEpoch : 0;
    if (!kIsWeb) {
      trxId = await _db.insertTransaksi(trxDraft);
    }

    // Buat objek final dengan ID yang benar
    Transaksi trxFinal = Transaksi(
      id: trxId,
      tipe: trxDraft.tipe,
      deskripsi: trxDraft.deskripsi,
      nominal: trxDraft.nominal,
      tanggal: trxDraft.tanggal,
      metodeBayar: trxDraft.metodeBayar,
      uangDiterima: trxDraft.uangDiterima
    );
    
    // Update Stok Bahan
    int index = _bahanList.indexWhere((b) => b.nama.toLowerCase() == nama.toLowerCase());
    if (index != -1) {
      BahanBaku update = _bahanList[index];
      update.stok += jumlah;
      update.hargaBeliTerakhir = (totalHarga / jumlah).round();
      _bahanList[index] = update; 
      if (!kIsWeb) await _db.updateBahan(update);
    } else {
      int bahanId = kIsWeb ? DateTime.now().millisecondsSinceEpoch : 0;
      BahanBaku baruDraft = BahanBaku(id: null, nama: nama, satuan: satuan, stok: jumlah, hargaBeliTerakhir: (totalHarga / jumlah).round());
      if (!kIsWeb) {
        bahanId = await _db.insertBahan(baruDraft);
      }
      BahanBaku baru = BahanBaku(id: bahanId, nama: nama, satuan: satuan, stok: jumlah, hargaBeliTerakhir: (totalHarga / jumlah).round());
      _bahanList.add(baru);
    }

    // Masukkan transaksi yang SUDAH PUNYA ID ke list
    _transaksiList.insert(0, trxFinal);
    notifyListeners();
  }

  Future<void> hapusBahan(int id) async {
    _bahanList.removeWhere((b) => b.id == id);
    if (!kIsWeb) await _db.deleteBahan(id);
    notifyListeners();
  }

  // --- TRANSAKSI KASIR UPDATE ---
  Future<void> bayarTransaksi(Map<Produk, int> cart, String metode, int uangDiterima, String? buktiFoto) async {
    int totalUang = 0;
    List<String> detailItems = [];

    for (var entry in cart.entries) {
      Produk p = entry.key;
      int qty = entry.value;
      
      int index = _produkList.indexOf(p);
      if (index != -1) {
        _produkList[index].stok -= qty;
      }
      if (!kIsWeb) await _db.updateProduk(p);
      
      totalUang += (p.hargaJual * qty);
      detailItems.add("${p.nama} x$qty");
    }

    String deskripsi = detailItems.join(", ");

    // Siapkan Draft
    Transaksi trxDraft = Transaksi(
      tipe: 'MASUK', 
      deskripsi: deskripsi, 
      nominal: totalUang, 
      tanggal: DateTime.now().toString(),
      metodeBayar: metode,
      uangDiterima: uangDiterima,
      buktiFoto: buktiFoto
    );

    // INSERT & DAPATKAN ID (Solusi Bug Hapus)
    int trxId = kIsWeb ? DateTime.now().millisecondsSinceEpoch : 0;
    if (!kIsWeb) {
      trxId = await _db.insertTransaksi(trxDraft);
    }

    // Buat Final Object
    Transaksi trxFinal = Transaksi(
      id: trxId, // ID SUDAH TERISI!
      tipe: trxDraft.tipe,
      deskripsi: trxDraft.deskripsi,
      nominal: trxDraft.nominal,
      tanggal: trxDraft.tanggal,
      metodeBayar: trxDraft.metodeBayar,
      uangDiterima: trxDraft.uangDiterima,
      buktiFoto: trxDraft.buktiFoto
    );

    _transaksiList.insert(0, trxFinal);
    notifyListeners();
  }

  // --- EDIT & HAPUS TRANSAKSI ---
  Future<void> hapusTransaksi(int id) async {
    _transaksiList.removeWhere((t) => t.id == id);
    if (!kIsWeb) await _db.deleteTransaksi(id);
    notifyListeners();
  }

  Future<void> updateTransaksi(Transaksi t) async {
    int index = _transaksiList.indexWhere((item) => item.id == t.id);
    if (index != -1) {
      _transaksiList[index] = t;
      if (!kIsWeb) await _db.updateTransaksi(t);
      notifyListeners();
    }
  }
}