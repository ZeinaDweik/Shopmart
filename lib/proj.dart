import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Small 1x1 transparent PNG (so we can use FadeInImage without adding assets/packages)
final Uint8List _transparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

String _formatPrice(num price) => '${price.toStringAsFixed(2)} JD';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopMart ',
      theme: ThemeData(
        primaryColor: Color(0xFF04143C),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF37B6FF),
        ),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF04143C),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF37B6FF),
          unselectedItemColor: Color(0xFF04143C),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF04143C)),
          bodyMedium: TextStyle(color: Color(0xFF04143C)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(),
        '/settingsScreen': (context) => SettingsScreen(onClearCart: () {}),
        '/contactScreen': (context) => ContactScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// Sort options (kept as String to match your style)
class _SortOptions {
  static const String recommended = 'Recommended';
  static const String priceLowToHigh = 'Price: Low → High';
  static const String priceHighToLow = 'Price: High → Low';
  static const String titleAZ = 'Title: A → Z';

  static const List<String> all = [
    recommended,
    priceLowToHigh,
    priceHighToLow,
    titleAZ,
  ];
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  String userName = "Guest";
  String userEmail = "guest@example.com";

  /// Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _userDocId() {
    final email = userEmail.trim().toLowerCase();
    return email.isEmpty ? 'guest@example.com' : email;
  }

  String _itemDocId(Map<String, dynamic> item) {
    // you already assign item["id"] in _loadItems()
    return (item['id'] ?? item['title']).toString();
  }

  Future<void> _saveFavoriteToFirestore(Map<String, dynamic> item) async {
    final userId = _userDocId();
    final itemId = _itemDocId(item);

    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(itemId);

    if (item['isFavorite'] == true) {
      await ref.set({
        'title': item['title'],
        'price': item['price'],
        'image': item['image'],
        'category': item['category'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.delete();
    }
  }

  Future<void> _saveCartItemToFirestore(Map<String, dynamic> item) async {
    final userId = _userDocId();
    final itemId = _itemDocId(item);

    final ref =
    _db.collection('users').doc(userId).collection('cart').doc(itemId);

    final count = item['count'] as int;

    if (count > 0) {
      await ref.set({
        'title': item['title'],
        'price': item['price'],
        'image': item['image'],
        'category': item['category'],
        'count': count,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.delete();
    }
  }

  Future<void> _clearCartInFirestore() async {
    final userId = _userDocId();
    final snap = await _db.collection('users').doc(userId).collection('cart').get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// Data
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _basket = [];

  /// Home controls
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortOption = _SortOptions.recommended;

  /// Async load (FutureBuilder requirement)
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    // Simulate loading from an API/DB (FutureBuilder demonstration)
    await Future.delayed(Duration(milliseconds: 650));

    final List<Map<String, dynamic>> items = [
      {
        "title": "Jacket",
        "isFavorite": false,
        "count": 0,
        "price": 45.00,
        "category": "Clothing",
        "image":
        "https://images.unsplash.com/photo-1624548140129-74786c5f1279?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "images": [
          "https://images.unsplash.com/photo-1624548140129-74786c5f1279?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
          "https://images.unsplash.com/photo-1520975916090-3105956dac38?q=80&w=774&auto=format&fit=crop",
        ],
      },
      {
        "title": "Sneakers",
        "isFavorite": false,
        "count": 0,
        "price": 30.00,
        "category": "Shoes",
        "image":
        "https://images.unsplash.com/photo-1634624943296-54ce51cf732c?q=80&w=1031&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "images": [
          "https://images.unsplash.com/photo-1634624943296-54ce51cf732c?q=80&w=1031&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
          "https://images.unsplash.com/photo-1528701800489-20be9c1f1d56?q=80&w=774&auto=format&fit=crop",
        ],
      },
      {
        "title": "T-Shirt",
        "isFavorite": false,
        "count": 0,
        "price": 10.00,
        "category": "Clothing",
        "image":
        "https://images.unsplash.com/photo-1716369786765-5de0bb2d2658?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "images": [
          "https://images.unsplash.com/photo-1716369786765-5de0bb2d2658?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
          "https://images.unsplash.com/photo-1520975869018-9d0f4f7d1b07?q=80&w=774&auto=format&fit=crop",
        ],
      },
      {
        "title": "Bag",
        "isFavorite": false,
        "count": 0,
        "price": 15.00,
        "category": "Accessories",
        "image":
        "https://images.unsplash.com/photo-1600857062241-98e5dba7f214?q=80&w=798&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "images": [
          "https://images.unsplash.com/photo-1600857062241-98e5dba7f214?q=80&w=798&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
          "https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?q=80&w=774&auto=format&fit=crop",
        ],
      },
    ];

    // Keep your "subtitle" field but make it consistent with price (fix)
    for (int i = 0; i < items.length; i++) {
      items[i]["subtitle"] = _formatPrice(items[i]["price"]);
      items[i]["id"] = i; // stable id for timers/keys
      items[i]["heroTag"] = '${items[i]["title"]}_$i';
    }

    return items;
  }

  int _basketItemsCount() {
    int total = 0;
    for (final item in _basket) {
      total += (item['count'] as int);
    }
    return total;
  }

  List<String> _categories() {
    final set = <String>{'All'};
    for (final item in _items) {
      set.add(item['category'] ?? 'Other');
    }
    return set.toList();
  }

  List<Map<String, dynamic>> _filteredSortedItems() {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_items);

    // filter by category
    if (_selectedCategory != 'All') {
      list = list
          .where((item) => (item['category'] ?? '') == _selectedCategory)
          .toList();
    }

    // filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((item) =>
          (item['title'] as String).toLowerCase().contains(q))
          .toList();
    }

    // sort
    if (_sortOption == _SortOptions.priceLowToHigh) {
      list.sort(
              (a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortOption == _SortOptions.priceHighToLow) {
      list.sort(
              (a, b) => (b['price'] as double).compareTo(a['price'] as double));
    } else if (_sortOption == _SortOptions.titleAZ) {
      list.sort((a, b) =>
          (a['title'] as String).compareTo(b['title'] as String));
    }

    return list;
  }

  void _toggleFavorite(Map<String, dynamic> item) {
    setState(() {
      item['isFavorite'] = !item['isFavorite'];
      if (item['isFavorite']) {
        if (!_favorites.contains(item)) _favorites.add(item);
      } else {
        _favorites.remove(item);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item['isFavorite']
              ? 'Added to favorites!'
              : 'Removed from favorites!'),
        ),
      );
    });

    _saveFavoriteToFirestore(item).catchError((_) {});
  }

  void _addToBasket(Map<String, dynamic> item) {
    setState(() {
      item['count']++;
      if (!_basket.contains(item)) {
        _basket.add(item);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to basket!')),
      );
    });

    _saveCartItemToFirestore(item).catchError((_) {});
  }

  void _removeFromBasket(Map<String, dynamic> item) {
    setState(() {
      if (item['count'] > 0) {
        item['count']--;
      }
      if (item['count'] == 0) {
        _basket.remove(item);
      }
    });

    _saveCartItemToFirestore(item).catchError((_) {});
  }

  void _removeItemCompletely(Map<String, dynamic> item) {
    setState(() {
      item['count'] = 0;
      _basket.remove(item);
    });

    _saveCartItemToFirestore(item).catchError((_) {});
  }

  void _clearCart() {
    setState(() {
      for (var item in _basket) {
        item['count'] = 0;
      }
      _basket.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart cleared!')),
      );
    });

    _clearCartInFirestore().catchError((_) {});
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Sort by'),
                subtitle: Text(_sortOption),
              ),
              for (final opt in _SortOptions.all)
                RadioListTile<String>(
                  value: opt,
                  groupValue: _sortOption,
                  onChanged: (value) => Navigator.pop(context, value),
                  title: Text(opt),
                ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _sortOption = selected;
      });
    }
  }

  Future<void> _openSearch() async {
    final result = await showSearch<String?>(
      context: context,
      delegate: ProductSearchDelegate(items: _items),
    );

    if (result != null) {
      setState(() {
        _searchQuery = result;
      });
    }
  }

  Widget _navIconWithBadge({required IconData icon, required int badgeCount}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  AppBar _buildAppBar() {
    String title = 'ShopMart Clothing';
    List<Widget> actions = [];

    if (_currentIndex == 0) {
      actions = [
        IconButton(
          tooltip: 'Search',
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: _items.isEmpty ? null : _openSearch,
        ),
        IconButton(
          tooltip: 'Sort',
          icon: Icon(Icons.sort, color: Colors.white),
          onPressed: _items.isEmpty ? null : _openSortSheet,
        ),
      ];
    }

    return AppBar(
      title: Row(
        children: [
          Icon(Icons.checkroom, color: Colors.white, size: 30),
          SizedBox(width: 10),
          Text(title),
        ],
      ),
      backgroundColor: Color(0xFF04143C),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final basketCount = _basketItemsCount();

    return Scaffold(
      appBar: _buildAppBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _items.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _items.isEmpty) {
            return Center(child: Text('Failed to load products.'));
          }

          if (snapshot.hasData && _items.isEmpty) {
            // store loaded items once
            _items = snapshot.data!;
          }

          // Use IndexedStack so tab states persist (improvement)
          return IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                items: _filteredSortedItems(),
                categories: _categories(),
                selectedCategory: _selectedCategory,
                searchQuery: _searchQuery,
                onSearchQueryChanged: (q) {
                  setState(() => _searchQuery = q);
                },
                onCategoryChanged: (cat) {
                  setState(() => _selectedCategory = cat);
                },
                onOpenSort: _openSortSheet,
                onFavoriteToggle: _toggleFavorite,
                onAddToBasket: _addToBasket,
                onRemoveFromBasket: _removeFromBasket,
                onOpenDetails: (item) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        item: item,
                        onFavoriteToggle: _toggleFavorite,
                        onAddToBasket: _addToBasket,
                        onRemoveFromBasket: _removeFromBasket,
                      ),
                    ),
                  );
                },
              ),
              FavoritesScreen(
                favorites: _favorites,
                onOpenDetails: (item) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        item: item,
                        onFavoriteToggle: _toggleFavorite,
                        onAddToBasket: _addToBasket,
                        onRemoveFromBasket: _removeFromBasket,
                      ),
                    ),
                  );
                },
              ),
              BasketScreen(
                basket: _basket,
                onAddToBasket: _addToBasket,
                onRemoveFromBasket: _removeFromBasket,
                onRemoveItemCompletely: _removeItemCompletely,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Color(0xFF37B6FF),
        currentIndex: _currentIndex,
        selectedFontSize: 20,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedItemColor: Color(0xFF04143C),
        onTap: (int index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: _navIconWithBadge(
                icon: Icons.shopping_basket, badgeCount: basketCount),
            label: 'Basket',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Color(0xFF37B6FF),
                child: Text(userName.isNotEmpty ? userName[0] : 'G'),
              ),
              decoration: BoxDecoration(
                color: Color(0xFF04143C),
              ),
            ),
            ListTile(
              leading: Icon(Icons.login),
              title: Text("Login"),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
                if (result != null) {
                  setState(() {
                    userName = result['name'];
                    userEmail = result['email'];
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(onClearCart: _clearCart),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts),
              title: Text("Contact Us"),
              onTap: () {
                Navigator.pushNamed(context, '/contactScreen');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// SearchDelegate requirement (showSearch)
class ProductSearchDelegate extends SearchDelegate<String?> {
  final List<Map<String, dynamic>> items;

  ProductSearchDelegate({required this.items});

  @override
  String? get searchFieldLabel => 'Search products...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query.trim());
    return SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase().trim();

    final matches = q.isEmpty
        ? items
        : items
        .where((item) =>
        (item['title'] as String).toLowerCase().contains(q))
        .toList();

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final item = matches[index];
        return ListTile(
          leading: _AppNetworkImage(
            url: item['image'],
            width: 44,
            height: 44,
            radius: 8,
          ),
          title: Text(item['title']),
          subtitle: Text(_formatPrice(item['price'] as double)),
          onTap: () => close(context, item['title']),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;

  final Function(String) onSearchQueryChanged;
  final Function(String) onCategoryChanged;
  final Future<void> Function() onOpenSort;

  final Function(Map<String, dynamic>) onFavoriteToggle;
  final Function(Map<String, dynamic>) onAddToBasket;
  final Function(Map<String, dynamic>) onRemoveFromBasket;

  final Function(Map<String, dynamic>) onOpenDetails;

  HomeScreen({
    required this.items,
    required this.categories,
    required this.selectedCategory,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.onCategoryChanged,
    required this.onOpenSort,
    required this.onFavoriteToggle,
    required this.onAddToBasket,
    required this.onRemoveFromBasket,
    required this.onOpenDetails,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Per-item timer + visibility (fixes the "global _showCounter" problem)
  final Map<int, Timer> _counterTimers = {};
  final Set<int> _counterVisible = {};

  final TextEditingController _searchController = TextEditingController();

  // StreamBuilder requirement: live “flash sale countdown”
  late final DateTime _flashSaleEndsAt;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _flashSaleEndsAt = DateTime.now().add(Duration(minutes: 15));
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    for (final t in _counterTimers.values) {
      t.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _restartTimer(int itemId) {
    _counterTimers[itemId]?.cancel();
    _counterTimers[itemId] = Timer(Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() {
        _counterVisible.remove(itemId);
      });
    });
  }

  void _showCounter(int itemId) {
    _counterVisible.add(itemId);
    _restartTimer(itemId);
  }

  void _hideCounter(int itemId) {
    _counterTimers[itemId]?.cancel();
    _counterTimers.remove(itemId);
    _counterVisible.remove(itemId);
  }

  Future<void> _refresh() async {
    // RefreshIndicator requirement (simulate refresh)
    await Future.delayed(Duration(milliseconds: 450));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Products refreshed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CustomScrollView + Slivers requirement
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // StreamBuilder: live countdown banner
                  StreamBuilder<int>(
                    stream: Stream.periodic(Duration(seconds: 1), (i) => i),
                    builder: (context, snapshot) {
                      final now = DateTime.now();
                      final remaining = _flashSaleEndsAt.difference(now);
                      final seconds = remaining.inSeconds;

                      String text;
                      if (seconds <= 0) {
                        text = 'Flash sale ended';
                      } else {
                        final mm = (remaining.inMinutes % 60)
                            .toString()
                            .padLeft(2, '0');
                        final ss = (remaining.inSeconds % 60)
                            .toString()
                            .padLeft(2, '0');
                        text = 'Flash sale ends in 00:$mm:$ss';
                      }

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.06),
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer, color: Color(0xFF37B6FF)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onOpenSort,
                              child: Text('Sort'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 12),

                  // Autocomplete requirement (search bar)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue value) {
                      final q = value.text.toLowerCase().trim();
                      if (q.isEmpty) return const Iterable<String>.empty();
                      return widget.items
                          .map((e) => e['title'] as String)
                          .where((t) => t.toLowerCase().contains(q));
                    },
                    onSelected: (selected) {
                      _searchController.text = selected;
                      widget.onSearchQueryChanged(selected);
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode,
                        onSubmit) {
                      // Keep controller in sync with your state
                      textEditingController.text = _searchController.text;
                      return TextField(
                        controller: _searchController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchQueryChanged('');
                              FocusScope.of(context).unfocus();
                              setState(() {});
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          widget.onSearchQueryChanged(value);
                          setState(() {});
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 24,
                            constraints: BoxConstraints(maxHeight: 240),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final opt = options.elementAt(index);
                                return ListTile(
                                  title: Text(opt),
                                  onTap: () => onSelected(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 10),

                  // FilterChip requirement
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.categories.map((cat) {
                        final selected = cat == widget.selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) => widget.onCategoryChanged(cat),
                            selectedColor: Color(0xFF37B6FF).withOpacity(0.2),
                            checkmarkColor: Color(0xFF04143C),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 10),
                  Text(
                    widget.items.isEmpty ? 'No products found' : 'Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // SliverGrid requirement (shopping-style grid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = widget.items[index];
                  final id = item['id'] as int;
                  final isCounterVisible = _counterVisible.contains(id);
                  final count = item['count'] as int;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => widget.onOpenDetails(item),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Hero(
                                tag: item['heroTag'],
                                child: _AppNetworkImage(
                                  url: item['image'],
                                  width: double.infinity,
                                  height: double.infinity,
                                  radius: 0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Text(
                              item['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                            child: Text(
                              _formatPrice(item['price'] as double),
                              style: TextStyle(color: Color(0xFF04143C)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    item['isFavorite']
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: item['isFavorite']
                                        ? Colors.pink
                                        : null,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        widget.onFavoriteToggle(item));
                                  },
                                ),
                                Spacer(),

                                // AnimatedSwitcher requirement: switch between "+" and stepper
                                AnimatedSwitcher(
                                  duration: Duration(milliseconds: 220),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: isCounterVisible
                                      ? _QuantityStepper(
                                    key: ValueKey('stepper_$id'),
                                    count: count,
                                    onAdd: () {
                                      setState(() {
                                        widget.onAddToBasket(item);
                                        _showCounter(id);
                                      });
                                    },
                                    onRemove: () {
                                      setState(() {
                                        widget.onRemoveFromBasket(item);
                                        if ((item['count'] as int) <= 0) {
                                          _hideCounter(id);
                                        } else {
                                          _restartTimer(id);
                                        }
                                      });
                                    },
                                  )
                                      : IconButton(
                                    key: ValueKey('plus_$id'),
                                    icon: Icon(Icons.add_circle,
                                        color: Color(0xFF37B6FF)),
                                    onPressed: () {
                                      setState(() {
                                        widget.onAddToBasket(item);
                                        _showCounter(id);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: widget.items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated stepper (AnimatedContainer + AnimatedSwitcher already used above)
class _QuantityStepper extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityStepper({
    Key? key,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF37B6FF).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: Icon(Icons.remove),
            onPressed: onRemove,
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: count.toDouble()),
            duration: Duration(milliseconds: 180),
            builder: (_, value, __) {
              return Text(
                '${value.round()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: Icon(Icons.add),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) onOpenDetails;

  FavoritesScreen({required this.favorites, required this.onOpenDetails});

  Future<void> _refresh(BuildContext context) async {
    await Future.delayed(Duration(milliseconds: 350));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Favorites refreshed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: favorites.isEmpty
          ? ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80),
          Center(child: Text('No favorites yet.')),
        ],
      )
          : GridView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(12),
        itemCount: favorites.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final item = favorites[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOpenDetails(item),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                      child: Hero(
                        tag: item['heroTag'],
                        child: _AppNetworkImage(
                          url: item['image'],
                          width: double.infinity,
                          height: double.infinity,
                          radius: 0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(_formatPrice(item['price'] as double)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BasketScreen extends StatefulWidget {
  final List<Map<String, dynamic>> basket;

  final Function(Map<String, dynamic>) onAddToBasket;
  final Function(Map<String, dynamic>) onRemoveFromBasket;
  final Function(Map<String, dynamic>) onRemoveItemCompletely;

  BasketScreen({
    required this.basket,
    required this.onAddToBasket,
    required this.onRemoveFromBasket,
    required this.onRemoveItemCompletely,
  });

  @override
  _BasketScreenState createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  double _calculateSubtotal() {
    return widget.basket.fold(
      0,
          (sum, item) =>
      sum + ((item['price'] as double) * (item['count'] as int)),
    );
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(milliseconds: 350));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Basket refreshed!')),
    );
  }

  void _checkout() {
    showDialog(
      context: context,
      builder: (context) {
        final subtotal = _calculateSubtotal();
        return AlertDialog(
          title: Text('Checkout'),
          content:
          Text('Subtotal: ${_formatPrice(subtotal)}\n\nYou are checking out.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();

    return Column(
      children: [
        Expanded(
          // RefreshIndicator requirement
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: widget.basket.isEmpty
                ? ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 80),
                Center(child: Text('Your basket is empty.')),
              ],
            )
                : ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: widget.basket.length,
              itemBuilder: (context, index) {
                final item = widget.basket[index];

                // Dismissible requirement
                return Dismissible(
                  key: ValueKey(item['heroTag']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    widget.onRemoveItemCompletely(item);
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: _AppNetworkImage(
                        url: item['image'],
                        width: 54,
                        height: 54,
                        radius: 10,
                      ),
                      title: Text(item['title']),
                      subtitle: Text(_formatPrice(item['price'] as double)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() =>
                                  widget.onRemoveFromBasket(item));
                            },
                          ),
                          Text('${item['count']}'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() =>
                                  widget.onAddToBasket(item));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Bottom “checkout bar” requirement
        SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: Colors.black.withOpacity(0.08),
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtotal: ${_formatPrice(subtotal)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.basket.isEmpty ? null : _checkout,
                  child: Text('Checkout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  final Function(Map<String, dynamic>) onFavoriteToggle;
  final Function(Map<String, dynamic>) onAddToBasket;
  final Function(Map<String, dynamic>) onRemoveFromBasket;

  ProductDetailsScreen({
    required this.item,
    required this.onFavoriteToggle,
    required this.onAddToBasket,
    required this.onRemoveFromBasket,
  });

  Future<void> _openStoreLink() async {
    // url_launcher requirement (real use-case)
    final uri = Uri.parse('https://example.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (item['images'] as List?)?.cast<String>() ?? [item['image'] as String];
    final price = item['price'] as double;

    return Scaffold(
      appBar: AppBar(
        title: Text(item['title']),
        actions: [
          IconButton(
            icon: Icon(item['isFavorite'] ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              onFavoriteToggle(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(item['isFavorite'] ? 'Added to favorites!' : 'Removed from favorites!'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          // Hero + PageView requirement
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Hero(
                tag: item['heroTag'],
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return _AppNetworkImage(
                      url: images[index],
                      width: double.infinity,
                      height: double.infinity,
                      radius: 0,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 12),

          Text(
            item['title'],
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            _formatPrice(price),
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  onAddToBasket(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to basket!')),
                  );
                },
                icon: Icon(Icons.shopping_basket),
                label: Text('Add to basket'),
              ),
              SizedBox(width: 10),
              OutlinedButton(
                onPressed: _openStoreLink,
                child: Text('Open website'),
              ),
            ],
          ),

          SizedBox(height: 16),

          // ExpansionTile requirement (nice for shopping details)
          ExpansionTile(
            title: Text('Product details'),
            children: [
              ListTile(
                title: Text('Category'),
                subtitle: Text(item['category'] ?? 'N/A'),
              ),
              ListTile(
                title: Text('Description'),
                subtitle: Text(
                  'High quality product with comfortable fit and modern design.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Shipping & returns'),
            children: [
              ListTile(
                title: Text('Shipping'),
                subtitle: Text('2–4 business days داخل الأردن'),
              ),
              ListTile(
                title: Text('Returns'),
                subtitle: Text('Return within 7 days if unused.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  const _AppNetworkImage({
    required this.url,
    required this.width,
    required this.height,
    required this.radius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: FadeInImage(
        placeholder: MemoryImage(_transparentImage),
        image: NetworkImage(url),
        width: width,
        height: height,
        fit: fit,
        imageErrorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.black12,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final VoidCallback onClearCart;

  const SettingsScreen({Key? key, required this.onClearCart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings Page', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _clearAccount(context),
              child: Text('Logout'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onClearCart(),
              child: Text('Clear Cart'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAccount(BuildContext context) {
    Navigator.pop(context);
  }
}

class ContactScreen extends StatelessWidget {
  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Contacts:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Text('Zeina', style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => _launchEmail('zeina@example.com'),
              child: Text(
                'zeina@example.com',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            SizedBox(height: 20),

            Text('Joud', style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => _launchEmail('joud@example.com'),
              child: Text(
                'joud@example.com',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Color _passwordStrengthColor = Colors.red;
  String _passwordStrengthMessage = '';
  List<String> _passwordRequirements = [];
  bool _isPasswordStrong = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) => _checkPasswordStrength(value),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (!_isPasswordStrong) return 'Password is not strong enough';
                    return null;
                  },
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _calculatePasswordStrength(_passwordController.text),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                ),
                SizedBox(height: 10),
                Text(_passwordStrengthMessage, style: TextStyle(color: _passwordStrengthColor)),
                SizedBox(height: 10),
                Text('Password Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: Text(
                    'Password length should be at least 8 characters',
                    style: TextStyle(
                      color: _passwordRequirements.contains('length') ? Colors.green : null,
                    ),
                  ),
                  value: _passwordRequirements.contains('length'),
                  onChanged: null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text(
                    'Password should contain at least one uppercase letter',
                    style: TextStyle(
                      color: _passwordRequirements.contains('uppercase') ? Colors.green : null,
                    ),
                  ),
                  value: _passwordRequirements.contains('uppercase'),
                  onChanged: null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text(
                    'Password should contain at least one lowercase letter',
                    style: TextStyle(
                      color: _passwordRequirements.contains('lowercase') ? Colors.green : null,
                    ),
                  ),
                  value: _passwordRequirements.contains('lowercase'),
                  onChanged: null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text(
                    'Password should contain at least one digit',
                    style: TextStyle(
                      color: _passwordRequirements.contains('digit') ? Colors.green : null,
                    ),
                  ),
                  value: _passwordRequirements.contains('digit'),
                  onChanged: null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'name': _nameController.text,
                        'email': _emailController.text,
                      });
                    }
                  },
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      double strength = _calculatePasswordStrength(password);
      if (strength < 1 / 3) {
        _passwordStrengthColor = Colors.red;
        _passwordStrengthMessage = 'Weak Password!';
      } else if (strength < 2 / 3) {
        _passwordStrengthColor = Colors.orange;
        _passwordStrengthMessage = 'Medium Password!';
      } else {
        _passwordStrengthColor = Colors.green;
        _passwordStrengthMessage = 'Strong Password!';
      }

      _updatePasswordRequirements(password);
      _isPasswordStrong = strength == 1.0;
    });
  }

  double _calculatePasswordStrength(String password) {
    double strength = 0.0;
    if (password.length >= 8) strength += 1 / 4;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 1 / 4;
    if (password.contains(RegExp(r'[a-z]'))) strength += 1 / 4;
    if (password.contains(RegExp(r'[0-9]'))) strength += 1 / 4;
    return strength;
  }

  void _updatePasswordRequirements(String password) {
    List<String> requirements = [];
    if (password.length >= 8) requirements.add('length');
    if (password.contains(RegExp(r'[A-Z]'))) requirements.add('uppercase');
    if (password.contains(RegExp(r'[a-z]'))) requirements.add('lowercase');
    if (password.contains(RegExp(r'[0-9]'))) requirements.add('digit');

    setState(() => _passwordRequirements = requirements);
  }
}
