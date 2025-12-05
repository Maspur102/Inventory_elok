import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/app_provider.dart';
import 'models/models.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider()..loadData())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elok Alfa ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676), 
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final List<Widget> _screens = [
    const HalamanKasir(),
    const HalamanInventaris(), 
    const HalamanLaporan(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF00E676).withOpacity(0.2),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Kasir'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventaris'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Laporan'),
        ],
      ),
    );
  }
}

// --- TAB 1: KASIR ---
class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});
  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}
class _HalamanKasirState extends State<HalamanKasir> {
  Map<Produk, int> cart = {};
  String selectedCategory = "Semua";
  String searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    List<String> categories = ["Semua", ...provider.produkList.map((e) => e.kategori).toSet().toList()];
    
    List<Produk> filteredProduk = provider.produkList.where((p) {
      bool matchCategory = selectedCategory == "Semua" || p.kategori == selectedCategory;
      bool matchSearch = p.nama.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();

    int totalBelanja = 0;
    cart.forEach((k, v) => totalBelanja += (k.hargaJual * v));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("KASIR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF00E676))),
                      const Spacer(),
                      if (cart.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                          label: const Text("Reset", style: TextStyle(color: Colors.redAccent)),
                          onPressed: () => setState(() => cart.clear()),
                        )
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Cari Produk...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => searchQuery = ""); }) : null,
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (bool selected) { setState(() => selectedCategory = cat); },
                    backgroundColor: const Color(0xFF2C2C2C),
                    selectedColor: const Color(0xFF00E676).withOpacity(0.5),
                    checkmarkColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                )).toList(),
              ),
            ),
            Expanded(
              child: filteredProduk.isEmpty 
                ? const Center(child: Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.70, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: filteredProduk.length,
                  itemBuilder: (ctx, i) {
                    final p = filteredProduk[i];
                    int qtyInCart = cart[p] ?? 0;
                    return Card(
                      color: const Color(0xFF252525),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(6)),
                                  child: Text(p.kategori, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                                ),
                                Text("Stok: ${p.stok}", style: TextStyle(fontSize: 10, color: p.stok < 5 ? Colors.red : Colors.grey)),
                              ],
                            ),
                            const Spacer(),
                            Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(currency.format(p.hargaJual), style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            qtyInCart == 0 
                            ? SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2C), foregroundColor: const Color(0xFF00E676), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  onPressed: p.stok > 0 ? () { setState(() => cart[p] = 1); } : null,
                                  child: Text(p.stok > 0 ? "TAMBAH" : "HABIS"),
                                ),
                              )
                            : Container(
                                height: 36,
                                decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(icon: const Icon(Icons.remove, size: 16, color: Colors.black), onPressed: () { setState(() { if (cart[p]! > 1) { cart[p] = cart[p]! - 1; } else { cart.remove(p); } }); }),
                                    Text("$qtyInCart", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    IconButton(icon: const Icon(Icons.add, size: 16, color: Colors.black), onPressed: p.stok > qtyInCart ? () { setState(() => cart[p] = cart[p]! + 1); } : null),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
            if (totalBelanja > 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -5))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${cart.length} Item dipilih", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(currency.format(totalBelanja), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.payment),
                      label: const Text("BAYAR", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showDialogBayar(context, provider, totalBelanja),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  void _showDialogBayar(BuildContext context, AppProvider provider, int totalTagihan) {
    String metode = "Tunai";
    TextEditingController uangCtrl = TextEditingController();
    XFile? pickedImage;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          int kembalian = 0;
          int uangMasuk = int.tryParse(uangCtrl.text) ?? 0;
          if (uangMasuk >= totalTagihan) kembalian = uangMasuk - totalTagihan;

          return AlertDialog(
            title: const Text("Pembayaran"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Total: Rp ${NumberFormat('#,###').format(totalTagihan)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: metode,
                    dropdownColor: const Color(0xFF2C2C2C),
                    decoration: const InputDecoration(labelText: "Metode Pembayaran", border: OutlineInputBorder()),
                    items: ["Tunai", "Transfer"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setModalState(() => metode = val!),
                  ),
                  const SizedBox(height: 10),
                  if (metode == "Tunai") ...[
                    TextField(
                      controller: uangCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Uang Diterima (Rp)", border: OutlineInputBorder()),
                      onChanged: (val) => setModalState((){}),
                    ),
                    const SizedBox(height: 10),
                    Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.grey[900], child: Text("Kembalian: Rp ${NumberFormat('#,###').format(kembalian)}", style: TextStyle(color: kembalian >= 0 ? const Color(0xFF00E676) : Colors.red, fontWeight: FontWeight.bold)))
                  ] else ...[
                     const SizedBox(height: 10),
                     GestureDetector(
                       onTap: () async {
                         final ImagePicker picker = ImagePicker();
                         final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                         if(image != null) setModalState(() => pickedImage = image);
                       },
                       child: Container(
                         height: 150,
                         width: double.infinity,
                         decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10), color: Colors.grey[900]),
                         child: pickedImage == null 
                           ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file, size: 40), Text("Tap untuk Upload Bukti")])
                           : kIsWeb 
                              ? Image.network(pickedImage!.path, fit: BoxFit.cover) 
                              : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                       ),
                     ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                onPressed: () async { // UBAH KE ASYNC
                  int uangFinal = metode == "Tunai" ? (int.tryParse(uangCtrl.text) ?? 0) : totalTagihan;
                  if (metode == "Tunai" && uangFinal < totalTagihan) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uang kurang!"), backgroundColor: Colors.red));
                    return;
                  }
                  if (metode == "Transfer" && pickedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap upload bukti transfer!"), backgroundColor: Colors.red));
                    return;
                  }
                  
                  // PERBAIKAN UTAMA: Gunakan Map.from(cart) agar data tidak hilang saat cart.clear()
                  // Dan gunakan await agar selesai proses dulu
                  await provider.bayarTransaksi(Map.from(cart), metode, uangFinal, pickedImage?.path);
                  
                  if (context.mounted) {
                    setState(() => cart.clear());
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pembayaran Berhasil!")));
                  }
                },
                child: const Text("PROSES BAYAR"),
              )
            ],
          );
        }
      ),
    );
  }
}

