class BahanBaku {
  final int? id;
  String nama;
  String satuan; 
  int stok;
  int hargaBeliTerakhir;

  BahanBaku({this.id, required this.nama, required this.satuan, required this.stok, required this.hargaBeliTerakhir});

  Map<String, dynamic> toMap() => {'id': id, 'nama': nama, 'satuan': satuan, 'stok': stok, 'harga_beli': hargaBeliTerakhir};
  
  factory BahanBaku.fromMap(Map<String, dynamic> map) {
    return BahanBaku(id: map['id'], nama: map['nama'], satuan: map['satuan'], stok: map['stok'], hargaBeliTerakhir: map['harga_beli']);
  }
}

class Produk {
  final int? id;
  String nama;
  String kategori;
  int hargaModal;
  int hargaJual;
  int stok;

  Produk({
    this.id, 
    required this.nama, 
    required this.kategori,
    required this.hargaModal,
    required this.hargaJual, 
    required this.stok
  });

  Map<String, dynamic> toMap() => {
    'id': id, 
    'nama': nama, 
    'kategori': kategori,
    'harga_modal': hargaModal,
    'harga_jual': hargaJual, 
    'stok': stok
  };

  factory Produk.fromMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id'], 
      nama: map['nama'], 
      kategori: map['kategori'],
      hargaModal: map['harga_modal'] ?? 0,
      hargaJual: map['harga_jual'], 
      stok: map['stok']
    );
  }
}

class Transaksi {
  final int? id;
  String tipe; 
  String deskripsi;
  int nominal;
  String tanggal;
  String metodeBayar;
  int uangDiterima;
  String? buktiFoto; // Path gambar bukti transfer

  Transaksi({
    this.id, 
    required this.tipe, 
    required this.deskripsi, 
    required this.nominal, 
    required this.tanggal,
    required this.metodeBayar,
    required this.uangDiterima,
    this.buktiFoto,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 
    'tipe': tipe, 
    'deskripsi': deskripsi, 
    'nominal': nominal, 
    'tanggal': tanggal,
    'metode_bayar': metodeBayar,
    'uang_diterima': uangDiterima,
    'bukti_foto': buktiFoto
  };

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'], 
      tipe: map['tipe'], 
      deskripsi: map['deskripsi'], 
      nominal: map['nominal'], 
      tanggal: map['tanggal'],
      metodeBayar: map['metode_bayar'] ?? '-',
      uangDiterima: map['uang_diterima'] ?? 0,
      buktiFoto: map['bukti_foto']
    );
  }
}