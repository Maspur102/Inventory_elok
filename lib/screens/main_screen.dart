import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
      title: 'Elok Alfa System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101010),
        primaryColor: const Color(0xFF00FF88), // Neon Green
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          secondary: Color(0xFF00CC6A),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.jetbrainsMonoTextTheme(ThemeData.dark().textTheme), // Font Hacker
        useMaterial3: true,
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
    const HalamanBahanBaku(),
    const HalamanKeuangan(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF00FF88).withOpacity(0.2),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'KASIR'),
          NavigationDestination(icon: Icon(Icons.inventory), label: 'BAHAN BAKU'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'KEUANGAN'),
        ],
      ),
    );
  }
}

// --- TAB 1: KASIR (POS) ---
class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});
  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}
class _HalamanKasirState extends State<HalamanKasir> {
  Map<Produk, int> cart = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    int totalBelanja = 0;
    cart.forEach((k, v) => totalBelanja += (k.hargaJual * v));

    return Scaffold(
      appBar: AppBar(title: const Text("KASIR ELOK ALFA"), actions: [
        IconButton(icon: const Icon(Icons.add_box), onPressed: () => _dialogTambahProduk(context, provider))
      ]),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: provider.produkList.length,
              itemBuilder: (ctx, i) {
                final p = provider.produkList[i];
                int qtyInCart = cart[p] ?? 0;
                return Card(
                  color: const Color(0xFF252525),
                  shape: RoundedRectangleBorder(side: BorderSide(color: p.stok < 5 ? Colors.red : Colors.transparent), borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () {
                      if (p.stok > qtyInCart) {
                        setState(() => cart[p] = qtyInCart + 1);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                          const SizedBox(height: 5),
                          Text(currency.format(p.hargaJual), style: const TextStyle(color: Color(0xFF00FF88))),
                          const SizedBox(height: 5),
                          Text("Stok: ${p.stok}", style: TextStyle(color: p.stok < 5 ? Colors.red : Colors.grey)),
                          if (qtyInCart > 0) 
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF00FF88), borderRadius: BorderRadius.circular(5)),
                              child: Text("$qtyInCart x", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (totalBelanja > 0)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                border: Border(top: BorderSide(color: Color(0xFF00FF88), width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: ${currency.format(totalBelanja)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black),
                    icon: const Icon(Icons.check),
                    label: const Text("BAYAR"),
                    onPressed: () {
                      provider.bayarTransaksi(cart);
                      setState(() => cart.clear());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi Berhasil!")));
                    },
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  void _dialogTambahProduk(BuildContext context, AppProvider provider) {
    // Dialog simple untuk menambah jenis produk baru / hasil produksi
    TextEditingController namaCtrl = TextEditingController();
    TextEditingController stokCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Input Hasil Produksi"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Produk (ex: Kripik Taro)")),
          TextField(controller: stokCtrl, decoration: const InputDecoration(labelText: "Jumlah Jadi (pcs)"), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            if(namaCtrl.text.isNotEmpty && stokCtrl.text.isNotEmpty) {
              provider.produksiBarang(namaCtrl.text, int.parse(stokCtrl.text), 5000); // Default 5000
              Navigator.pop(ctx);
            }
          },
          child: const Text("Simpan"),
        )
      ],
    ));
  }
}

// --- TAB 2: BAHAN BAKU (INVENTORY) ---
class HalamanBahanBaku extends StatelessWidget {
  const HalamanBahanBaku({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("GUDANG BAHAN"), actions: [
        IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => _dialogBelanja(context, provider))
      ]),
      body: ListView.builder(
        itemCount: provider.bahanList.length,
        itemBuilder: (ctx, i) {
          final b = provider.bahanList[i];
          return ListTile(
            leading: const Icon(Icons.layers, color: Colors.amber),
            title: Text(b.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Beli Terakhir: ${currency.format(b.hargaBeliTerakhir)} / ${b.satuan}"),
            trailing: Text("${b.stok} ${b.satuan}", style: const TextStyle(fontSize: 18, color: Color(0xFF00FF88))),
          );
        },
      ),
    );
  }

  void _dialogBelanja(BuildContext context, AppProvider provider) {
    TextEditingController namaCtrl = TextEditingController();
    TextEditingController satuanCtrl = TextEditingController(text: "kg");
    TextEditingController jumlahCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Belanja Bahan Baku"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Bahan")),
            TextField(controller: satuanCtrl, decoration: const InputDecoration(labelText: "Satuan (kg/liter)")),
            TextField(controller: jumlahCtrl, decoration: const InputDecoration(labelText: "Jumlah Beli"), keyboardType: TextInputType.number),
            TextField(controller: hargaCtrl, decoration: const InputDecoration(labelText: "Total Rupiah"), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          onPressed: () {
            if(namaCtrl.text.isNotEmpty && hargaCtrl.text.isNotEmpty) {
              provider.belanjaBahan(namaCtrl.text, satuanCtrl.text, int.parse(jumlahCtrl.text), int.parse(hargaCtrl.text));
              Navigator.pop(ctx);
            }
          },
          child: const Text("BELI (UANG KELUAR)"),
        )
      ],
    ));
  }
}

// --- TAB 3: KEUANGAN (REPORT) ---
class HalamanKeuangan extends StatelessWidget {
  const HalamanKeuangan({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("ARUS KAS")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF252525),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoBox("Pemasukan", currency.format(provider.totalPemasukan), const Color(0xFF00FF88)),
                _infoBox("Pengeluaran", currency.format(provider.totalPengeluaran), Colors.redAccent),
                _infoBox("Saldo", currency.format(provider.saldoBersih), Colors.white),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: provider.transaksiList.length,
              itemBuilder: (ctx, i) {
                final t = provider.transaksiList[i];
                bool isMasuk = t.tipe == 'MASUK';
                return ListTile(
                  leading: Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: isMasuk ? const Color(0xFF00FF88) : Colors.red),
                  title: Text(t.deskripsi, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(t.tanggal.substring(0, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  trailing: Text(
                    currency.format(t.nominal),
                    style: TextStyle(color: isMasuk ? const Color(0xFF00FF88) : Colors.red, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _infoBox(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}