// --- TAB 2: INVENTARIS ---
class HalamanInventaris extends StatelessWidget {
  const HalamanInventaris({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("MANAJEMEN GUDANG"),
          bottom: const TabBar(indicatorColor: Color(0xFF00E676), labelColor: Color(0xFF00E676), unselectedLabelColor: Colors.grey, tabs: [Tab(text: "Produk Jadi"), Tab(text: "Bahan Baku")]),
        ),
        body: const TabBarView(children: [ListProdukView(), ListBahanView()]),
      ),
    );
  }
}

class ListProdukView extends StatelessWidget {
  const ListProdukView({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormProduk(context, null, provider),
        label: const Text("Produk Baru"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.produkList.length,
        itemBuilder: (ctx, i) {
          final p = provider.produkList[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
                  child: Center(child: Text(p.kategori.isNotEmpty ? p.kategori.substring(0,1) : "?", style: const TextStyle(fontSize: 30, color: Color(0xFF00E676), fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: p.stok > 5 ? const Color(0xFF00E676).withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(p.stok > 5 ? "Aman" : "Tipis", style: TextStyle(color: p.stok > 5 ? const Color(0xFF00E676) : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)))]),
                        const SizedBox(height: 5),
                        Text("${currency.format(p.hargaModal)} -> ${currency.format(p.hargaJual)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 10),
                        Row(children: [const Icon(Icons.inventory_2, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("Stok: ${p.stok}", style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent), onPressed: () => _showFormProduk(context, p, provider)), IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => _confirmDelete(context, () => provider.hapusProduk(p.id ?? 0)))])
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFormProduk(BuildContext context, Produk? produk, AppProvider provider) {
    final isEdit = produk != null;
    final namaCtrl = TextEditingController(text: isEdit ? produk.nama : '');
    final kategoriCtrl = TextEditingController(text: isEdit ? produk.kategori : '');
    final stokCtrl = TextEditingController(text: isEdit ? produk.stok.toString() : '');
    final modalCtrl = TextEditingController(text: isEdit ? produk.hargaModal.toString() : '');
    final jualCtrl = TextEditingController(text: isEdit ? produk.hargaJual.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? "Edit Produk" : "Tambah Produk Baru", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
            const SizedBox(height: 20),
            TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Produk")),
            const SizedBox(height: 10),
            TextField(controller: kategoriCtrl, decoration: const InputDecoration(labelText: "Kategori")),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: TextField(controller: stokCtrl, decoration: const InputDecoration(labelText: "Stok"), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: modalCtrl, decoration: const InputDecoration(labelText: "Modal"), keyboardType: TextInputType.number))]),
            const SizedBox(height: 10),
            TextField(controller: jualCtrl, decoration: const InputDecoration(labelText: "Harga Jual"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black), child: const Text("SIMPAN"), onPressed: () { if (namaCtrl.text.isNotEmpty && jualCtrl.text.isNotEmpty) { Produk p = Produk(id: isEdit ? produk.id : null, nama: namaCtrl.text, kategori: kategoriCtrl.text.isEmpty ? "Umum" : kategoriCtrl.text, stok: int.tryParse(stokCtrl.text) ?? 0, hargaModal: int.tryParse(modalCtrl.text) ?? 0, hargaJual: int.tryParse(jualCtrl.text) ?? 0); provider.simpanProduk(p, isEdit); Navigator.pop(ctx); } })),
            const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class ListBahanView extends StatelessWidget {
  const ListBahanView({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _dialogBelanja(context, provider), label: const Text("Belanja Bahan"), icon: const Icon(Icons.shopping_cart), backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: provider.bahanList.length,
        itemBuilder: (ctx, i) {
          final b = provider.bahanList[i];
          return ListTile(leading: const Icon(Icons.layers_outlined), title: Text(b.nama), subtitle: Text("Beli terakhir: ${currency.format(b.hargaBeliTerakhir)} / ${b.satuan}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("${b.stok} ${b.satuan}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => _confirmDelete(context, () => provider.hapusBahan(b.id ?? 0)))]));
        },
      ),
    );
  }
  void _dialogBelanja(BuildContext context, AppProvider provider) {
    TextEditingController namaCtrl = TextEditingController();
    TextEditingController satuanCtrl = TextEditingController(text: "kg");
    TextEditingController jumlahCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Catat Belanja Bahan"), content: SingleChildScrollView(child: Column(children: [TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Bahan")), TextField(controller: satuanCtrl, decoration: const InputDecoration(labelText: "Satuan")), TextField(controller: jumlahCtrl, decoration: const InputDecoration(labelText: "Jumlah Beli"), keyboardType: TextInputType.number), TextField(controller: hargaCtrl, decoration: const InputDecoration(labelText: "Total Biaya (Rp)"), keyboardType: TextInputType.number)])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")), ElevatedButton(onPressed: () { if(namaCtrl.text.isNotEmpty && hargaCtrl.text.isNotEmpty) { provider.belanjaBahan(namaCtrl.text, satuanCtrl.text, int.parse(jumlahCtrl.text), int.parse(hargaCtrl.text)); Navigator.pop(ctx); } }, child: const Text("SIMPAN"))]));
  }
}

