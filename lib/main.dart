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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const VoorraadHome(),
    );
  }
}

class _Item {
  final String id;
  final String name;
  final int count;
  final String category;

  const _Item({
    required this.id,
    required this.name,
    required this.count,
    required this.category,
  });

  factory _Item.fromMap(Map<String, dynamic> map) {
    return _Item(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      count: (map['count'] ?? 0) as int,
      category: (map['category'] ?? 'overig').toString(),
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

  final controller = TextEditingController();
  final searchController = TextEditingController();

  final List<_Item> _items = [];
  RealtimeChannel? channel;

  String selectedFilter = 'alle';

  @override
  void initState() {
    super.initState();
    _load();
    _listen();
  }

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    channel?.unsubscribe();
    super.dispose();
  }

  // ---------------- DATA ----------------

  Future<void> _load() async {
    final data = await supabase.from('items').select().order('name');

    if (!mounted) return;

    setState(() {
      _items
        ..clear()
        ..addAll((data as List).map((e) => _Item.fromMap(e)));
    });
  }

  void _listen() {
    channel = supabase
        .channel('items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  // ---------------- ACTIONS ----------------

  Future<void> add() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    controller.clear();

    await supabase.from('items').insert({
      'name': name,
      'count': 0,
      'category': selectedFilter == 'alle' ? 'overig' : selectedFilter,
    });
  }

  Future<void> update(String id, int count) async {
    if (count < 0) return;

    await supabase.from('items').update({
      'count': count,
    }).eq('id', id);
  }

  Future<void> remove(String id) async {
    await supabase.from('items').delete().eq('id', id);
  }

  // ---------------- FILTER ----------------

  List<_Item> get filtered {
    final q = searchController.text.toLowerCase();

    final list = _items.where((i) {
      final matchCat =
          selectedFilter == 'alle' || i.category == selectedFilter;

      final matchSearch = i.name.toLowerCase().contains(q);

      return matchCat && matchSearch;
    }).toList();

    list.sort((a, b) => a.count.compareTo(b.count));

    return list;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "🧺 Voorraad PRO",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          _search(),
          _categories(),
          _input(),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Geen items"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final low = item.count <= 1;

                      return _animatedCard(item, low);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- ANIMATED CARD ----------------

  Widget _animatedCard(_Item item, bool low) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => remove(item.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: low ? Colors.red : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${item.count}",
                      style: TextStyle(
                        color: low ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => update(item.id, item.count - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => update(item.id, item.count + 1),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- OTHER UI ----------------

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: "Zoek...",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _categories() {
    Widget chip(String c) {
      final selected = selectedFilter == c;

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(c),
          selected: selected,
          onSelected: (_) => setState(() => selectedFilter = c),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          chip('alle'),
          chip('overig'),
          chip('eten'),
          chip('drinken'),
          chip('schoonmaak'),
        ],
      ),
    );
  }

  Widget _input() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Nieuw product...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: add,
          )
        ],
      ),
    );
  }
}