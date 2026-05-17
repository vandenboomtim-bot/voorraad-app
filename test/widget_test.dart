import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypttjslpvbyufhvhquuc.supabase.co',
    anonKey: 'JOUW_SUPABASE_ANON_KEY_HIER',
  );

  runApp(const VoorraadApp()); // 🔥 BELANGRIJK: GEEN MyApp
}

// ================= APP =================

class VoorraadApp extends StatelessWidget {
  const VoorraadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const VoorraadHome(),
    );
  }
}

// ================= MODEL =================

class Item {
  final String id;
  final String name;
  final int count;

  Item({
    required this.id,
    required this.name,
    required this.count,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      count: int.tryParse(map['count'].toString()) ?? 0,
    );
  }
}

// ================= HOME =================

class VoorraadHome extends StatefulWidget {
  const VoorraadHome({super.key});

  @override
  State<VoorraadHome> createState() => _VoorraadHomeState();
}

class _VoorraadHomeState extends State<VoorraadHome> {
  final supabase = Supabase.instance.client;

  final itemController = TextEditingController();

  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  // ================= LOAD =================

  Future<void> loadItems() async {
    try {
      final data = await supabase.from('items').select().order('name');

      debugPrint("LOAD RAW: $data");

      final list = List<Map<String, dynamic>>.from(data);

      setState(() {
        items = list.map(Item.fromMap).toList();
      });
    } catch (e) {
      debugPrint("LOAD ERROR: $e");
    }
  }

  // ================= ADD (PLUS KNOP) =================

  Future<void> addItem() async {
    final name = itemController.text.trim();

    debugPrint("ADD CLICKED: $name");

    if (name.isEmpty) {
      debugPrint("NAME EMPTY");
      return;
    }

    try {
      final response = await supabase.from('items').insert({
        'name': name,
        'count': 0,
      }).select();

      debugPrint("INSERT RESPONSE: $response");

      itemController.clear();

      await loadItems();
    } catch (e) {
      debugPrint("ADD ERROR: $e");
    }
  }

  // ================= UPDATE =================

  Future<void> updateCount(String id, int newCount) async {
    if (newCount < 0) return;

    try {
      await supabase.from('items').update({
        'count': newCount,
      }).eq('id', id);

      setState(() {
        final index = items.indexWhere((i) => i.id == id);
        if (index != -1) {
          items[index] = Item(
            id: items[index].id,
            name: items[index].name,
            count: newCount,
          );
        }
      });
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
    }
  }

  // ================= DELETE =================

  Future<void> deleteItem(String id) async {
    try {
      await supabase.from('items').delete().eq('id', id);

      setState(() {
        items.removeWhere((i) => i.id == id);
      });
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voorraad")),
      body: Column(
        children: [
          _input(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (c, i) => _card(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: itemController,
              decoration: const InputDecoration(
                hintText: "Nieuw product",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              debugPrint("PLUS BUTTON CLICKED");
              addItem();
            },
          ),
        ],
      );

  Widget _card(Item item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text("Aantal: ${item.count}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => updateCount(item.id, item.count - 1),
          ),
          Text("${item.count}"),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => updateCount(item.id, item.count + 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteItem(item.id),
          ),
        ],
      ),
    );
  }
}