// --- TAB 3: LAPORAN (UPDATE: STUK ADA, EDIT/HAPUS ADA) ---
class HalamanLaporan extends StatelessWidget {
  const HalamanLaporan({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("LAPORAN KEUANGAN")),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00BFA5)]), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,5))]),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_summaryItem("PEMASUKAN", provider.totalPemasukan, Colors.black), Container(width: 1, height: 40, color: Colors.black26), _summaryItem("PENGELUARAN", provider.totalPengeluaran, Colors.black87)]),
                const Divider(color: Colors.black26, height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("SALDO BERSIH: ", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)), Text(currency.format(provider.saldoBersih), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))])
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: provider.transaksiList.length,
              itemBuilder: (ctx, i) {
                final t = provider.transaksiList[i];
                bool isMasuk = t.tipe == 'MASUK';
                return ExpansionTile(
                  leading: CircleAvatar(backgroundColor: isMasuk ? const Color(0xFF00E676).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2), child: Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: isMasuk ? const Color(0xFF00E676) : Colors.redAccent)),
                  title: Text(t.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("${t.metodeBayar} • ${t.tanggal.substring(0, 16)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text("${isMasuk ? '+' : '-'} ${currency.format(t.nominal)}", style: TextStyle(color: isMasuk ? const Color(0xFF00E676) : Colors.redAccent, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          // Tombol Struk
                          ElevatedButton.icon(
                            icon: const Icon(Icons.receipt),
                            label: const Text("Struk"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                            onPressed: () => _showDetailTransaksi(context, t),
                          ),
                          // Tombol Lihat Bukti Foto
                          if (t.buktiFoto != null && t.buktiFoto!.isNotEmpty)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.image),
                              label: const Text("Bukti"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                              onPressed: () => _showImageDialog(context, t.buktiFoto!),
                            ),
                          // Tombol Edit
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () => _showEditDialog(context, t, provider),
                          ),
                          // Tombol Hapus
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text("Hapus"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => _confirmDelete(context, () => provider.hapusTransaksi(t.id!)),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showDetailTransaksi(BuildContext context, Transaksi t) {
    // Dialog Cetak Struk
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Center(child: Text("STRUK TRANSAKSI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text("ELOK ALFA CHIPS", style: GoogleFonts.courierPrime(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))),
              const Divider(color: Colors.black),
              Text("Tgl: ${t.tanggal.substring(0,16)}", style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
              Text("Metode: ${t.metodeBayar}", style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
              
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text("--------------------------------", style: GoogleFonts.courierPrime(color: Colors.black), maxLines: 1, overflow: TextOverflow.clip)),
              ...t.deskripsi.split(", ").map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(item, style: GoogleFonts.courierPrime(fontSize: 14, color: Colors.black)))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text("--------------------------------", style: GoogleFonts.courierPrime(color: Colors.black), maxLines: 1, overflow: TextOverflow.clip)),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TOTAL", style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, color: Colors.black)), Text(currency.format(t.nominal), style: GoogleFonts.courierPrime(fontWeight: FontWeight.bold, color: Colors.black))]),
              if(t.metodeBayar == "Tunai") ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TUNAI", style: GoogleFonts.courierPrime(color: Colors.black)), Text(currency.format(t.uangDiterima), style: GoogleFonts.courierPrime(color: Colors.black))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("KEMBALI", style: GoogleFonts.courierPrime(color: Colors.black)), Text(currency.format(t.uangDiterima - t.nominal), style: GoogleFonts.courierPrime(color: Colors.black))]),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup")),
          ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), icon: const Icon(Icons.print), label: const Text("Cetak"), onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sedang Mencetak... (Simulasi)"))); })
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String path) {
    showDialog(context: context, builder: (ctx) => Dialog(child: kIsWeb ? Image.network(path) : Image.file(File(path))));
  }

  void _showEditDialog(BuildContext context, Transaksi t, AppProvider provider) {
    final descCtrl = TextEditingController(text: t.deskripsi);
    final nomCtrl = TextEditingController(text: t.nominal.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Edit Transaksi"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Deskripsi")), TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: "Nominal"), keyboardType: TextInputType.number)]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")), ElevatedButton(onPressed: () { Transaksi updated = Transaksi(id: t.id, tipe: t.tipe, deskripsi: descCtrl.text, nominal: int.tryParse(nomCtrl.text) ?? 0, tanggal: t.tanggal, metodeBayar: t.metodeBayar, uangDiterima: t.uangDiterima, buktiFoto: t.buktiFoto); provider.updateTransaksi(updated); Navigator.pop(ctx); }, child: const Text("SIMPAN"))]));
  }

  Widget _summaryItem(String label, int value, Color color) {
    final currency = NumberFormat.compact(locale: 'id_ID').format(value);
    return Column(children: [Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.6))), const SizedBox(height: 5), Text("Rp $currency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]);
  }
}

void _confirmDelete(BuildContext context, Function onConfirm) {
  showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Hapus Data?"), content: const Text("Data yang dihapus tidak bisa dikembalikan."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")), TextButton(onPressed: () { onConfirm(); Navigator.pop(ctx); }, child: const Text("HAPUS", style: TextStyle(color: Colors.red)))]));
}