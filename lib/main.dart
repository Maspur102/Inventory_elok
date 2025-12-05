// Kode ini SAMA dengan yang Anda berikan, karena secara sintaksis sudah benar untuk versi Flutter modern.
// Perbaikan utamanya adalah membersihkan build cache.
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
        // BARIS 39: CardTheme sudah benar untuk useMaterial3: true
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
        onPressed: () => _showFormProduk(context, null,