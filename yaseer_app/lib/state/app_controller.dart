import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../domain/models.dart';

class AppController extends ChangeNotifier {
  AppController({
    LocalStore? store,
    DateTime Function()? clock,
  })  : _store = store ?? LocalStore(),
        _clock = clock ?? DateTime.now {
    _data = AppData.initial(now: _clock());
  }

  static Future<AppController> create({
    LocalStore? store,
    DateTime Function()? clock,
  }) async {
    final controller = AppController(store: store, clock: clock);
    await controller.initialize();
    return controller;
  }

  final LocalStore _store;
  final DateTime Function() _clock;
  late AppData _data;
  Future<void> _writeChain = Future<void>.value();
  int _idSequence = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  Object? _loadError;

  AppData get data => _data;
  AppMode? get mode => _data.mode;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Object? get loadError => _loadError;
  List<PartyRecord> get parties => _data.parties;
  List<LedgerEntry> get ledgerEntries => _data.ledgerEntries;
  List<FinancialAccount> get accounts => _data.accounts;
  List<Product> get products => _data.products;
  List<InventoryMovement> get inventoryMovements => _data.inventoryMovements;
  List<SaleRecord> get sales => _data.sales;

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final loaded = await _store.load();
      if (loaded == null) {
        await _store.save(_data);
      } else if (loaded.accounts.isEmpty) {
        final cashAccount = AppData.initial(now: _clock()).accounts.single;
        _data = loaded.copyWith(accounts: <FinancialAccount>[cashAccount]);
        await _store.save(_data);
      } else {
        _data = loaded;
      }
      _isInitialized = true;
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMode(AppMode mode) => _replace(_data.copyWith(mode: mode));

  /// Returns to mode selection without deleting any business data.
  Future<void> resetMode() => _replace(_data.copyWith(mode: null));

  PartyRecord? partyById(String id) =>
      _firstWhereOrNull(_data.parties, (party) => party.id == id);

  FinancialAccount? accountById(String id) =>
      _firstWhereOrNull(_data.accounts, (account) => account.id == id);

  Product? productById(String id) =>
      _firstWhereOrNull(_data.products, (product) => product.id == id);

  SaleRecord? saleById(String id) =>
      _firstWhereOrNull(_data.sales, (sale) => sale.id == id);

  Future<PartyRecord> addParty({
    required String name,
    required PartyKind kind,
    String? phone,
    String? note,
  }) async {
    final now = _clock();
    final party = PartyRecord(
      id: _newId('party', now),
      name: _requiredText(name, 'اسم الطرف'),
      kind: kind,
      phone: _cleanText(phone),
      note: _cleanText(note),
      createdAt: now,
    );
    await _replace(
      _data.copyWith(parties: <PartyRecord>[..._data.parties, party]),
    );
    return party;
  }

  Future<LedgerEntry> recordCustomerDebt({
    required String customerId,
    required int amount,
    DateTime? dueDate,
    String? description,
  }) {
    _requireParty(customerId, PartyKind.customer);
    return _recordDebt(
      type: LedgerType.customerDebt,
      partyId: customerId,
      amount: amount,
      dueDate: dueDate,
      description: description,
    );
  }

  Future<LedgerEntry> recordCustomerPayment({
    required String customerId,
    required int amount,
    String? accountId,
    String? description,
  }) async {
    _requireParty(customerId, PartyKind.customer);
    _requirePositive(amount, 'قيمة الدفعة');
    final balance = customerBalance(customerId);
    if (amount > balance) {
      throw StateError(
        'الدفعة ($amount) أكبر من رصيد العميل المستحق ($balance).',
      );
    }
    final account = _resolveAccount(accountId);
    final now = _clock();
    final entry = LedgerEntry(
      id: _newId('ledger', now),
      type: LedgerType.customerPayment,
      amount: amount,
      occurredAt: now,
      partyId: customerId,
      accountId: account.id,
      description: _cleanText(description),
    );
    await _appendLedger(entry);
    return entry;
  }

  Future<LedgerEntry> receiveCustomerPayment({
    required String customerId,
    required int amount,
    String? accountId,
    String? description,
  }) =>
      recordCustomerPayment(
        customerId: customerId,
        amount: amount,
        accountId: accountId,
        description: description,
      );

