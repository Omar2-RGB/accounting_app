import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // ✅ الإصدار 3 مع دعم العملات
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // إنشاء جدول العملات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS currencies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL,
          exchange_rate REAL NOT NULL,
          is_default INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      // إضافة عمود العملة إلى جدول الفواتير
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN currency_id INTEGER');
        await db.execute('ALTER TABLE invoices ADD COLUMN currency_rate REAL');
      } catch (e) {
        // الأعمدة موجودة مسبقاً
      }

      // إضافة العملات الافتراضية
      final existingCurrencies = await db.query('currencies');
      if (existingCurrencies.isEmpty) {
        await db.insert('currencies', {
          'code': 'JOD',
          'name': 'دينار أردني',
          'symbol': 'د.أ',
          'exchange_rate': 1.0,
          'is_default': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('currencies', {
          'code': 'USD',
          'name': 'دولار أمريكي',
          'symbol': '\$',
          'exchange_rate': 0.71,
          'is_default': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('currencies', {
          'code': 'KWD',
          'name': 'دينار كويتي',
          'symbol': 'د.ك',
          'exchange_rate': 0.30,
          'is_default': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('currencies', {
          'code': 'SYP',
          'name': 'ليرة سورية',
          'symbol': 'ل.س',
          'exchange_rate': 7.50,
          'is_default': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // تحديث الفواتير القديمة لربطها بالعملة الافتراضية
      final defaultCurr = await db.query(
        'currencies',
        where: 'is_default = 1',
      );
      if (defaultCurr.isNotEmpty) {
        final defaultId = defaultCurr.first['id'];
        await db.rawUpdate(
          'UPDATE invoices SET currency_id = ?, currency_rate = 1.0 WHERE currency_id IS NULL',
          [defaultId],
        );
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. جدول المستخدمين
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // 2. جدول جهات الاتصال
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. جدول العملات
    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        exchange_rate REAL NOT NULL,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. جدول الفواتير (معدل مع العملات)
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        contact_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        tax REAL DEFAULT 0,
        grand_total REAL NOT NULL,
        currency_id INTEGER NOT NULL,
        currency_rate REAL NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE,
        FOREIGN KEY (currency_id) REFERENCES currencies (id) ON DELETE CASCADE
      )
    ''');

    // 5. جدول بنود الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 6. جدول المدفوعات
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        contact_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE SET NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
      )
    ''');

    // ===== ✅ إدراج العملات الافتراضية =====
    // 1. الدينار الأردني (العملة الأساسية)
    await db.insert('currencies', {
      'code': 'JOD',
      'name': 'دينار أردني',
      'symbol': 'د.أ',
      'exchange_rate': 1.0,
      'is_default': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. الدولار الأمريكي
    await db.insert('currencies', {
      'code': 'USD',
      'name': 'دولار أمريكي',
      'symbol': '\$',
      'exchange_rate': 0.71,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. الدينار الكويتي
    await db.insert('currencies', {
      'code': 'KWD',
      'name': 'دينار كويتي',
      'symbol': 'د.ك',
      'exchange_rate': 0.30,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 4. الليرة السورية
    await db.insert('currencies', {
      'code': 'SYP',
      'name': 'ليرة سورية',
      'symbol': 'ل.س',
      'exchange_rate': 7.50,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        contact_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        tax REAL DEFAULT 0,
        grand_total REAL NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        contact_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE SET NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
      )
    ''');
    // 7. جدول المنتجات
await db.execute('''
  CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price REAL NOT NULL,
    cost REAL NOT NULL,
    quantity REAL DEFAULT 0,
    sku TEXT UNIQUE,
    category TEXT,
    created_at TEXT NOT NULL
  )
''');

// 8. جدول المصاريف
await db.execute('''
  CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    category TEXT NOT NULL,
    date TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL
  )
''');

// 9. جدول مخزون المنتجات (للمتابعة)
await db.execute('''
  CREATE TABLE inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    quantity REAL NOT NULL,
    type TEXT NOT NULL,  -- 'in' (إضافة) أو 'out' (صرف)
    note TEXT,
    date TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
  )
''');
  }

  // ==================== دوال المستخدمين ====================
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;
    final data = {
      'name': name,
      'email': email,
      'password': password,
    };
    return await db.insert('users', data);
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }
// ==================== دوال المنتجات ====================
Future<int> addProduct(Map<String, dynamic> product) async {
  final db = await database;
  return await db.insert('products', product);
}

Future<List<Map<String, dynamic>>> getAllProducts() async {
  final db = await database;
  return await db.query('products', orderBy: 'name ASC');
}

Future<Map<String, dynamic>?> getProduct(int id) async {
  final db = await database;
  final result = await db.query(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );
  return result.isNotEmpty ? result.first : null;
}

Future<List<Map<String, dynamic>>> searchProducts(String query) async {
  final db = await database;
  return await db.query(
    'products',
    where: 'name LIKE ? OR sku LIKE ?',
    whereArgs: ['%$query%', '%$query%'],
    orderBy: 'name ASC',
  );
}

Future<int> updateProduct(Map<String, dynamic> product) async {
  final db = await database;
  return await db.update(
    'products',
    product,
    where: 'id = ?',
    whereArgs: [product['id']],
  );
}

Future<int> deleteProduct(int id) async {
  final db = await database;
  return await db.delete(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<double> getProductQuantity(int productId) async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT quantity FROM products WHERE id = ?',
    [productId],
  );
  return result.isNotEmpty ? (result.first['quantity'] as double? ?? 0.0) : 0.0;
}

Future<void> updateProductQuantity(int productId, double newQuantity) async {
  final db = await database;
  await db.update(
    'products',
    {'quantity': newQuantity},
    where: 'id = ?',
    whereArgs: [productId],
  );
}
// ==================== دوال المصاريف ====================
Future<int> addExpense(Map<String, dynamic> expense) async {
  final db = await database;
  return await db.insert('expenses', expense);
}

Future<List<Map<String, dynamic>>> getAllExpenses() async {
  final db = await database;
  return await db.query('expenses', orderBy: 'date DESC');
}

Future<List<Map<String, dynamic>>> getExpensesByDate(DateTime start, DateTime end) async {
  final db = await database;
  return await db.query(
    'expenses',
    where: 'date BETWEEN ? AND ?',
    whereArgs: [start.toIso8601String(), end.toIso8601String()],
    orderBy: 'date DESC',
  );
}

Future<double> getTotalExpensesByDate(DateTime start, DateTime end) async {
  final db = await database;
  final result = await db.rawQuery('''
    SELECT SUM(amount) as total FROM expenses 
    WHERE date BETWEEN ? AND ?
  ''', [start.toIso8601String(), end.toIso8601String()]);
  return result.first['total'] as double? ?? 0.0;
}

Future<List<String>> getExpenseCategories() async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT DISTINCT category FROM expenses ORDER BY category ASC',
  );
  return result.map((e) => e['category'] as String).toList();
}

// ✅ أضف هذه الدوال الجديدة:
Future<int> deleteExpense(int id) async {
  final db = await database;
  return await db.delete(
    'expenses',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> updateExpense(Map<String, dynamic> expense) async {
  final db = await database;
  return await db.update(
    'expenses',
    expense,
    where: 'id = ?',
    whereArgs: [expense['id']],
  );
}

Future<Map<String, dynamic>?> getExpense(int id) async {
  final db = await database;
  final result = await db.query(
    'expenses',
    where: 'id = ?',
    whereArgs: [id],
  );
  return result.isNotEmpty ? result.first : null;
}
// ==================== دوال المخزون ====================
Future<int> addInventoryTransaction(Map<String, dynamic> transaction) async {
  final db = await database;
  // تحديث كمية المنتج
  final product = await getProduct(transaction['product_id']);
  if (product != null) {
    double newQuantity = product['quantity'] as double? ?? 0.0;
    if (transaction['type'] == 'in') {
      newQuantity += transaction['quantity'] as double;
    } else {
      newQuantity -= transaction['quantity'] as double;
    }
    await updateProductQuantity(transaction['product_id'], newQuantity);
  }
  return await db.insert('inventory', transaction);
}

Future<List<Map<String, dynamic>>> getInventoryTransactions(int productId) async {
  final db = await database;
  return await db.query(
    'inventory',
    where: 'product_id = ?',
    whereArgs: [productId],
    orderBy: 'date DESC',
  );
}

Future<List<Map<String, dynamic>>> getAllInventoryTransactions() async {
  final db = await database;
  return await db.query('inventory', orderBy: 'date DESC');
}
// ==================== دوال الأرباح والخسائر ====================
Future<Map<String, double>> getProfitLoss(DateTime start, DateTime end) async {
  final db = await database;
  
  // إجمالي المبيعات (فواتير البيع)
  final salesResult = await db.rawQuery('''
    SELECT SUM(grand_total * currency_rate) as total 
    FROM invoices 
    WHERE type = 'sale' AND date BETWEEN ? AND ?
  ''', [start.toIso8601String(), end.toIso8601String()]);
  final totalSales = salesResult.first['total'] as double? ?? 0.0;

  // إجمالي المشتريات (فواتير الشراء)
  final purchasesResult = await db.rawQuery('''
    SELECT SUM(grand_total * currency_rate) as total 
    FROM invoices 
    WHERE type = 'purchase' AND date BETWEEN ? AND ?
  ''', [start.toIso8601String(), end.toIso8601String()]);
  final totalPurchases = purchasesResult.first['total'] as double? ?? 0.0;

  // إجمالي المصاريف
  final totalExpenses = await getTotalExpensesByDate(start, end);

  // حساب صافي الربح/الخسارة
  final profit = totalSales - totalPurchases - totalExpenses;

  return {
    'sales': totalSales,
    'purchases': totalPurchases,
    'expenses': totalExpenses,
    'profit': profit,
  };
}

// جلب ديون العملاء (الرصيد المستحق)
Future<List<Map<String, dynamic>>> getCustomerDebts() async {
  final db = await database;
  // جلب جميع العملاء مع إجمالي فواتير البيع غير المدفوعة
  final customers = await getContactsByType('client');
  List<Map<String, dynamic>> debts = [];
  for (var c in customers) {
    final invoices = await db.rawQuery('''
      SELECT SUM(grand_total * currency_rate) as total
      FROM invoices
      WHERE contact_id = ? AND type = 'sale' AND status != 'paid'
    ''', [c['id']]);
    final amount = invoices.first['total'] as double? ?? 0.0;
    if (amount > 0) {
      c['debt_amount'] = amount;
      debts.add(c);
    }
  }
  debts.sort((a, b) => (b['debt_amount'] as double).compareTo(a['debt_amount'] as double));
  return debts;
}
  // ==================== دوال جهات الاتصال ====================
  Future<int> addContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final db = await database;
    return await db.query('contacts', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getContactsByType(String type) async {
    final db = await database;
    return await db.query(
      'contacts',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getContact(int id) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.update(
      'contacts',
      contact,
      where: 'id = ?',
      whereArgs: [contact['id']],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getContactName(int contactId) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [contactId],
    );
    if (result.isNotEmpty) {
      return result.first['name'] as String;
    }
    return null;
  }

  // ==================== دوال الفواتير ====================
  Future<int> addInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice);
  }

  Future<int> addInvoiceItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('invoice_items', item);
  }

  Future<List<Map<String, dynamic>>> getInvoicesByContact(int contactId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    return await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getInvoiceWithDetails(int invoiceId) async {
    final db = await database;
    final invoiceResult = await db.rawQuery('''
      SELECT invoices.*, contacts.name as contact_name, contacts.phone as contact_phone,
             currencies.symbol as currency_symbol
      FROM invoices
      INNER JOIN contacts ON invoices.contact_id = contacts.id
      LEFT JOIN currencies ON invoices.currency_id = currencies.id
      WHERE invoices.id = ?
    ''', [invoiceId]);
    if (invoiceResult.isEmpty) return null;

    final invoice = invoiceResult.first;
    final items = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    invoice['items'] = items;
    return invoice;
  }

  // ==================== دوال المدفوعات ====================
  Future<int> addPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByContact(int contactId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentsByInvoice(int invoiceId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await database;
    return await db.query('payments', orderBy: 'date DESC');
  }

  // ==================== دوال خاصة بالمدفوعات وتحديث حالة الفواتير ====================
  
  Future<List<Map<String, dynamic>>> getUnpaidInvoicesByContact(int contactId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'contact_id = ? AND status != ?',
      whereArgs: [contactId, 'paid'],
      orderBy: 'date DESC',
    );
  }

  Future<double> getPaidAmountForInvoice(int invoiceId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE invoice_id = ?',
      [invoiceId],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<void> updateInvoiceStatus(int invoiceId) async {
    final db = await database;
    
    final invoiceResult = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    if (invoiceResult.isEmpty) return;
    
    final invoice = invoiceResult.first;
    final grandTotal = invoice['grand_total'] as double;
    final paidAmount = await getPaidAmountForInvoice(invoiceId);
    
    String status;
    if (paidAmount >= grandTotal) {
      status = 'paid';
    } else if (paidAmount > 0) {
      status = 'partial';
    } else {
      status = 'unpaid';
    }
    
    await db.update(
      'invoices',
      {'status': status},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<int> addPaymentWithStatusUpdate(Map<String, dynamic> payment) async {
    final db = await database;
    
    final paymentId = await db.insert('payments', payment);
    
    if (payment['invoice_id'] != null) {
      await updateInvoiceStatus(payment['invoice_id']);
    }
    
    return paymentId;
  }

  // ==================== دوال العملات ====================
  Future<int> addCurrency(Map<String, dynamic> currency) async {
    final db = await database;
    return await db.insert('currencies', currency);
  }

  Future<List<Map<String, dynamic>>> getAllCurrencies() async {
    final db = await database;
    return await db.query('currencies', orderBy: 'is_default DESC, name ASC');
  }

  Future<Map<String, dynamic>?> getDefaultCurrency() async {
    final db = await database;
    final result = await db.query(
      'currencies',
      where: 'is_default = 1',
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getCurrencyById(int id) async {
    final db = await database;
    final result = await db.query(
      'currencies',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCurrency(Map<String, dynamic> currency) async {
    final db = await database;
    return await db.update(
      'currencies',
      currency,
      where: 'id = ?',
      whereArgs: [currency['id']],
    );
  }

  Future<int> deleteCurrency(int id) async {
    final db = await database;
    final currency = await getCurrencyById(id);
    if (currency != null && currency['is_default'] == 1) {
      return -1;
    }
    return await db.delete(
      'currencies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> getCurrencySymbolForInvoice(int invoiceId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.symbol 
      FROM invoices i
      JOIN currencies c ON i.currency_id = c.id
      WHERE i.id = ?
    ''', [invoiceId]);
    return result.isNotEmpty ? result.first['symbol'] as String : 'د.أ';
  }

  // ==================== دوال حساب الأرصدة (بالعملة الأساسية) ====================
  Future<double> getTotalReceivables() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(grand_total * currency_rate) as total 
      FROM invoices 
      WHERE type = 'sale' AND status != 'paid'
    ''');
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalPayables() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(grand_total * currency_rate) as total 
      FROM invoices 
      WHERE type = 'purchase' AND status != 'paid'
    ''');
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalBalance() async {
    final receivables = await getTotalReceivables();
    final payables = await getTotalPayables();
    return receivables - payables;
  }

  // ==================== إغلاق قاعدة البيانات ====================
  Future close() async {
    final db = await database;
    db.close();
  }
}