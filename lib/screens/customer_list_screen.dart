import 'dart:ui' as ui; // لضمان RTL
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/auth_service.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  /// رسالة نجاح اختيارية (مثلاً: "تم تسجيل الدخول بنجاح")
  final String? successMessage;

  const CustomerListScreen({Key? key, this.successMessage}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    // عرض رسالة النجاح (مرّة واحدة بعد بناء الإطار)
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final customers = await CustomerService.loadCustomers();
      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _filteredCustomers = customers;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  // ======== BottomSheet تأكيد الحذف ========
  Future<bool> _showDeleteConfirmSheet() async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('تأكيد الحذف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('هل أنت متأكد أنك تريد حذف هذا العميل؟'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          icon: const Icon(Icons.delete),
                          label: const Text('حذف'),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return res == true;
  }

  // ======== Dialog احتياطي للتأكيد ========
  Future<bool> _showDeleteConfirmDialog() async {
    final res = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا العميل؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.delete),
              label: const Text('حذف'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    return res == true;
  }

  /// تأكيد قبل الحذف ثم تنفيذ الحذف باستخدام الفهرس الأصلي
  Future<void> _confirmAndDelete(int originalIndex) async {
    if (originalIndex < 0 || originalIndex >= _allCustomers.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديد العميل المطلوب حذفه'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final ok = await _showDeleteConfirmSheet() || await _showDeleteConfirmDialog();
    if (ok) {
      await CustomerService.deleteCustomer(originalIndex);
      await _loadCustomers();
      if (!mounted) return;
      // بعد إعادة البناء: أعرض الرسالة في Frame لاحق لضمان ظهورها
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العميل بنجاح'), behavior: SnackBarBehavior.floating),
        );
      });
    }
  }

  /// الانتقال إلى شاشة الإضافة + إظهار "تمت إضافة العميل" بعد العودة
  Future<void> _navigateToAddCustomer() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );

    await _loadCustomers();

    if (!mounted) return;
    if (result == true) {
      // نؤجل الإظهار لِما بعد إعادة بناء الشاشة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة العميل بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  /// الانتقال إلى شاشة التعديل + إظهار "تم تحديث بيانات العميل" بعد العودة
  Future<void> _navigateToEditCustomer(Customer customer, int originalIndex) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditCustomerScreen(customer: customer)),
    );

    await _loadCustomers();

    if (!mounted) return;
    if (result == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات العميل'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  /// البطاقة تستقبل الـ originalIndex وتعيد تمريره للأزرار
  Widget _buildCustomerCard(Customer customer, int originalIndex) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navigateToEditCustomer(customer, originalIndex),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmAndDelete(originalIndex),
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
              try {
                final path = await CustomerService.exportToJsonFile();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حفظ النسخة الاحتياطية في:\n$path'), behavior: SnackBarBehavior.floating),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذّر التصدير: $e'), behavior: SnackBarBehavior.floating),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload),
            label: const Text('استيراد'),
            onPressed: () async {
              try {
                await CustomerService.importCustomersFromJson();
                await _loadCustomers();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذّر الاستيراد: $e'), behavior: SnackBarBehavior.floating),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.date_range),
            label: const Text('فلترة بالتاريخ'),
            onPressed: _selectDateRange,
          ),
          IconButton(
            tooltip: 'إعادة الكل',
            icon: const Icon(Icons.clear),
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
      textDirection: ui.TextDirection.rtl,
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
                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddCustomer,
          child: const Icon(Icons.add),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                itemBuilder: (context, i) {
                  final customer = _filteredCustomers[i];
                  final originalIndex = _allCustomers.indexOf(customer); // المؤشّر الأصلي
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