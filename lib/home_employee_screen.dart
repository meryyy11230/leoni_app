import 'package:flutter/material.dart';
import 'api_service.dart';
import 'catalogue_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomeEmployeeScreen extends StatefulWidget {
  final String token;
  final String name;

  const HomeEmployeeScreen({
    super.key,
    required this.token,
    required this.name,
  });

  @override
  State<HomeEmployeeScreen> createState() => _HomeEmployeeScreenState();
}

class _HomeEmployeeScreenState extends State<HomeEmployeeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _todayMenu = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final menuResult = await ApiService.getTodayMenu(widget.token);
    final productsResult = await ApiService.getAllProducts(widget.token);

    setState(() {
      if (menuResult['success']) _todayMenu = menuResult['data'];
      if (productsResult['success']) _allProducts = productsResult['data'];
      _isLoading = false;
    });
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a3a6b),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu,
                    color: Colors.white, size: 28),
              ),
              Text(
                'Hello, ${widget.name} 👋',
                style: const TextStyle(
                  color: Color(0xFF1a3a6b),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Today's Menu
          const Text(
            "Today's Menu",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a3a6b),
            ),
          ),
          const SizedBox(height: 12),

          _todayMenu.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucun menu publié aujourd\'hui',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _todayMenu.length,
                    itemBuilder: (context, index) {
                      final product = _todayMenu[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           Container(
  height: 110,
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12)),
  ),
  child: ClipRRect(
    borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12)),
    child: product['image_url'] != null
        ? Image.network(
            product['image_url'],
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.fastfood,
                        color: Colors.grey, size: 40),
                  ),
                ),
          )
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.fastfood,
                  color: Colors.grey, size: 40),
            ),
          ),
  ),
),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${product['price']} dt',
                                        style: const TextStyle(
                                          color: Color(0xFF1a3a6b),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final result =
                                              await ApiService.addToCart(
                                            widget.token,
                                            product['id'],
                                            1,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result['success']
                                                  ? '${product['name']} ajouté au panier !'
                                                  : result['message']),
                                              backgroundColor: result['success']
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a3a6b),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 24),

          // For You
          const Text(
            'For you',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a3a6b),
            ),
          ),
          const SizedBox(height: 12),

          _allProducts.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucun produit disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _allProducts.length,
                  itemBuilder: (context, index) {
                    final product = _allProducts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
  child: ClipRRect(
    borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12)),
    child: product['image_url'] != null
        ? Image.network(
            product['image_url'],
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.fastfood,
                        color: Colors.grey, size: 40),
                  ),
                ),
          )
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.fastfood,
                  color: Colors.grey, size: 40),
            ),
          ),
  ),
),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${product['price']} dt',
                                      style: const TextStyle(
                                        color: Color(0xFF1a3a6b),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final result =
                                            await ApiService.addToCart(
                                          widget.token,
                                          product['id'],
                                          1,
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(result['success']
                                                ? '${product['name']} ajouté au panier !'
                                                : result['message']),
                                            backgroundColor: result['success']
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1a3a6b),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Add',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1a3a6b)))
            : _selectedIndex == 0
                ? _buildHome()
                : _selectedIndex == 1
                    ? CatalogueScreen(token: widget.token)
                    : _selectedIndex == 2
                        ? CartScreen(token: widget.token)
                        : ProfileScreen(
                            token: widget.token,
                            name: widget.name,
                          ),
      ),

      // Barre de navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1a3a6b),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: 'Catalogue'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}