  Future<LedgerEntry> recordSupplierDebt({
    required String supplierId,
    required int amount,
    DateTime? dueDate,
    String? description,
  }) {
    _requireParty(supplierId, PartyKind.supplier);
    return _recordDebt(
      type: LedgerType.supplierDebt,
      partyId: supplierId,
      amount: amount,
      dueDate: dueDate,
      description: description,
    );
  }

  Future<LedgerEntry> recordSupplierPayment({
    required String supplierId,
    required int amount,
    String? accountId,
    String? description,
  }) async {
    _requireParty(supplierId, PartyKind.supplier);
    _requirePositive(amount, 'قيمة الدفعة');
    final balance = supplierBalance(supplierId);
    if (amount > balance) {
      throw StateError(
        'الدفعة ($amount) أكبر من رصيد المورد المستحق ($balance).',
      );
    }
    final account = _resolveAccount(accountId);
    final now = _clock();
    final entry = LedgerEntry(
      id: _newId('ledger', now),
      type: LedgerType.supplierPayment,
      amount: amount,
      occurredAt: now,
      partyId: supplierId,
      accountId: account.id,
      description: _cleanText(description),
    );
    await _appendLedger(entry);
    return entry;
  }

  Future<LedgerEntry> paySupplier({
    required String supplierId,
    required int amount,
    String? accountId,
    String? description,
  }) =>
      recordSupplierPayment(
        supplierId: supplierId,
        amount: amount,
        accountId: accountId,
        description: description,
      );

  Future<LedgerEntry> recordIncome({
    required int amount,
    String? accountId,
    String? description,
  }) =>
      _recordAccountEntry(
        type: LedgerType.income,
        amount: amount,
        accountId: accountId,
        description: description,
      );

