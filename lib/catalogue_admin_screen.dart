import 'package:flutter/material.dart';
import 'api_service.dart';

class CatalogueAdminScreen extends StatefulWidget {
  final String token;

  const CatalogueAdminScreen({super.key, required this.token});

  @override
  State<CatalogueAdminScreen> createState() => _CatalogueAdminScreenState();
}

class _CatalogueAdminScreenState extends State<CatalogueAdminScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final result = await ApiService.getAllProducts(widget.token);
    setState(() {
      if (result['success']) _products = result['data'];
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    final result = await ApiService.deleteProduct(widget.token, id);
    if (result['success']) {
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(
        text: product != null ? product['price'].toString() : '');
    final imageController = TextEditingController(text: product?['image_url'] ?? '');
    int? selectedCategoryId = product?['category_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product == null ? 'New product' : 'Edit product',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a3a6b),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in the product information',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                const Text('PRODUCT NAME', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Salmon Bowl',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('PRICE (dt)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('IMAGE URL', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: imageController,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('CATEGORY', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 2, 3, 4].map((catId) {
                    final names = {1: 'Bowls', 2: 'Sandwiches', 3: 'Boissons', 4: 'Desserts'};
                    final isSelected = selectedCategoryId == catId;
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return GestureDetector(
                          onTap: () => setStateDialog(() => selectedCategoryId = catId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1a3a6b) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              names[catId]!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          priceController.text.isEmpty ||
                          selectedCategoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez remplir tous les champs')),
                        );
                        return;
                      }

                      final result = product == null
                          ? await ApiService.createProduct(
                              widget.token,
                              selectedCategoryId!,
                              nameController.text,
                              priceController.text,
                              imageController.text,
                            )
                          : await ApiService.updateProduct(
                              widget.token,
                              product['id'],
                              selectedCategoryId!,
                              nameController.text,
                              priceController.text,
                              imageController.text,
                            );

                      if (result['success']) {
                        Navigator.pop(context);
                        _loadProducts();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'])),
                        );
                      }
                    },
                    icon: Icon(product == null ? Icons.add : Icons.save, color: Colors.white),
                    label: Text(
                      product == null ? 'Add product' : 'Save changes',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a3a6b),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Catalogue Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a3a6b),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a3a6b)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
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
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: product['image_url'] != null
                                      ? Image.network(
                                          product['image_url'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (c, e, s) => Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.fastfood, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.fastfood, color: Colors.grey),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${product['price']}dt',
                                      style: const TextStyle(color: Color(0xFF1a3a6b), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showAddEditDialog(product: product),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.edit, size: 14, color: Color(0xFF1a3a6b)),
                                              SizedBox(width: 4),
                                              Text('Edit', style: TextStyle(color: Color(0xFF1a3a6b), fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () => _deleteProduct(product['id']),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.delete, size: 14, color: Colors.red),
                                              SizedBox(width: 4),
                                              Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                                            ],
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add a new product',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a3a6b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}