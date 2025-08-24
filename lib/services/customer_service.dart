import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../models/customer.dart';

class CustomerService {
  static const String fileName = 'customers_backup.json';

  // --------- أدوات مساعدة خاصة ----------
  static String _clean(String s) => s.trim();

  static Map<String, dynamic> _toJson(Customer c) => {
    'name': _clean(c.name),
    'phone': _clean(c.phone),
    'invoiceNumber': _clean(c.invoiceNumber),
    'createdAt': c.createdAt.toIso8601String(),
  };

  static Customer _fromJson(Map<String, dynamic> m) {
    return Customer(
      name: _clean(m['name'] ?? ''),
      phone: _clean(m['phone'] ?? ''),
      invoiceNumber: _clean(m['invoiceNumber'] ?? ''),
      createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    // أنشئ الملف إن ما كان موجود
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]'); // مصفوفة فاضية صالحة JSON
    }
    return file;
  }

  // --------- عمليات القراءة/الكتابة الأساسية ----------
  static Future<List<Customer>> loadCustomers() async {
    try {
      final file = await _getLocalFile();
      final contents = await file.readAsString();

      if (contents.trim().isEmpty) return [];

      final dynamic decoded = json.decode(contents);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();
    } catch (_) {
      // لو الملف معطوب أو صار استثناء، نرجّع قائمة فاضية بدل ما يطيح التطبيق
      return [];
    }
  }

  static Future<void> _saveAllCustomers(List<Customer> customers) async {
    final file = await _getLocalFile();
    final list = customers.map(_toJson).toList();
    // استخدم writeAsString مع flush لضمان كتابة فورية
    await file.writeAsString(jsonEncode(list), flush: true);
  }

  // --------- واجهة عامة (ترجع bool للنجاح) ----------
  static Future<bool> addCustomer(Customer customer) async {
    try {
      final customers = await loadCustomers();

      // منع التكرار حسب رقم الجوال
      final phone = _clean(customer.phone);
      if (customers.any((c) => _clean(c.phone) == phone)) {
        return false;
      }

      customers.add(
        Customer(
          name: _clean(customer.name),
          phone: phone,
          invoiceNumber: _clean(customer.invoiceNumber),
          createdAt: customer.createdAt,
        ),
      );
      await _saveAllCustomers(customers);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteCustomer(int index) async {
    try {
      final customers = await loadCustomers();
      if (index < 0 || index >= customers.length) return false;
      customers.removeAt(index);
      await _saveAllCustomers(customers);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// تحديث حسب الفهرس
  static Future<bool> updateCustomer({
    required int index,
    required Customer updatedCustomer,
  }) async {
    try {
      final customers = await loadCustomers();
      if (index < 0 || index >= customers.length) return false;

      customers[index] = Customer(
        name: _clean(updatedCustomer.name),
        phone: _clean(updatedCustomer.phone),
        invoiceNumber: _clean(updatedCustomer.invoiceNumber),
        createdAt: customers[index].createdAt, // نحافظ على تاريخ الإنشاء
      );

      await _saveAllCustomers(customers);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// تحديث باستخدام الكائن القديم (مفيد إذا تغيّر رقم الجوال)
  static Future<bool> editCustomer(
      Customer oldCustomer, Customer updatedCustomer) async {
    try {
      final customers = await loadCustomers();
      final oldPhone = _clean(oldCustomer.phone);
      final idx = customers.indexWhere((c) => _clean(c.phone) == oldPhone);
      if (idx == -1) return false;

      customers[idx] = Customer(
        name: _clean(updatedCustomer.name),
        phone: _clean(updatedCustomer.phone),
        invoiceNumber: _clean(updatedCustomer.invoiceNumber),
        createdAt: customers[idx].createdAt, // احتفظ بتاريخ الإنشاء
      );

      await _saveAllCustomers(customers);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isDuplicatePhone(String phone) async {
    final customers = await loadCustomers();
    final p = _clean(phone);
    return customers.any((c) => _clean(c.phone) == p);
  }

  // --------- تصدير / استيراد ----------
  static Future<String> exportToJsonFile() async {
    try {
      final customers = await loadCustomers();
      final jsonString = jsonEncode(customers.map(_toJson).toList());

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString, flush: true);
      return file.path;
    } catch (e) {
      // رجّع رسالة الخطأ النصية علشان الواجهة تعرضها
      return 'ERROR: $e';
    }
  }

  /// استيراد باستخدام file_selector (يعمل على Android/Windows/macOS/iOS/Web حسب الدعم)
  static Future<bool> importCustomersFromJson() async {
    try {
      final typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
      final xfile = await openFile(acceptedTypeGroups: [typeGroup]);
      if (xfile == null) return false;

      final contents = await File(xfile.path).readAsString();
      final dynamic decoded = json.decode(contents);
      if (decoded is! List) return false;

      final newCustomers = decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();

      final existing = await loadCustomers();

      for (final nc in newCustomers) {
        final p = _clean(nc.phone);
        final dup = existing.any((c) => _clean(c.phone) == p);
        if (!dup) existing.add(nc);
      }

      await _saveAllCustomers(existing);
      return true;
    } catch (_) {
      return false;
    }
  }
}