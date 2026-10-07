import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaseer/data/local_store.dart';
import 'package:yaseer/domain/models.dart';
import 'package:yaseer/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cashAccountId = AppData.defaultCashAccountId;
  final now = DateTime(2026, 10, 6, 12);

  late LocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    store = LocalStore(preferences: preferences);
  });

  Future<AppController> createController() => AppController.create(
        store: store,
        clock: () => now,
      );

  group('initialization and persistence', () {
    test('starts with only the cash account and no mock transactions',
        () async {
      final controller = await createController();

      expect(controller.isInitialized, isTrue);
      expect(controller.mode, isNull);
      expect(controller.accounts, hasLength(1));
      expect(controller.accounts.single.id, cashAccountId);
      expect(controller.accounts.single.name, 'الصندوق');
      expect(controller.accountBalance(cashAccountId), 0);
      expect(controller.parties, isEmpty);
      expect(controller.ledgerEntries, isEmpty);
      expect(controller.products, isEmpty);
      expect(controller.inventoryMovements, isEmpty);
      expect(controller.sales, isEmpty);

      final persisted = await store.load();
      expect(persisted, isNotNull);
      expect(persisted!.accounts.single.id, cashAccountId);
      expect(persisted.ledgerEntries, isEmpty);
      expect(persisted.sales, isEmpty);
    });

    test('saves the selected mode and restores it through LocalStore',
        () async {
      final controller = await createController();

      await controller.selectMode(AppMode.professional);

      expect((await store.load())?.mode, AppMode.professional);

      final restored = await createController();
      expect(restored.mode, AppMode.professional);
      expect(restored.accounts.single.id, cashAccountId);
    });
  });

  group('debts and payments', () {
    test('customer debt and partial payment update debt and cash balances',
        () async {
      final controller = await createController();
      final customer = await controller.addParty(
        name: 'عميل الاختبار',
        kind: PartyKind.customer,
      );

      final debt = await controller.recordCustomerDebt(
        customerId: customer.id,
        amount: 1000,
      );
      final payment = await controller.recordCustomerPayment(
        customerId: customer.id,
        amount: 400,
      );

      expect(debt.type, LedgerType.customerDebt);
      expect(payment.type, LedgerType.customerPayment);
      expect(payment.accountId, cashAccountId);
      expect(controller.customerBalance(customer.id), 600);
      expect(controller.partyBalance(customer.id), 600);
      expect(controller.totalCustomerDebt, 600);
      expect(controller.outstandingDebt(debt.id), 600);
      expect(controller.accountBalance(cashAccountId), 400);
    });

    test('rejects a customer payment larger than the outstanding balance',
        () async {
      final controller = await createController();
      final customer = await controller.addParty(
        name: 'عميل',
        kind: PartyKind.customer,
      );
      await controller.recordCustomerDebt(
        customerId: customer.id,
        amount: 300,
      );

      await expectLater(
        controller.recordCustomerPayment(
          customerId: customer.id,
          amount: 301,
        ),
        throwsA(isA<StateError>()),
      );

      expect(controller.customerBalance(customer.id), 300);
      expect(controller.accountBalance(cashAccountId), 0);
      expect(controller.ledgerEntries, hasLength(1));
    });

    test('supplier debt and payment update supplier and cash balances',
        () async {
      final controller = await createController();
      final supplier = await controller.addParty(
        name: 'مورد الاختبار',
        kind: PartyKind.supplier,
      );

      final debt = await controller.recordSupplierDebt(
        supplierId: supplier.id,
        amount: 900,
      );
      final payment = await controller.recordSupplierPayment(
        supplierId: supplier.id,
        amount: 250,
      );

      expect(debt.type, LedgerType.supplierDebt);
      expect(payment.type, LedgerType.supplierPayment);
      expect(payment.accountId, cashAccountId);
      expect(controller.supplierBalance(supplier.id), 650);
      expect(controller.totalSupplierDebt, 650);
      expect(controller.outstandingDebt(debt.id), 650);
      expect(controller.accountBalance(cashAccountId), -250);
    });
  });

  test('a transfer preserves the total balance across accounts', () async {
    final controller = await createController();
    final bank = await controller.addAccount(
      name: 'البنك',
      openingBalance: 400,
    );
    final totalBefore = controller.accountBalances.values
        .fold<int>(0, (total, balance) => total + balance);

    await controller.transfer(
      fromAccountId: bank.id,
      toAccountId: cashAccountId,
      amount: 150,
    );

    final totalAfter = controller.accountBalances.values
        .fold<int>(0, (total, balance) => total + balance);
    final transferEntries = controller.ledgerEntries;
    expect(controller.accountBalance(bank.id), 250);
    expect(controller.accountBalance(cashAccountId), 150);
    expect(totalAfter, totalBefore);
    expect(transferEntries, hasLength(2));
    expect(
      transferEntries.map((entry) => entry.type),
      containsAll(<LedgerType>[
        LedgerType.transferOut,
        LedgerType.transferIn,
      ]),
    );
    expect(transferEntries.first.referenceId, transferEntries.last.referenceId);
  });

  group('inventory and sales', () {
    test('restocking and a cash sale update stock, cash, and profit', () async {
      final controller = await createController();
      final product = await controller.addProduct(
        name: 'منتج',
        salePrice: 30,
        costPrice: 10,
        initialStock: 4,
      );

      await controller.restockProduct(
        productId: product.id,
        quantity: 6,
        unitCost: 20,
      );
      final restockedProduct = controller.productById(product.id)!;
      expect(restockedProduct.costPrice, 16);
      expect(controller.stockForProduct(product.id), 10);

      final sale = await controller.checkoutSale(
        lines: <SaleLine>[
          SaleLine(productId: product.id, quantity: 3, unitPrice: 30),
        ],
        paymentMethod: PaymentMethod.cash,
      );

      expect(sale.totalAmount, 90);
      expect(sale.costAmount, 48);
      expect(sale.profit, 42);
      expect(sale.accountId, cashAccountId);
      expect(controller.stockForProduct(product.id), 7);
      expect(controller.accountBalance(cashAccountId), 90);
      expect(controller.todaySalesAmount, 90);
      expect(controller.todayCostOfGoodsAmount, 48);
      expect(controller.todayProfitAmount, 42);
      expect(controller.inventoryValue, 112);
      expect(controller.ledgerEntries.single.type, LedgerType.cashSale);
    });

    test('a credit sale increases customer debt without increasing cash',
        () async {
      final controller = await createController();
      final customer = await controller.addParty(
        name: 'عميل آجل',
        kind: PartyKind.customer,
      );
      final product = await controller.addProduct(
        name: 'صنف آجل',
        costPrice: 5,
        salePrice: 15,
        initialStock: 5,
      );

      final sale = await controller.checkoutSale(
        lines: <SaleLine>[
          SaleLine(productId: product.id, quantity: 2, unitPrice: 15),
        ],
        paymentMethod: PaymentMethod.credit,
        customerId: customer.id,
      );

      expect(sale.totalAmount, 30);
      expect(sale.customerId, customer.id);
      expect(sale.accountId, isNull);
      expect(controller.customerBalance(customer.id), 30);
      expect(controller.accountBalance(cashAccountId), 0);
      expect(controller.stockForProduct(product.id), 3);
      expect(controller.ledgerEntries.single.type, LedgerType.creditSale);
    });

    test('rejects a sale that would make product stock negative', () async {
      final controller = await createController();
      final product = await controller.addProduct(
        name: 'مخزون محدود',
        salePrice: 25,
        costPrice: 10,
        initialStock: 2,
      );

      await expectLater(
        controller.checkoutSale(
          lines: <SaleLine>[
            SaleLine(productId: product.id, quantity: 3, unitPrice: 25),
          ],
          paymentMethod: PaymentMethod.cash,
        ),
        throwsA(isA<StateError>()),
      );

      expect(controller.stockForProduct(product.id), 2);
      expect(controller.sales, isEmpty);
      expect(controller.ledgerEntries, isEmpty);
      expect(controller.accountBalance(cashAccountId), 0);
    });
  });
}