  Future<LedgerEntry> recordExpense({
    required int amount,
    String? accountId,
    String? description,
  }) =>
      _recordAccountEntry(
        type: LedgerType.expense,
        amount: amount,
        accountId: accountId,
        description: description,
      );

  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    String? description,
  }) async {
    _requirePositive(amount, 'قيمة التحويل');
    if (fromAccountId == toAccountId) {
      throw ArgumentError('يجب أن يختلف حساب المصدر عن حساب الوجهة.');
    }
    final from = _requireAccount(fromAccountId);
    final to = _requireAccount(toAccountId);
    final now = _clock();
    final referenceId = _newId('transfer', now);
    final cleanDescription = _cleanText(description);
    final outgoing = LedgerEntry(
      id: _newId('ledger', now),
      type: LedgerType.transferOut,
      amount: amount,
      occurredAt: now,
      accountId: from.id,
      relatedAccountId: to.id,
      description: cleanDescription,
      referenceId: referenceId,
    );
    final incoming = LedgerEntry(
      id: _newId('ledger', now),
      type: LedgerType.transferIn,
      amount: amount,
      occurredAt: now,
      accountId: to.id,
      relatedAccountId: from.id,
      description: cleanDescription,
      referenceId: referenceId,
    );
    await _replace(
      _data.copyWith(
        ledgerEntries: <LedgerEntry>[
          ..._data.ledgerEntries,
          outgoing,
          incoming,
        ],
      ),
    );
  }

  Future<FinancialAccount> addAccount({
    required String name,
    int openingBalance = 0,
  }) async {
    final cleanName = _requiredText(name, 'اسم الحساب');
    if (_data.accounts.any(
      (account) => account.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      throw ArgumentError.value(name, 'name', 'اسم الحساب مستخدم مسبقًا.');
    }
    final now = _clock();
    final account = FinancialAccount(
      id: _newId('account', now),
      name: cleanName,
      openingBalance: openingBalance,
      createdAt: now,
    );
    await _replace(
      _data.copyWith(
        accounts: <FinancialAccount>[..._data.accounts, account],
      ),
    );
    return account;
  }

  Future<Product> addProduct({
    required String name,
    String? sku,
    String? barcode,
    int salePrice = 0,
    int costPrice = 0,
    int minimumStock = 0,
    int initialStock = 0,
  }) async {
    _requireNonNegative(salePrice, 'سعر البيع');
    _requireNonNegative(costPrice, 'سعر التكلفة');
    _requireNonNegative(minimumStock, 'حد المخزون');
    _requireNonNegative(initialStock, 'المخزون الافتتاحي');
    final cleanSku = _cleanText(sku);
    final cleanBarcode = _cleanText(barcode);
    if (cleanSku != null &&
        _data.products.any((product) => product.sku == cleanSku)) {
      throw ArgumentError.value(sku, 'sku', 'رمز الصنف مستخدم مسبقًا.');
    }
    if (cleanBarcode != null &&
        _data.products.any((product) => product.barcode == cleanBarcode)) {
      throw ArgumentError.value(
        barcode,
        'barcode',
        'الباركود مستخدم مسبقًا.',
      );
    }

    final now = _clock();
    final product = Product(
      id: _newId('product', now),
      name: _requiredText(name, 'اسم الصنف'),
      sku: cleanSku,
      barcode: cleanBarcode,
      salePrice: salePrice,
      costPrice: costPrice,
      minimumStock: minimumStock,
      createdAt: now,
    );
    final movements = <InventoryMovement>[..._data.inventoryMovements];
    if (initialStock > 0) {
      movements.add(
        InventoryMovement(
          id: _newId('stock', now),
          productId: product.id,
          quantityDelta: initialStock,
          unitCost: costPrice,
          occurredAt: now,
          reason: 'مخزون افتتاحي',
          referenceId: product.id,
        ),
      );
    }
    await _replace(
      _data.copyWith(
        products: <Product>[..._data.products, product],
        inventoryMovements: movements,
      ),
    );
    return product;
  }

  Future<InventoryMovement> restockProduct({
    required String productId,
    required int quantity,
    required int unitCost,
    String? note,
  }) async {
    final product = _requireProduct(productId);
    _requirePositive(quantity, 'الكمية');
    _requireNonNegative(unitCost, 'تكلفة الوحدة');
    final oldStock = stockForProduct(productId);
    final newStock = oldStock + quantity;
    final weightedCost = newStock == 0
        ? unitCost
        : ((oldStock * product.costPrice + quantity * unitCost) / newStock)
            .round();
    final updatedProduct = product.copyWith(costPrice: weightedCost);
    final updatedProducts = _data.products
        .map((item) => item.id == productId ? updatedProduct : item)
        .toList();
    final now = _clock();
    final movement = InventoryMovement(
      id: _newId('stock', now),
      productId: productId,
      quantityDelta: quantity,
      unitCost: unitCost,
      occurredAt: now,
      reason: _cleanText(note) ?? 'توريد مخزون',
    );
    await _replace(
      _data.copyWith(
        products: updatedProducts,
        inventoryMovements: <InventoryMovement>[
          ..._data.inventoryMovements,
          movement,
        ],
      ),
    );
    return movement;
  }

  Future<SaleRecord> checkoutSale({
    required List<SaleLine> lines,
    required PaymentMethod paymentMethod,
    String? accountId,
    String? customerId,
    DateTime? dueDate,
    String? note,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'لا يمكن حفظ فاتورة فارغة.');
    }

    final requestedByProduct = <String, int>{};
    final normalizedLines = <SaleLine>[];
    for (final line in lines) {
      final product = _requireProduct(line.productId);
      if (!product.isActive) {
        throw StateError('الصنف «${product.name}» غير نشط.');
      }
      _requirePositive(line.quantity, 'كمية ${product.name}');
      _requireNonNegative(line.unitPrice, 'سعر ${product.name}');
      requestedByProduct.update(
        product.id,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
      normalizedLines.add(
        line.copyWith(
          productName: product.name,
          unitCost: product.costPrice,
        ),
      );
    }

    for (final request in requestedByProduct.entries) {
      final available = stockForProduct(request.key);
      if (request.value > available) {
        final product = _requireProduct(request.key);
        throw StateError(
          'مخزون «${product.name}» غير كافٍ: المتاح $available والمطلوب ${request.value}.',
        );
      }
    }

    final total = normalizedLines.fold<int>(
      0,
      (sum, line) => sum + line.lineTotal,
    );
    _requirePositive(total, 'إجمالي الفاتورة');

    FinancialAccount? account;
    PartyRecord? customer;
    if (paymentMethod == PaymentMethod.cash) {
      account = _resolveAccount(accountId);
    } else {
      if (customerId == null) {
        throw ArgumentError.notNull('customerId');
      }
      customer = _requireParty(customerId, PartyKind.customer);
    }

    final now = _clock();
    final saleId = _newId('sale', now);
    final sale = SaleRecord(
      id: saleId,
      lines: normalizedLines,
      paymentMethod: paymentMethod,
      totalAmount: total,
      accountId: account?.id,
      customerId: customer?.id,
      dueDate: paymentMethod == PaymentMethod.credit ? dueDate : null,
      note: _cleanText(note),
      createdAt: now,
    );
    final ledger = LedgerEntry(
      id: _newId('ledger', now),
      type: paymentMethod == PaymentMethod.cash
          ? LedgerType.cashSale
          : LedgerType.creditSale,
      amount: total,
      occurredAt: now,
      partyId: customer?.id,
      accountId: account?.id,
      dueDate: paymentMethod == PaymentMethod.credit ? dueDate : null,
      description: _cleanText(note) ?? 'فاتورة بيع',
      referenceId: saleId,
    );
    final movements = normalizedLines
        .map(
          (line) => InventoryMovement(
            id: _newId('stock', now),
            productId: line.productId,
            quantityDelta: -line.quantity,
            unitCost: line.unitCost,
            occurredAt: now,
            reason: 'بيع',
            referenceId: saleId,
          ),
        )
        .toList();

    await _replace(
      _data.copyWith(
        ledgerEntries: <LedgerEntry>[..._data.ledgerEntries, ledger],
        inventoryMovements: <InventoryMovement>[
          ..._data.inventoryMovements,
          ...movements,
        ],
        sales: <SaleRecord>[..._data.sales, sale],
      ),
    );
    return sale;
  }

  int customerBalance(String customerId) {
    var balance = 0;
    for (final entry in _data.ledgerEntries) {
      if (entry.partyId != customerId) continue;
      switch (entry.type) {
        case LedgerType.customerDebt:
        case LedgerType.creditSale:
          balance += entry.amount;
          break;
        case LedgerType.customerPayment:
          balance -= entry.amount;
          break;
        default:
          break;
      }
    }
    return balance;
  }

  int supplierBalance(String supplierId) {
    var balance = 0;
    for (final entry in _data.ledgerEntries) {
      if (entry.partyId != supplierId) continue;
      switch (entry.type) {
        case LedgerType.supplierDebt:
          balance += entry.amount;
          break;
        case LedgerType.supplierPayment:
          balance -= entry.amount;
          break;
        default:
          break;
      }
    }
    return balance;
  }

  int partyBalance(String partyId) {
    final party = _requireParty(partyId);
    return party.kind == PartyKind.customer
        ? customerBalance(partyId)
        : supplierBalance(partyId);
  }

  Map<String, int> get partyBalances => Map<String, int>.unmodifiable(
        <String, int>{
          for (final party in _data.parties) party.id: partyBalance(party.id),
        },
      );

  int accountBalance(String accountId) {
    final account = _requireAccount(accountId);
    var balance = account.openingBalance;
    for (final entry in _data.ledgerEntries) {
      if (entry.accountId != accountId) continue;
      switch (entry.type) {
        case LedgerType.customerPayment:
        case LedgerType.income:
        case LedgerType.transferIn:
        case LedgerType.cashSale:
          balance += entry.amount;
          break;
        case LedgerType.supplierPayment:
        case LedgerType.expense:
        case LedgerType.transferOut:
          balance -= entry.amount;
          break;
        default:
          break;
      }
    }
    return balance;
  }

  Map<String, int> get accountBalances => Map<String, int>.unmodifiable(
        <String, int>{
          for (final account in _data.accounts)
            account.id: accountBalance(account.id),
        },
      );

  int stockForProduct(String productId) {
    _requireProduct(productId);
    return _data.inventoryMovements
        .where((movement) => movement.productId == productId)
        .fold<int>(0, (stock, movement) => stock + movement.quantityDelta);
  }

  Map<String, int> get productStocks => Map<String, int>.unmodifiable(
        <String, int>{
          for (final product in _data.products)
            product.id: stockForProduct(product.id),
        },
      );

  List<Product> get lowStockProducts => List<Product>.unmodifiable(
        _data.products.where(
          (product) => stockForProduct(product.id) <= product.minimumStock,
        ),
      );

  int get todaySalesAmount {
    final today = _clock();
    return _data.sales
        .where((sale) => _isSameDay(sale.createdAt, today))
        .fold<int>(0, (sum, sale) => sum + sale.totalAmount);
  }

  int get todayExpenseAmount {
    final today = _clock();
    return _data.ledgerEntries
        .where(
          (entry) =>
              entry.type == LedgerType.expense &&
              _isSameDay(entry.occurredAt, today),
        )
        .fold<int>(0, (sum, entry) => sum + entry.amount);
  }

  int get todayCostOfGoodsAmount {
    final today = _clock();
    return _data.sales
        .where((sale) => _isSameDay(sale.createdAt, today))
        .fold<int>(0, (sum, sale) => sum + sale.costAmount);
  }

  int get todayProfitAmount =>
      todaySalesAmount - todayCostOfGoodsAmount - todayExpenseAmount;

  int get todaySales => todaySalesAmount;
  int get todayExpenses => todayExpenseAmount;
  int get todayProfit => todayProfitAmount;

  int get inventoryValue => _data.products.fold<int>(
        0,
        (sum, product) => sum + stockForProduct(product.id) * product.costPrice,
      );

  int outstandingDebt(String ledgerEntryId) =>
      _outstandingDebtAmounts[ledgerEntryId] ?? 0;

  List<LedgerEntry> get overdueDebtEntries {
    final today = _dateOnly(_clock());
    final outstanding = _outstandingDebtAmounts;
    return List<LedgerEntry>.unmodifiable(
      _debtEntries.where(
        (entry) =>
            outstanding[entry.id] != null &&
            outstanding[entry.id]! > 0 &&
            entry.dueDate != null &&
            _dateOnly(entry.dueDate!).isBefore(today),
      ),
    );
  }

  List<LedgerEntry> get dueTodayDebtEntries {
    final today = _dateOnly(_clock());
    final outstanding = _outstandingDebtAmounts;
    return List<LedgerEntry>.unmodifiable(
      _debtEntries.where(
        (entry) =>
            outstanding[entry.id] != null &&
            outstanding[entry.id]! > 0 &&
            entry.dueDate != null &&
            _dateOnly(entry.dueDate!) == today,
      ),
    );
  }

  int get overdueDebtAmount {
    final outstanding = _outstandingDebtAmounts;
    return overdueDebtEntries.fold<int>(
      0,
      (sum, entry) => sum + (outstanding[entry.id] ?? 0),
    );
  }

  int get dueTodayDebtAmount {
    final outstanding = _outstandingDebtAmounts;
    return dueTodayDebtEntries.fold<int>(
      0,
      (sum, entry) => sum + (outstanding[entry.id] ?? 0),
    );
  }

  int get overdueDebts => overdueDebtAmount;
  int get debtsDueToday => dueTodayDebtAmount;

  int get totalCustomerDebt => _data.parties
      .where((party) => party.kind == PartyKind.customer)
      .fold<int>(0, (sum, party) => sum + customerBalance(party.id));

  int get totalSupplierDebt => _data.parties
      .where((party) => party.kind == PartyKind.supplier)
      .fold<int>(0, (sum, party) => sum + supplierBalance(party.id));

  List<LedgerEntry> get _debtEntries => _data.ledgerEntries
      .where(
        (entry) =>
            entry.type == LedgerType.customerDebt ||
            entry.type == LedgerType.creditSale ||
            entry.type == LedgerType.supplierDebt,
      )
      .toList();

  Map<String, int> get _outstandingDebtAmounts {
    final result = <String, int>{};
    for (final party in _data.parties) {
      final debtTypes = party.kind == PartyKind.customer
          ? <LedgerType>{LedgerType.customerDebt, LedgerType.creditSale}
          : <LedgerType>{LedgerType.supplierDebt};
      final paymentType = party.kind == PartyKind.customer
          ? LedgerType.customerPayment
          : LedgerType.supplierPayment;
      final debts = _data.ledgerEntries
          .where(
            (entry) =>
                entry.partyId == party.id && debtTypes.contains(entry.type),
          )
          .toList()
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      var payments = _data.ledgerEntries
          .where(
            (entry) => entry.partyId == party.id && entry.type == paymentType,
          )
          .fold<int>(0, (sum, entry) => sum + entry.amount);

      for (final debt in debts) {
        final applied = payments > debt.amount ? debt.amount : payments;
        result[debt.id] = debt.amount - applied;
        payments -= applied;
      }
    }
    return result;
  }

  Future<LedgerEntry> _recordDebt({
    required LedgerType type,
    required String partyId,
    required int amount,
    DateTime? dueDate,
    String? description,
  }) async {
    _requirePositive(amount, 'قيمة الدين');
    final now = _clock();
    final entry = LedgerEntry(
      id: _newId('ledger', now),
      type: type,
      amount: amount,
      occurredAt: now,
      partyId: partyId,
      dueDate: dueDate,
      description: _cleanText(description),
    );
    await _appendLedger(entry);
    return entry;
  }

  Future<LedgerEntry> _recordAccountEntry({
    required LedgerType type,
    required int amount,
    String? accountId,
    String? description,
  }) async {
    _requirePositive(amount, 'المبلغ');
    final account = _resolveAccount(accountId);
    final now = _clock();
    final entry = LedgerEntry(
      id: _newId('ledger', now),
      type: type,
      amount: amount,
      occurredAt: now,
      accountId: account.id,
      description: _cleanText(description),
    );
    await _appendLedger(entry);
    return entry;
  }

  Future<void> _appendLedger(LedgerEntry entry) => _replace(
        _data.copyWith(
          ledgerEntries: <LedgerEntry>[..._data.ledgerEntries, entry],
        ),
      );

  Future<void> _replace(AppData next) async {
    _data = next;
    notifyListeners();
    final snapshot = next;
    final write = _writeChain.then<void>(
      (_) => _store.save(snapshot),
      onError: (Object _, StackTrace __) => _store.save(snapshot),
    );
    _writeChain = write;
    await write;
  }

  PartyRecord _requireParty(String id, [PartyKind? expectedKind]) {
    final party = partyById(id);
    if (party == null) {
      throw ArgumentError.value(id, 'partyId', 'الطرف غير موجود.');
    }
    if (expectedKind != null && party.kind != expectedKind) {
      final expected = expectedKind == PartyKind.customer ? 'عميلًا' : 'موردًا';
      throw ArgumentError.value(id, 'partyId', 'يجب أن يكون الطرف $expected.');
    }
    return party;
  }

  FinancialAccount _requireAccount(String id) {
    final account = accountById(id);
    if (account == null || account.isArchived) {
      throw ArgumentError.value(id, 'accountId', 'الحساب غير موجود أو مؤرشف.');
    }
    return account;
  }

  FinancialAccount _resolveAccount(String? id) {
    if (id != null) return _requireAccount(id);
    final defaultAccount = accountById(AppData.defaultCashAccountId);
    if (defaultAccount != null && !defaultAccount.isArchived) {
      return defaultAccount;
    }
    final active = _firstWhereOrNull(
      _data.accounts,
      (account) => !account.isArchived,
    );
    if (active == null) {
      throw StateError('لا يوجد حساب مالي نشط.');
    }
    return active;
  }

  Product _requireProduct(String id) {
    final product = productById(id);
    if (product == null) {
      throw ArgumentError.value(id, 'productId', 'الصنف غير موجود.');
    }
    return product;
  }

  String _newId(String prefix, DateTime now) =>
      '$prefix-${now.microsecondsSinceEpoch}-${_idSequence++}';

  static String _requiredText(String value, String fieldName) {
    final clean = value.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(value, fieldName, '$fieldName مطلوب.');
    }
    return clean;
  }

  static String? _cleanText(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  static void _requirePositive(int value, String fieldName) {
    if (value <= 0) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName يجب أن يكون موجبًا.');
    }
  }

  static void _requireNonNegative(int value, String fieldName) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName لا يمكن أن يكون سالبًا.',
      );
    }
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _isSameDay(DateTime first, DateTime second) =>
      _dateOnly(first) == _dateOnly(second);

  static T? _firstWhereOrNull<T>(
    Iterable<T> values,
    bool Function(T) test,
  ) {
    for (final value in values) {
      if (test(value)) return value;
    }
    return null;
  }
}
