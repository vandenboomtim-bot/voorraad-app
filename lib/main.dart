import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypttjslpvbyufhvhquuc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwdHRqc2xwdmJ5dWZodmhxdXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NDc2NTUsImV4cCI6MjA5NDUyMzY1NX0.xLGfSDmNEvu6SGDysk6V24-yzHDRzPfM99KN-CTmCA4',
  );

  runApp(const VoorraadApp());
}

class VoorraadApp extends StatelessWidget {
  const VoorraadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class Item {
  final int id;
  final String name;
  final int count;

  Item({
    required this.id,
    required this.name,
    required this.count,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      count: map['count'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  final controller = TextEditingController();

  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final data = await supabase
        .from('items')
        .select()
        .order('id');

    setState(() {
      items = (data as List)
          .map((e) => Item.fromMap(e))
          .toList();
    });
  }

  Future<void> addItem() async {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    await supabase.from('items').insert({
      'name': text,
      'count': 0,
    });

    controller.clear();

    await loadItems();
  }

  Future<void> plus(Item item) async {
    await supabase
        .from('items')
        .update({
          'count': item.count + 1,
        })
        .eq('id', item.id);

    await loadItems();
  }

  Future<void> minus(Item item) async {
    if (item.count <= 0) return;

    await supabase
        .from('items')
        .update({
          'count': item.count - 1,
        })
        .eq('id', item.id);

    await loadItems();
  }

  Future<void> remove(Item item) async {
    await supabase
        .from('items')
        .delete()
        .eq('id', item.id);

    await loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voorraad'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Nieuw product',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addItem,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    'Aantal: ${item.count}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => minus(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => plus(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => remove(item),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}