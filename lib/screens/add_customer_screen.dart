import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _invoiceController = TextEditingController();

  List<Customer> _allCustomers = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    _allCustomers = await CustomerService.loadCustomers();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final invoiceNumber = _invoiceController.text.trim();

      // التحقق من تكرار رقم الجوال
      final isDuplicate = _allCustomers.any(
            (c) => c.phone.trim() == phone,
      );
      if (isDuplicate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الجوال مكرر ولا يمكن إضافته'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _saving = false); // حل مشكلة التعليق عند التكرار
        return;
      }

      final newCustomer = Customer(
        name: name,
        phone: phone,
        invoiceNumber: invoiceNumber,
        createdAt: DateTime.now(),
      );

      await CustomerService.addCustomer(newCustomer);

      if (!mounted) return;
      Navigator.pop(context, true); // إرجاع true عند الإضافة بنجاح
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر حفظ العميل: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة عميل')),
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم';
                    }
                    if (value.trim().length < 2) {
                      return 'الاسم قصير جدًا';
                    }
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
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'الرجاء إدخال رقم الجوال';
                    if (v.length < 8) return 'رقم الجوال غير صحيح';
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم الفاتورة';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _saveCustomer(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveCustomer,
                    icon: _saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.check),
                    label: const Text('إضافة العميل'),
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