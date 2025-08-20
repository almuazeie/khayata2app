import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';

class CustomerService {
  static const String fileName = 'customers_backup.json';

  /// ✅ تحميل العملاء من ملف التخزين المحلي
  static Future<List<Customer>> loadCustomers() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);

      return jsonList.map((item) => Customer(
        name: item['name'],
        phone: item['phone'],
        invoiceNumber: item['invoiceNumber'],
        createdAt: DateTime.parse(item['createdAt']),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// ✅ حفظ كل العملاء إلى الملف
  static Future<void> _saveAllCustomers(List<Customer> customers) async {
    final file = await _getLocalFile();
    final List<Map<String, dynamic>> jsonList = customers.map((c) => {
      'name': c.name,
      'phone': c.phone,
      'invoiceNumber': c.invoiceNumber,
      'createdAt': c.createdAt.toIso8601String(),
    }).toList();

    await file.writeAsString(jsonEncode(jsonList));
  }

  /// ✅ إضافة عميل
  static Future<void> addCustomer(Customer customer) async {
    final customers = await loadCustomers();
    customers.add(customer);
    await _saveAllCustomers(customers);
  }

  /// ✅ حذف عميل حسب الفهرس
  static Future<void> deleteCustomer(int index) async {
    final customers = await loadCustomers();
    if (index >= 0 && index < customers.length) {
      customers.removeAt(index);
      await _saveAllCustomers(customers);
    }
  }

  /// ✅ تحديث عميل حسب الفهرس
  static Future<void> updateCustomer({
    required int index,
    required Customer updatedCustomer,
  }) async {
    final customers = await loadCustomers();
    if (index >= 0 && index < customers.length) {
      customers[index] = updatedCustomer;
      await _saveAllCustomers(customers);
    }
  }

  /// ✅ تحديث عميل باستخدام الكائن مباشرة (بدون فهرس)
  static Future<void> editCustomer(Customer oldCustomer, Customer updatedCustomer) async {
    final customers = await loadCustomers();
    final updatedList = customers.map((c) {
      if (c.phone == oldCustomer.phone) {
        return updatedCustomer;
      }
      return c;
    }).toList();

    await _saveAllCustomers(updatedList);
  }

  /// ✅ التحقق من تكرار رقم الجوال
  static Future<bool> isDuplicatePhone(String phone) async {
    final customers = await loadCustomers();
    return customers.any((c) => c.phone == phone);
  }

  /// ✅ تصدير البيانات إلى ملف JSON خارجي
  static Future<String> exportToJsonFile() async {
    final customers = await loadCustomers();

    final List<Map<String, dynamic>> jsonList = customers.map((c) => {
      'name': c.name,
      'phone': c.phone,
      'invoiceNumber': c.invoiceNumber,
      'createdAt': c.createdAt.toIso8601String(),
    }).toList();

    final jsonString = jsonEncode(jsonList);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// ✅ استيراد العملاء من ملف JSON خارجي باستخدام file_selector
  static Future<void> importCustomersFromJson() async {
    final typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      final contents = await File(file.path).readAsString();
      final List<dynamic> jsonList = json.decode(contents);

      final newCustomers = jsonList.map((item) => Customer(
        name: item['name'],
        phone: item['phone'],
        invoiceNumber: item['invoiceNumber'],
        createdAt: DateTime.parse(item['createdAt']),
      )).toList();

      final existingCustomers = await loadCustomers();

      for (var customer in newCustomers) {
        final isDuplicate = existingCustomers.any((c) => c.phone == customer.phone);
        if (!isDuplicate) {
          existingCustomers.add(customer);
        }
      }

      await _saveAllCustomers(existingCustomers);
    }
  }

  /// ✅ الوصول إلى ملف التخزين المحلي
  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }
}