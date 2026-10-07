enum AppMode { basic, professional }

enum PartyKind { customer, supplier }

enum LedgerType {
  customerDebt,
  customerPayment,
  supplierDebt,
  supplierPayment,
  income,
  expense,
  transferIn,
  transferOut,
  cashSale,
  creditSale,
}

enum PaymentMethod { cash, credit }

const Object _notProvided = Object();

T _enumFromName<T extends Enum>(List<T> values, Object? value) {
  final name = value?.toString();
  for (final item in values) {
    if (item.name == name) return item;
  }
  throw FormatException('Unknown enum value: $value');
}

int _intFromJson(Object? value, [int fallback = 0]) {
  return value is num ? value.toInt() : fallback;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime _dateFromJson(Object? value) {
  if (value is! String) {
    throw const FormatException('Missing date value');
  }
  return DateTime.parse(value);
}

DateTime? _nullableDateFromJson(Object? value) {
  return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}

class PartyRecord {
  const PartyRecord({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    this.phone,
    this.note,
  });

  final String id;
  final String name;
  final PartyKind kind;
  final String? phone;
  final String? note;
  final DateTime createdAt;

  PartyRecord copyWith({
    String? id,
    String? name,
    PartyKind? kind,
    Object? phone = _notProvided,
    Object? note = _notProvided,
    DateTime? createdAt,
  }) {
    return PartyRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      phone: identical(phone, _notProvided) ? this.phone : phone as String?,
      note: identical(note, _notProvided) ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'kind': kind.name,
        'phone': phone,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PartyRecord.fromJson(Map<String, dynamic> json) => PartyRecord(
        id: json['id'].toString(),
        name: json['name'].toString(),
        kind: _enumFromName(PartyKind.values, json['kind']),
        phone: _nullableString(json['phone']),
        note: _nullableString(json['note']),
        createdAt: _dateFromJson(json['createdAt']),
      );
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.partyId,
    this.accountId,
    this.relatedAccountId,
    this.dueDate,
    this.description,
    this.referenceId,
  });

  final String id;
  final LedgerType type;

  /// Whole riyals. Values are always positive; [type] determines direction.
  final int amount;
  final DateTime occurredAt;
  final String? partyId;
  final String? accountId;
  final String? relatedAccountId;
  final DateTime? dueDate;
  final String? description;
  final String? referenceId;

  DateTime get date => occurredAt;

  LedgerEntry copyWith({
    String? id,
    LedgerType? type,
    int? amount,
    DateTime? occurredAt,
    Object? partyId = _notProvided,
    Object? accountId = _notProvided,
    Object? relatedAccountId = _notProvided,
    Object? dueDate = _notProvided,
    Object? description = _notProvided,
    Object? referenceId = _notProvided,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      partyId:
          identical(partyId, _notProvided) ? this.partyId : partyId as String?,
      accountId: identical(accountId, _notProvided)
          ? this.accountId
          : accountId as String?,
      relatedAccountId: identical(relatedAccountId, _notProvided)
          ? this.relatedAccountId
          : relatedAccountId as String?,
      dueDate: identical(dueDate, _notProvided)
          ? this.dueDate
          : dueDate as DateTime?,
      description: identical(description, _notProvided)
          ? this.description
          : description as String?,
      referenceId: identical(referenceId, _notProvided)
          ? this.referenceId
          : referenceId as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'amount': amount,
        'occurredAt': occurredAt.toIso8601String(),
        'partyId': partyId,
        'accountId': accountId,
        'relatedAccountId': relatedAccountId,
        'dueDate': dueDate?.toIso8601String(),
        'description': description,
        'referenceId': referenceId,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id'].toString(),
        type: _enumFromName(LedgerType.values, json['type']),
        amount: _intFromJson(json['amount']),
        occurredAt: _dateFromJson(json['occurredAt']),
        partyId: _nullableString(json['partyId']),
        accountId: _nullableString(json['accountId']),
        relatedAccountId: _nullableString(json['relatedAccountId']),
        dueDate: _nullableDateFromJson(json['dueDate']),
        description: _nullableString(json['description']),
        referenceId: _nullableString(json['referenceId']),
      );
}

class FinancialAccount {
  const FinancialAccount({
    required this.id,
    required this.name,
    required this.createdAt,
    this.openingBalance = 0,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final int openingBalance;
  final DateTime createdAt;
  final bool isArchived;

  FinancialAccount copyWith({
    String? id,
    String? name,
    int? openingBalance,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return FinancialAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'openingBalance': openingBalance,
        'createdAt': createdAt.toIso8601String(),
        'isArchived': isArchived,
      };

  factory FinancialAccount.fromJson(Map<String, dynamic> json) =>
      FinancialAccount(
        id: json['id'].toString(),
        name: json['name'].toString(),
        openingBalance: _intFromJson(json['openingBalance']),
        createdAt: _dateFromJson(json['createdAt']),
        isArchived: json['isArchived'] == true,
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sku,
    this.barcode,
    this.salePrice = 0,
    this.costPrice = 0,
    this.minimumStock = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final int salePrice;
  final int costPrice;
  final int minimumStock;
  final DateTime createdAt;
  final bool isActive;

  Product copyWith({
    String? id,
    String? name,
    Object? sku = _notProvided,
    Object? barcode = _notProvided,
    int? salePrice,
    int? costPrice,
    int? minimumStock,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: identical(sku, _notProvided) ? this.sku : sku as String?,
      barcode:
          identical(barcode, _notProvided) ? this.barcode : barcode as String?,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      minimumStock: minimumStock ?? this.minimumStock,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'salePrice': salePrice,
        'costPrice': costPrice,
        'minimumStock': minimumStock,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'].toString(),
        name: json['name'].toString(),
        sku: _nullableString(json['sku']),
        barcode: _nullableString(json['barcode']),
        salePrice: _intFromJson(json['salePrice']),
        costPrice: _intFromJson(json['costPrice']),
        minimumStock: _intFromJson(json['minimumStock']),
        createdAt: _dateFromJson(json['createdAt']),
        isActive: json['isActive'] != false,
      );
}

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.quantityDelta,
    required this.unitCost,
    required this.occurredAt,
    required this.reason,
    this.referenceId,
  });

  final String id;
  final String productId;

  /// Positive for stock received and negative for stock sold.
  final int quantityDelta;
  final int unitCost;
  final DateTime occurredAt;
  final String reason;
  final String? referenceId;

  int get quantity => quantityDelta;
  DateTime get date => occurredAt;

  InventoryMovement copyWith({
    String? id,
    String? productId,
    int? quantityDelta,
    int? unitCost,
    DateTime? occurredAt,
    String? reason,
    Object? referenceId = _notProvided,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      unitCost: unitCost ?? this.unitCost,
      occurredAt: occurredAt ?? this.occurredAt,
      reason: reason ?? this.reason,
      referenceId: identical(referenceId, _notProvided)
          ? this.referenceId
          : referenceId as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'productId': productId,
        'quantityDelta': quantityDelta,
        'unitCost': unitCost,
        'occurredAt': occurredAt.toIso8601String(),
        'reason': reason,
        'referenceId': referenceId,
      };

  factory InventoryMovement.fromJson(Map<String, dynamic> json) =>
      InventoryMovement(
        id: json['id'].toString(),
        productId: json['productId'].toString(),
        quantityDelta: _intFromJson(json['quantityDelta']),
        unitCost: _intFromJson(json['unitCost']),
        occurredAt: _dateFromJson(json['occurredAt']),
        reason: json['reason']?.toString() ?? '',
        referenceId: _nullableString(json['referenceId']),
      );
}

class SaleLine {
  const SaleLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.productName = '',
    this.unitCost = 0,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int unitCost;

  int get lineTotal => quantity * unitPrice;
  int get total => lineTotal;
  int get costTotal => quantity * unitCost;
  int get profit => lineTotal - costTotal;

  SaleLine copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? unitCost,
  }) {
    return SaleLine(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unitCost': unitCost,
      };

  factory SaleLine.fromJson(Map<String, dynamic> json) => SaleLine(
        productId: json['productId'].toString(),
        productName: json['productName']?.toString() ?? '',
        quantity: _intFromJson(json['quantity']),
        unitPrice: _intFromJson(json['unitPrice']),
        unitCost: _intFromJson(json['unitCost']),
      );
}

class SaleRecord {
  SaleRecord({
    required this.id,
    required List<SaleLine> lines,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    this.accountId,
    this.customerId,
    this.dueDate,
    this.note,
  }) : lines = List<SaleLine>.unmodifiable(lines);

  final String id;
  final List<SaleLine> lines;
  final PaymentMethod paymentMethod;
  final int totalAmount;
  final String? accountId;
  final String? customerId;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;

  int get costAmount =>
      lines.fold<int>(0, (total, line) => total + line.costTotal);
  int get profit => totalAmount - costAmount;

  SaleRecord copyWith({
    String? id,
    List<SaleLine>? lines,
    PaymentMethod? paymentMethod,
    int? totalAmount,
    Object? accountId = _notProvided,
    Object? customerId = _notProvided,
    Object? dueDate = _notProvided,
    Object? note = _notProvided,
    DateTime? createdAt,
  }) {
    return SaleRecord(
      id: id ?? this.id,
      lines: lines ?? this.lines,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      accountId: identical(accountId, _notProvided)
          ? this.accountId
          : accountId as String?,
      customerId: identical(customerId, _notProvided)
          ? this.customerId
          : customerId as String?,
      dueDate: identical(dueDate, _notProvided)
          ? this.dueDate
          : dueDate as DateTime?,
      note: identical(note, _notProvided) ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'lines': lines.map((line) => line.toJson()).toList(),
        'paymentMethod': paymentMethod.name,
        'totalAmount': totalAmount,
        'accountId': accountId,
        'customerId': customerId,
        'dueDate': dueDate?.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) => SaleRecord(
        id: json['id'].toString(),
        lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => SaleLine.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
        paymentMethod:
            _enumFromName(PaymentMethod.values, json['paymentMethod']),
        totalAmount: _intFromJson(json['totalAmount']),
        accountId: _nullableString(json['accountId']),
        customerId: _nullableString(json['customerId']),
        dueDate: _nullableDateFromJson(json['dueDate']),
        note: _nullableString(json['note']),
        createdAt: _dateFromJson(json['createdAt']),
      );
}

class AppData {
  AppData({
    this.mode,
    List<PartyRecord> parties = const <PartyRecord>[],
    List<LedgerEntry> ledgerEntries = const <LedgerEntry>[],
    List<FinancialAccount> accounts = const <FinancialAccount>[],
    List<Product> products = const <Product>[],
    List<InventoryMovement> inventoryMovements = const <InventoryMovement>[],
    List<SaleRecord> sales = const <SaleRecord>[],
  })  : parties = List<PartyRecord>.unmodifiable(parties),
        ledgerEntries = List<LedgerEntry>.unmodifiable(ledgerEntries),
        accounts = List<FinancialAccount>.unmodifiable(accounts),
        products = List<Product>.unmodifiable(products),
        inventoryMovements =
            List<InventoryMovement>.unmodifiable(inventoryMovements),
        sales = List<SaleRecord>.unmodifiable(sales);

  static const int schemaVersion = 1;
  static const String defaultCashAccountId = 'account-cash';

  final AppMode? mode;
  final List<PartyRecord> parties;
  final List<LedgerEntry> ledgerEntries;
  final List<FinancialAccount> accounts;
  final List<Product> products;
  final List<InventoryMovement> inventoryMovements;
  final List<SaleRecord> sales;

  factory AppData.initial({DateTime? now}) {
    final createdAt = now ?? DateTime.now();
    return AppData(
      accounts: <FinancialAccount>[
        FinancialAccount(
          id: defaultCashAccountId,
          name: 'الصندوق',
          createdAt: createdAt,
        ),
      ],
    );
  }

  AppData copyWith({
    Object? mode = _notProvided,
    List<PartyRecord>? parties,
    List<LedgerEntry>? ledgerEntries,
    List<FinancialAccount>? accounts,
    List<Product>? products,
    List<InventoryMovement>? inventoryMovements,
    List<SaleRecord>? sales,
  }) {
    return AppData(
      mode: identical(mode, _notProvided) ? this.mode : mode as AppMode?,
      parties: parties ?? this.parties,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      accounts: accounts ?? this.accounts,
      products: products ?? this.products,
      inventoryMovements: inventoryMovements ?? this.inventoryMovements,
      sales: sales ?? this.sales,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'mode': mode?.name,
        'parties': parties.map((party) => party.toJson()).toList(),
        'ledgerEntries': ledgerEntries.map((entry) => entry.toJson()).toList(),
        'accounts': accounts.map((account) => account.toJson()).toList(),
        'products': products.map((product) => product.toJson()).toList(),
        'inventoryMovements':
            inventoryMovements.map((movement) => movement.toJson()).toList(),
        'sales': sales.map((sale) => sale.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) {
    List<T> decodeList<T>(
      String key,
      T Function(Map<String, dynamic>) decode,
    ) {
      return (json[key] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => decode(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    final rawMode = json['mode'];
    return AppData(
      mode: rawMode == null ? null : _enumFromName(AppMode.values, rawMode),
      parties: decodeList('parties', PartyRecord.fromJson),
      ledgerEntries: decodeList('ledgerEntries', LedgerEntry.fromJson),
      accounts: decodeList('accounts', FinancialAccount.fromJson),
      products: decodeList('products', Product.fromJson),
      inventoryMovements:
          decodeList('inventoryMovements', InventoryMovement.fromJson),
      sales: decodeList('sales', SaleRecord.fromJson),
    );
  }
}
