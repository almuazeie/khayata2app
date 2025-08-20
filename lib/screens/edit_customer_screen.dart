import 'package:flutter/material.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _invoiceController;
  List<Customer> _allCustomers = [];

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
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final invoiceNumber = _invoiceController.text.trim();

      final isDuplicate = _allCustomers.any(
            (c) => c.phone == phone && c.phone != widget.customer.phone,
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الجوال مكرر ولا يمكن استخدامه'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedCustomer = Customer(
        name: name,
        phone: phone,
        invoiceNumber: invoiceNumber,
        createdAt: widget.customer.createdAt,
      );

      await CustomerService.editCustomer(widget.customer, updatedCustomer);

      if (!mounted) return;
      Navigator.pop(context, true); // ✅ إرجاع true عند النجاح
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل العميل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم العميل'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الجوال'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم الجوال';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _invoiceController,
                  decoration: const InputDecoration(labelText: 'رقم الفاتورة'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم الفاتورة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateCustomer,
                  child: const Text('تحديث'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}