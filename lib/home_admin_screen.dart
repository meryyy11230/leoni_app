import 'package:flutter/material.dart';
import 'api_service.dart';
import 'catalogue_admin_screen.dart';
import 'menu_admin_screen.dart';
import 'login_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  final String token;
  final String name;

  const HomeAdminScreen({
    super.key,
    required this.token,
    required this.name,
  });

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  int _selectedIndex = 0;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  int _total = 0;
  int _pending = 0;
  int _preparing = 0;
  int _delivered = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final result = await ApiService.getAllOrders(widget.token);
    setState(() {
      if (result['success']) {
        _orders = result['data'];
        _total = _orders.length;
        _pending = _orders.where((o) => o['status'] == 'pending').length;
        _preparing = _orders.where((o) => o['status'] == 'preparing').length;
        _delivered = _orders.where((o) => o['status'] == 'delivered').length;
      }
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'In preparation';
      case 'ready': return 'Ready';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final result = await ApiService.updateOrderStatus(widget.token, orderId, newStatus);
    if (result['success']) {
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Administration',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Color(0xFF1a3a6b),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _buildStatCard('$_total', 'Total', Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard('$_pending', 'En attente', Colors.orange),
              const SizedBox(width: 8),
              _buildStatCard('$_preparing', 'En préparation', Colors.purple),
              const SizedBox(width: 8),
              _buildStatCard('$_delivered', 'Livrée', Colors.teal),
            ],
          ),
          const SizedBox(height: 24),

          // Order Flow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order flow',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a3a6b),
                ),
              ),
              const Text('Today', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a3a6b)))
              : _orders.isEmpty
                  ? const Center(child: Text('Aucune commande', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final name = order['name'] ?? 'Inconnu';
                        final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a3a6b).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFF1a3a6b),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Infos
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${order['name']} - MAT-${order['matricule']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${order['total_price']} dt',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Status dropdown
                              DropdownButton<String>(
                                value: order['status'],
                                underline: const SizedBox(),
                                style: TextStyle(
                                  color: _getStatusColor(order['status']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                items: ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled']
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(_getStatusText(s),
                                              style: TextStyle(color: _getStatusColor(s))),
                                        ))
                                    .toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    _updateStatus(order['id'], newStatus);
                                  }
                                },
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

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildDashboard()
            : _selectedIndex == 1
                ? CatalogueAdminScreen(token: widget.token)
                : MenuAdminScreen(token: widget.token),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1a3a6b),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Catalogue'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Menu'),
        ],
      ),
    );
  }
}