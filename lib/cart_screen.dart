import 'package:flutter/material.dart';
import 'api_service.dart';

class CartScreen extends StatefulWidget {
  final String token;

  const CartScreen({super.key, required this.token});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final result = await ApiService.getCart(widget.token);
    setState(() {
      if (result['success']) {
        _cartItems = result['data']['items'] ?? [];
        _total = result['data']['total'] ?? 0;
      }
      _isLoading = false;
    });
  }

  Future<void> _removeItem(int itemId) async {
    final result = await ApiService.removeCartItem(widget.token, itemId);
    if (result['success']) {
      _loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _updateQuantity(int itemId, int quantity) async {
    if (quantity <= 0) {
      _removeItem(itemId);
      return;
    }
    final result =
        await ApiService.updateCartItem(widget.token, itemId, quantity);
    if (result['success']) {
      _loadCart();
    }
  }

  Future<void> _checkout() async {
    final result = await ApiService.checkout(widget.token);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Commande passée avec succès ! 🎉'),
            backgroundColor: Colors.green),
      );
      _loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mon Panier',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a3a6b),
                    ),
                  ),
                  Text(
                    '${_cartItems.length} article(s)',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Liste des items
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1a3a6b)))
                  : _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text(
                                'Votre panier est vide',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Image placeholder
                                ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: item['image_url'] != null
      ? Image.network(
          item['image_url'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood,
                    color: Colors.grey),
              ),
        )
      : Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: const Icon(Icons.fastfood,
              color: Colors.grey),
        ),
),
                                  const SizedBox(width: 12),

                                  // Nom + prix
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${item['unit_price']} dt',
                                          style: const TextStyle(
                                            color: Color(0xFF1a3a6b),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantité
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _updateQuantity(
                                            item['id'], item['quantity'] - 1),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.remove,
                                              size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          '${item['quantity']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _updateQuantity(
                                            item['id'], item['quantity'] + 1),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a3a6b),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.add,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Supprimer
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _removeItem(item['id']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Total + Commander
            if (!_isLoading && _cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total :',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_total.toStringAsFixed(2)} dt',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a3a6b),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a3a6b),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Commander',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}