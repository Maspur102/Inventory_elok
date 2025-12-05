class Produk {
  String? id;
  String nama;
  String kategori;
  int stok;
  int hargaModal;
  int hargaJual;

  Produk({this.id, required this.nama, required this.kategori, required this.stok, required this.hargaModal, required this.hargaJual});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'stok': stok,
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
    };
  }

  factory Produk.fromMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id']?.toString(),
      nama: map['nama'] ?? '',
      kategori: map['kategori'] ?? '',
      stok: map['stok'] ?? 0,
      hargaModal: map['hargaModal'] ?? 0,
      hargaJual: map['hargaJual'] ?? 0,
    );
  }
}

class BahanBaku {
  String? id;
  String nama;
  String satuan;
  double stok;
  int hargaBeliTerakhir;

  BahanBaku({this.id, required this.nama, required this.satuan, required this.stok, required this.hargaBeliTerakhir});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'satuan': satuan,
      'stok': stok,
      'hargaBeliTerakhir': hargaBeliTerakhir,
    };
  }

  factory BahanBaku.fromMap(Map<String, dynamic> map) {
    return BahanBaku(
      id: map['id']?.toString(),
      nama: map['nama'] ?? '',
      satuan: map['satuan'] ?? 'unit',
      stok: (map['stok'] is int) ? (map['stok'] as int).toDouble() : map['stok'] ?? 0.0,
      hargaBeliTerakhir: map['hargaBeliTerakhir'] ?? 0,
    );
  }
}

class Transaksi {
  String? id;
  String tipe; // 'MASUK' (Penjualan) atau 'KELUAR' (Pembelian/Pengeluaran)
  String deskripsi; // Detail barang/catatan
  int nominal;
  String tanggal;
  String metodeBayar;
  int uangDiterima; // Khusus tunai
  String? buktiFoto; // Path foto

  Transaksi({
    this.id,
    required this.tipe,
    required this.deskripsi,
    required this.nominal,
    required this.tanggal,
    required this.metodeBayar,
    this.uangDiterima = 0,
    this.buktiFoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipe': tipe,
      'deskripsi': deskripsi,
      'nominal': nominal,
      'tanggal': tanggal,
      'metodeBayar': metodeBayar,
      'uangDiterima': uangDiterima,
      'buktiFoto': buktiFoto,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id']?.toString(),
      tipe: map['tipe'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      nominal: map['nominal'] ?? 0,
      tanggal: map['tanggal'] ?? DateTime.now().toIso8601String(),
      metodeBayar: map['metodeBayar'] ?? 'Tunai',
      uangDiterima: map['uangDiterima'] ?? 0,
      buktiFoto: map['buktiFoto'],
    );
  }
}