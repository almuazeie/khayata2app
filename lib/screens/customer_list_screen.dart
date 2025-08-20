import 'dart:ui' as ui; // ✅ لضمان TextDirection.rtl بدون تعارض
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/auth_service.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final String? successMessage;

  const CustomerListScreen({
    Key? key,
    this.successMessage,
  }) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    // ✅ عرض رسالة النجاح مرة واحدة
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.successMessage!)),
        );
      });
    }
  }

  Future<void> _loadCustomers() async {
    final customers = await CustomerService.loadCustomers();
    if (!mounted) return;
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
    });
  }

  void _searchCustomers(String query) {
    final search = query.toLowerCase();
    final filtered = _allCustomers.where((c) {
      return c.name.toLowerCase().contains(search) ||
          c.phone.toLowerCase().contains(search) ||
          c.invoiceNumber.toLowerCase().contains(search);
    }).toList();

    setState(() => _filteredCustomers = filtered);
  }

  void _filterByDate() {
    if (_fromDate == null || _toDate == null) return;

    final filtered = _allCustomers.where((c) {
      final d = c.createdAt;
      return d.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
          d.isBefore(_toDate!.add(const Duration(days: 1)));
    }).toList();

    setState(() => _filteredCustomers = filtered);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (_fromDate != null && _toDate != null)
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      _fromDate = picked.start;
      _toDate = picked.end;
      _filterByDate();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _fromDate = null;
      _toDate = null;
      _filteredCustomers = _allCustomers;
    });
  }

  Future<void> _deleteCustomer(int index) async {
    await CustomerService.deleteCustomer(index);
    await _loadCustomers();
  }

  Future<void> _navigateToAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );
    await _loadCustomers();
  }

  Future<void> _navigateToEditCustomer(Customer customer, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCustomerScreen(customer: customer)),
    );
    await _loadCustomers();
  }

  Widget _buildCustomerCard(Customer customer, int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 ${customer.phone}'),
            Text('🧾 ${customer.invoiceNumber}'),
            Text('📅 ${DateFormat('yyyy-MM-dd').format(customer.createdAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navigateToEditCustomer(customer, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCustomer(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('تصدير'),
            onPressed: () async {
              final path = await CustomerService.exportToJsonFile();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حفظ النسخة الاحتياطية في:\n$path')),
              );
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload),
            label: const Text('استيراد'),
            onPressed: () async {
              await CustomerService.importCustomersFromJson();
              await _loadCustomers();
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.date_range),
            label: const Text('فلترة بالتاريخ'),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'إعادة الكل',
            onPressed: _resetFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'عدد العملاء: ${_filteredCustomers.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection
          .rtl, // ✅ استخدام ui.TextDirection.rtl يزيل الخطأ نهائيًا
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة العملاء'),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.instance.signOut();
                if (!mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/auth', (_) => false);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddCustomer,
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            _buildTopButtons(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم العميل أو الجوال أو الفاتورة',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _searchCustomers,
              ),
            ),
            _buildCustomerCount(),
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : ListView.builder(
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _filteredCustomers[index];
                  final originalIndex = _allCustomers.indexOf(customer);
                  return _buildCustomerCard(customer, originalIndex);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}