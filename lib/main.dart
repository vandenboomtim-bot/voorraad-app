import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypttjslpvbyufhvhquuc.supabase.co',
    anonKey: 'sb_publishable_1q8mBlpiTgHPiejDsLHBBw_XHddbHii',
  );

  runApp(const VoorraadApp());
}

class VoorraadApp extends StatelessWidget {
  const VoorraadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VoorraadHome(),
    );
  }
}

class VoorraadHome extends StatefulWidget {
  const VoorraadHome({super.key});

  @override
  State<VoorraadHome> createState() => _VoorraadHomeState();
}

class _VoorraadHomeState extends State<VoorraadHome> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> items = [];
  final TextEditingController controller = TextEditingController();

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    loadItems();
    subscribe();
  }

  @override
  void dispose() {
    controller.dispose();
    channel?.unsubscribe();
    super.dispose();
  }

  // ---------------- DATA ----------------

  Future<void> loadItems() async {
    final data = await supabase.from('items').select().order('name');

    if (!mounted) return;

    setState(() {
      items = List<Map<String, dynamic>>.from(data);
    });
  }

  void subscribe() {
    channel = supabase
        .channel('items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => loadItems(),
        )
        .subscribe();
  }

  // ---------------- ACTIONS ----------------

  Future<void> addItem(String name) async {
    await supabase.from('items').insert({
      'name': name,
      'count': 0,
      'category': 'overig',
    });
  }

  Future<void> updateCount(String id, int count) async {
    await supabase.from('items').update({
      'count': count,
    }).eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await supabase.from('items').delete().eq('id', id);
  }

  // ---------------- UI ----------------

  Color categoryColor(String category) {
    switch (category) {
      case 'eten':
        return Colors.orange;
      case 'drinken':
        return Colors.blue;
      case 'schoonmaak':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "🧺 Voorraad Pro",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Nieuw product...",
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;

                        addItem(controller.text.trim());
                        controller.clear();
                        Navigator.pop(context);
                        loadItems();
                      },
                      child: const Text("Toevoegen"),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),

      body: items.isEmpty
          ? const Center(child: Text("Geen items"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                final id = item['id'].toString();
                final name = item['name'] ?? '';
                final count = (item['count'] ?? 0) as int;
                final category = item['category'] ?? 'overig';

                final lowStock = count <= 1;
                final color = categoryColor(category);

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => deleteItem(id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: lowStock
                            ? Colors.red.shade100
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lowStock
                                        ? Colors.red
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "$count",
                                    style: TextStyle(
                                      color: lowStock
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  updateCount(id, count - 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  updateCount(id, count + 1),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}