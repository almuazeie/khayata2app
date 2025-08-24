import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;

  const EditCustomerScreen({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _invoiceController;

  List<Customer> _allCustomers = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _invoiceController = TextEditingController(text: widget.customer.invoiceNumber);
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    _allCustomers = await CustomerService.loadCustomers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    // أغلق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final invoiceNumber = _invoiceController.text.trim();

      // منع التكرار: أي عميل آخر يحمل نفس الجوال غير العميل الحالي
      final isDuplicate = _allCustomers.any(
            (c) => c.phone.trim() == phone && c.phone.trim() != widget.customer.phone.trim(),
      );

      if (isDuplicate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الجوال مكرر ولا يمكن استخدامه'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final updatedCustomer = Customer(
        name: name,
        phone: phone,
        invoiceNumber: invoiceNumber,
        createdAt: widget.customer.createdAt, // نحافظ على تاريخ الإنشاء
      );

      await CustomerService.editCustomer(widget.customer, updatedCustomer);

      if (!mounted) return;
      // نرجّع true عشان شاشة القائمة تعرض "تم التحديث" هناك
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر تحديث العميل: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل العميل'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'الرجاء إدخال الاسم';
                    if (val.length < 2) return 'الاسم قصير جدًا';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'الرجاء إدخال رقم الجوال';
                    if (val.length < 8) return 'رقم الجوال غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _invoiceController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'رقم الفاتورة',
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'الرجاء إدخال رقم الفاتورة';
                    return null;
                  },
                  onFieldSubmitted: (_) => _updateCustomer(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _updateCustomer,
                    icon: _saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save),
                    label: const Text('تحديث'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}