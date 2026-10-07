import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../shared/widgets.dart';
import '../../state/app_controller.dart';

const _successColor = Color(0xFF198754);
const _warningColor = Color(0xFFD98310);
const _dangerColor = Color(0xFFC43D4B);
const _infoColor = Color(0xFF2B6CB0);
const _proColor = Color(0xFFF4B740);

String _formatNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '${negative ? '-' : ''}$buffer';
}

String _formatMoney(int value) => '${_formatNumber(value)} ر.س';

String _shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _saleTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour >= 12 ? 'م' : 'ص'}';
}

void _showMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: error ? _dangerColor : const Color(0xFF125E55),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.child, this.maxWidth = 1240});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 540
                ? 2
                : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Professional dashboard
// ---------------------------------------------------------------------------

class ProfessionalDashboardPage extends StatelessWidget {
  const ProfessionalDashboardPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final products = controller.products;
        final stocks = controller.productStocks;
        final lowStockProducts = products.where((product) {
          final stock = stocks[product.id] ?? 0;
          return product.isActive && stock <= product.minimumStock;
        }).toList()
          ..sort((a, b) {
            final first = stocks[a.id] ?? 0;
            final second = stocks[b.id] ?? 0;
            return first.compareTo(second);
          });
        final recentSales = controller.sales.reversed.take(5).toList();
        final now = DateTime.now();

        return _PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'صباح الإنجاز 👋',
                subtitle: 'ملخص متجرك اليوم • ${_shortDate(now)}',
                actions: const [
                  StatusChip(
                    label: 'الوضع الاحترافي',
                    tone: YaseerStatusTone.pro,
                    icon: Icons.workspace_premium_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _TodayHero(
                sales: controller.todaySalesAmount,
                profit: controller.todayProfitAmount,
                transactions: controller.sales
                    .where((sale) =>
                        sale.createdAt.year == now.year &&
                        sale.createdAt.month == now.month &&
                        sale.createdAt.day == now.day)
                    .length,
              ),
              const SizedBox(height: 16),
              _MetricGrid(
                children: [
                  MetricCard(
                    label: 'مبيعات اليوم',
                    value: _formatMoney(controller.todaySalesAmount),
                    icon: Icons.point_of_sale_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    caption: 'إجمالي المبيعات المسجلة اليوم',
                    highlighted: true,
                  ),
                  MetricCard(
                    label: 'ربح اليوم',
                    value: _formatMoney(controller.todayProfitAmount),
                    icon: Icons.trending_up_rounded,
                    color: _successColor,
                    caption: 'بعد خصم تكلفة الأصناف',
                  ),
                  MetricCard(
                    label: 'مصروف اليوم',
                    value: _formatMoney(controller.todayExpenseAmount),
                    icon: Icons.payments_outlined,
                    color: _dangerColor,
                    caption: 'المصروفات المسجلة اليوم',
                  ),
                  MetricCard(
                    label: 'قيمة المخزون',
                    value: _formatMoney(controller.inventoryValue),
                    icon: Icons.inventory_2_outlined,
                    color: _infoColor,
                    caption: '${products.length} صنف في الكتالوج',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 840;
                  final alerts = _StockAlertsCard(
                    products: lowStockProducts,
                    stocks: stocks,
                  );
                  final sales = _RecentSalesCard(sales: recentSales);
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [alerts, const SizedBox(height: 16), sales],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: alerts),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: sales),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.sales,
    required this.profit,
    required this.transactions,
  });

  final int sales;
  final int profit;
  final int transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0F766E), Color(0xFF083F3B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240B4F4A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final amount = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجمالي حركة اليوم',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .74),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _formatMoney(sales),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
          final details = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(
                icon: Icons.receipt_long_rounded,
                label: '$transactions عملية بيع',
              ),
              _HeroStat(
                icon: Icons.auto_graph_rounded,
                label: 'ربح ${_formatMoney(profit)}',
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [amount, const SizedBox(height: 18), details],
            );
          }
          return Row(
            children: [
              Expanded(child: amount),
              const SizedBox(width: 24),
              details,
            ],
          );
        },
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _proColor, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertsCard extends StatelessWidget {
  const _StockAlertsCard({required this.products, required this.stocks});

  final List<Product> products;
  final Map<String, int> stocks;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'تنبيهات المخزون',
      subtitle: products.isEmpty
          ? 'كل الأصناف ضمن الحد الآمن'
          : '${products.length} صنف يحتاج انتباهك',
      trailing: StatusChip(
        label: products.isEmpty ? 'ممتاز' : '${products.length}',
        tone: products.isEmpty
            ? YaseerStatusTone.success
            : YaseerStatusTone.warning,
        icon: products.isEmpty
            ? Icons.check_rounded
            : Icons.notifications_active_outlined,
      ),
      child: products.isEmpty
          ? const _CompactEmpty(
              icon: Icons.inventory_rounded,
              title: 'مخزونك بحالة جيدة',
              subtitle: 'لا توجد أصناف منخفضة أو نافدة الآن.',
            )
          : Column(
              children: [
                for (var index = 0;
                    index < products.length && index < 5;
                    index++) ...[
                  _StockAlertRow(
                    product: products[index],
                    stock: stocks[products[index].id] ?? 0,
                  ),
                  if (index < products.length - 1 && index < 4)
                    const Divider(height: 18),
                ],
                if (products.length > 5) ...[
                  const Divider(height: 18),
                  Text(
                    'و${products.length - 5} أصناف أخرى',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StockAlertRow extends StatelessWidget {
  const _StockAlertRow({required this.product, required this.stock});

  final Product product;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final out = stock <= 0;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (out ? _dangerColor : _warningColor).withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            out
                ? Icons.remove_shopping_cart_outlined
                : Icons.inventory_outlined,
            color: out ? _dangerColor : _warningColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'الحد الأدنى ${product.minimumStock}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .58),
                    ),
              ),
            ],
          ),
        ),
        StatusChip(
          label: out ? 'نفد' : 'متبقي $stock',
          tone: out ? YaseerStatusTone.danger : YaseerStatusTone.warning,
        ),
      ],
    );
  }
}

class _RecentSalesCard extends StatelessWidget {
  const _RecentSalesCard({required this.sales});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'أحدث المبيعات',
      subtitle: 'آخر العمليات المحفوظة على جهازك',
      trailing:
          sales.isEmpty ? null : StatusChip(label: '${sales.length} أخيرة'),
      child: sales.isEmpty
          ? const _CompactEmpty(
              icon: Icons.point_of_sale_outlined,
              title: 'لا توجد مبيعات بعد',
              subtitle: 'ستظهر هنا أحدث عمليات نقطة البيع.',
            )
          : Column(
              children: [
                for (var index = 0; index < sales.length; index++) ...[
                  _SaleRow(sale: sales[index]),
                  if (index != sales.length - 1) const Divider(height: 20),
                ],
              ],
            ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    final cash = sale.paymentMethod == PaymentMethod.cash;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (cash ? _successColor : _infoColor).withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            cash ? Icons.payments_outlined : Icons.schedule_rounded,
            color: cash ? _successColor : _infoColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sale.lines.length} صنف • ${cash ? 'نقدي' : 'آجل'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${_shortDate(sale.createdAt)}، ${_saleTime(sale.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .56),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        MoneyText(amount: sale.totalAmount, decimalDigits: 0),
      ],
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .55),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .58),
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Point of sale
// ---------------------------------------------------------------------------

class PosPage extends StatefulWidget {
  const PosPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _searchController = TextEditingController();
  final Map<String, int> _cart = <String, int>{};
  String _query = '';
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _accountId;
  String? _customerId;
  DateTime? _dueDate;
  bool _checkingOut = false;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _setInitialSelections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setInitialSelections() {
    final accounts =
        controller.accounts.where((item) => !item.isArchived).toList();
    final customers = controller.parties
        .where((item) => item.kind == PartyKind.customer)
        .toList();
    if (!accounts.any((account) => account.id == _accountId)) {
      _accountId = accounts.isEmpty ? null : accounts.first.id;
    }
    if (!customers.any((customer) => customer.id == _customerId)) {
      _customerId = customers.isEmpty ? null : customers.first.id;
    }
  }

  List<Product> _filteredProducts() {
    final normalized = _query.trim().toLowerCase();
    return controller.products.where((product) {
      if (!product.isActive) return false;
      if (normalized.isEmpty) return true;
      return product.name.toLowerCase().contains(normalized) ||
          (product.sku?.toLowerCase().contains(normalized) ?? false) ||
          (product.barcode?.toLowerCase().contains(normalized) ?? false);
    }).toList();
  }

  List<SaleLine> _cartLines() {
    final productsById = <String, Product>{
      for (final product in controller.products) product.id: product,
    };
    return _cart.entries
        .where(
            (entry) => entry.value > 0 && productsById.containsKey(entry.key))
        .map((entry) {
      final product = productsById[entry.key]!;
      return SaleLine(
        productId: product.id,
        productName: product.name,
        quantity: entry.value,
        unitPrice: product.salePrice,
        unitCost: product.costPrice,
      );
    }).toList();
  }

  int get _cartCount =>
      _cart.values.fold<int>(0, (total, quantity) => total + quantity);

  int get _cartTotal => _cartLines().fold<int>(
        0,
        (total, line) => total + line.lineTotal,
      );

  void _addProduct(Product product) {
    final stock = controller.productStocks[product.id] ?? 0;
    final current = _cart[product.id] ?? 0;
    if (stock <= 0) {
      _showMessage(context, 'نفد مخزون ${product.name}', error: true);
      return;
    }
    if (current >= stock) {
      _showMessage(
        context,
        'الكمية المتوفرة من ${product.name} هي $stock فقط',
        error: true,
      );
      return;
    }
    setState(() => _cart[product.id] = current + 1);
  }

  void _changeQuantity(Product product, int quantity) {
    final stock = controller.productStocks[product.id] ?? 0;
    if (quantity <= 0) {
      setState(() => _cart.remove(product.id));
      return;
    }
    if (quantity > stock) {
      _showMessage(
        context,
        'لا يمكن تجاوز المخزون المتوفر ($stock)',
        error: true,
      );
      return;
    }
    setState(() => _cart[product.id] = quantity);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'موعد سداد البيع الآجل',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (selected != null && mounted) setState(() => _dueDate = selected);
  }

  Future<void> _checkout() async {
    final lines = _cartLines();
    if (lines.isEmpty) {
      _showMessage(context, 'أضف صنفًا واحدًا على الأقل للسلة', error: true);
      return;
    }

    for (final line in lines) {
      final stock = controller.productStocks[line.productId] ?? 0;
      if (line.quantity > stock) {
        _showMessage(
          context,
          'تغيّر مخزون ${line.productName}؛ المتوفر الآن $stock',
          error: true,
        );
        return;
      }
    }

    if (_paymentMethod == PaymentMethod.cash && _accountId == null) {
      _showMessage(context, 'اختر الحساب الذي استلم المبلغ', error: true);
      return;
    }
    if (_paymentMethod == PaymentMethod.credit && _customerId == null) {
      _showMessage(context, 'اختر العميل للبيع الآجل', error: true);
      return;
    }

    final completedTotal = _cartTotal;
    setState(() => _checkingOut = true);
    try {
      await controller.checkoutSale(
        lines: lines,
        paymentMethod: _paymentMethod,
        accountId: _paymentMethod == PaymentMethod.cash ? _accountId : null,
        customerId: _paymentMethod == PaymentMethod.credit ? _customerId : null,
        dueDate: _paymentMethod == PaymentMethod.credit ? _dueDate : null,
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _checkingOut = false;
      });
      await _showSaleSuccess(completedTotal);
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingOut = false);
      _showMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _showSaleSuccess(int total) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F5ED),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: _successColor,
            size: 38,
          ),
        ),
        title: const Text('تم البيع بنجاح', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'حُفظت العملية وخُصمت الكميات من المخزون.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _formatMoney(total),
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    color: _successColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('بيع جديد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        _setInitialSelections();
        final products = _filteredProducts();
        final cartLines = _cartLines();
        return _PageBody(
          maxWidth: 1380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'نقطة البيع',
                subtitle: 'اختر الأصناف، راجع السلة، ثم أكمل الدفع',
                actions: [
                  StatusChip(
                    label: _cartCount == 0
                        ? 'السلة فارغة'
                        : '$_cartCount في السلة',
                    tone: _cartCount == 0
                        ? YaseerStatusTone.neutral
                        : YaseerStatusTone.pro,
                    icon: Icons.shopping_cart_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 930;
                  final catalog = _CatalogPanel(
                    products: products,
                    stocks: controller.productStocks,
                    cart: _cart,
                    searchController: _searchController,
                    onSearch: (value) => setState(() => _query = value),
                    onAdd: _addProduct,
                  );
                  final checkout = _CheckoutPanel(
                    lines: cartLines,
                    products: controller.products,
                    total: _cartTotal,
                    paymentMethod: _paymentMethod,
                    accounts: controller.accounts
                        .where((account) => !account.isArchived)
                        .toList(),
                    customers: controller.parties
                        .where((party) => party.kind == PartyKind.customer)
                        .toList(),
                    accountId: _accountId,
                    customerId: _customerId,
                    dueDate: _dueDate,
                    busy: _checkingOut,
                    onQuantityChanged: _changeQuantity,
                    onPaymentChanged: (value) =>
                        setState(() => _paymentMethod = value),
                    onAccountChanged: (value) =>
                        setState(() => _accountId = value),
                    onCustomerChanged: (value) =>
                        setState(() => _customerId = value),
                    onPickDueDate: _pickDueDate,
                    onCheckout: _checkout,
                    onClear: () => setState(_cart.clear),
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        catalog,
                        const SizedBox(height: 16),
                        checkout,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: catalog),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: checkout),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogPanel extends StatelessWidget {
  const _CatalogPanel({
    required this.products,
    required this.stocks,
    required this.cart,
    required this.searchController,
    required this.onSearch,
    required this.onAdd,
  });

  final List<Product> products;
  final Map<String, int> stocks;
  final Map<String, int> cart;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'الأصناف',
      subtitle: '${products.length} صنف مطابق',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBox(
            controller: searchController,
            hintText: 'ابحث بالاسم أو الرمز أو الباركود…',
            onChanged: onSearch,
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const EmptyState(
              title: 'لا توجد أصناف مطابقة',
              description: 'جرّب كلمة أخرى أو أضف أصنافًا من صفحة الأصناف.',
              icon: Icons.search_off_rounded,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760
                    ? 3
                    : constraints.maxWidth >= 430
                        ? 2
                        : 1;
                const gap = 10.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final product in products)
                      SizedBox(
                        width: width,
                        child: _PosProductCard(
                          product: product,
                          stock: stocks[product.id] ?? 0,
                          cartQuantity: cart[product.id] ?? 0,
                          onAdd: () => onAdd(product),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PosProductCard extends StatelessWidget {
  const _PosProductCard({
    required this.product,
    required this.stock,
    required this.cartQuantity,
    required this.onAdd,
  });

  final Product product;
  final int stock;
  final int cartQuantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final out = stock <= 0;
    return Material(
      color: out
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: .42)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cartQuantity > 0
              ? theme.colorScheme.primary.withValues(alpha: .5)
              : theme.colorScheme.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: out ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (cartQuantity > 0)
                    StatusChip(
                      label: '$cartQuantity بالسلة',
                      tone: YaseerStatusTone.pro,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (product.sku != null) ...[
                const SizedBox(height: 2),
                Text(
                  product.sku!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .52),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MoneyText(
                      amount: product.salePrice,
                      decimalDigits: 0,
                    ),
                  ),
                  StatusChip(
                    label: out ? 'نفد' : '$stock متوفر',
                    tone: out
                        ? YaseerStatusTone.danger
                        : stock <= product.minimumStock
                            ? YaseerStatusTone.warning
                            : YaseerStatusTone.success,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  onPressed: out ? null : onAdd,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 19),
                  label: Text(out ? 'غير متوفر' : 'أضف للسلة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({
    required this.lines,
    required this.products,
    required this.total,
    required this.paymentMethod,
    required this.accounts,
    required this.customers,
    required this.accountId,
    required this.customerId,
    required this.dueDate,
    required this.busy,
    required this.onQuantityChanged,
    required this.onPaymentChanged,
    required this.onAccountChanged,
    required this.onCustomerChanged,
    required this.onPickDueDate,
    required this.onCheckout,
    required this.onClear,
  });

  final List<SaleLine> lines;
  final List<Product> products;
  final int total;
  final PaymentMethod paymentMethod;
  final List<FinancialAccount> accounts;
  final List<PartyRecord> customers;
  final String? accountId;
  final String? customerId;
  final DateTime? dueDate;
  final bool busy;
  final void Function(Product product, int quantity) onQuantityChanged;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onPickDueDate;
  final VoidCallback onCheckout;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final byId = <String, Product>{for (final item in products) item.id: item};
    final theme = Theme.of(context);
    return SectionCard(
      title: 'سلة البيع',
      subtitle: lines.isEmpty
          ? 'اختر صنفًا لتبدأ'
          : '${lines.fold<int>(0, (sum, line) => sum + line.quantity)} قطعة',
      trailing: lines.isEmpty
          ? null
          : IconButton(
              tooltip: 'تفريغ السلة',
              onPressed: busy ? null : onClear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lines.isEmpty)
            const _CompactEmpty(
              icon: Icons.shopping_cart_outlined,
              title: 'السلة فارغة',
              subtitle: 'اضغط على أي صنف لإضافته.',
            )
          else ...[
            for (var index = 0; index < lines.length; index++) ...[
              _CartLineRow(
                line: lines[index],
                product: byId[lines[index].productId]!,
                onChanged: (quantity) => onQuantityChanged(
                  byId[lines[index].productId]!,
                  quantity,
                ),
              ),
              if (index != lines.length - 1) const Divider(height: 20),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text('الإجمالي', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  MoneyText(
                    amount: total,
                    decimalDigits: 0,
                    color: theme.colorScheme.primary,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('طريقة الدفع', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text('نقدي'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: PaymentMethod.credit,
                label: Text('آجل'),
                icon: Icon(Icons.schedule_rounded),
              ),
            ],
            selected: {paymentMethod},
            showSelectedIcon: false,
            onSelectionChanged:
                busy ? null : (selection) => onPaymentChanged(selection.first),
          ),
          const SizedBox(height: 14),
          if (paymentMethod == PaymentMethod.cash)
            DropdownButtonFormField<String>(
              key: ValueKey('cash-account-$accountId'),
              initialValue: accounts.any((item) => item.id == accountId)
                  ? accountId
                  : null,
              decoration: const InputDecoration(
                labelText: 'الحساب المستلم',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: [
                for (final account in accounts)
                  DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  ),
              ],
              onChanged: busy ? null : onAccountChanged,
            )
          else ...[
            DropdownButtonFormField<String>(
              key: ValueKey('credit-customer-$customerId'),
              initialValue: customers.any((item) => item.id == customerId)
                  ? customerId
                  : null,
              decoration: const InputDecoration(
                labelText: 'العميل',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              hint: const Text('اختر العميل'),
              items: [
                for (final customer in customers)
                  DropdownMenuItem(
                    value: customer.id,
                    child: Text(customer.name),
                  ),
              ],
              onChanged: busy ? null : onCustomerChanged,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy ? null : onPickDueDate,
              icon: const Icon(Icons.event_outlined),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  dueDate == null
                      ? 'إضافة موعد سداد (اختياري)'
                      : 'موعد السداد: ${_shortDate(dueDate!)}',
                ),
              ),
            ),
            if (customers.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'أضف عميلًا أولًا من قسم الديون لإتمام بيع آجل.',
                style: TextStyle(color: _dangerColor, fontSize: 12),
              ),
            ],
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: lines.isEmpty || busy ? null : onCheckout,
              icon: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                busy
                    ? 'جارٍ حفظ البيع…'
                    : 'إتمام البيع • ${_formatMoney(total)}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يحفظ البيع محليًا ويحدّث المخزون فورًا.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .56),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.product,
    required this.onChanged,
  });

  final SaleLine line;
  final Product product;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Text(
                '${_formatMoney(line.unitPrice)} × ${line.quantity} = ${_formatMoney(line.lineTotal)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .58),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _QuantityStepper(
          quantity: line.quantity,
          onMinus: () => onChanged(line.quantity - 1),
          onPlus: () => onChanged(line.quantity + 1),
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: quantity == 1 ? 'حذف' : 'إنقاص',
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: Icon(
              quantity == 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              size: 19,
              color: quantity == 1 ? _dangerColor : color,
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'زيادة',
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: Icon(Icons.add_rounded, size: 19, color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debts
// ---------------------------------------------------------------------------

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _balanceFor(String partyId) {
    return widget.controller.customerBalance(partyId);
  }

  DateTime? _lastActivityFor(String partyId) {
    DateTime? last;
    for (final entry in widget.controller.data.ledgerEntries) {
      if (entry.partyId != partyId) continue;
      if (last == null || entry.occurredAt.isAfter(last)) {
        last = entry.occurredAt;
      }
    }
    return last;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final query = _query.trim().toLowerCase();
        final customers = widget.controller.parties
            .where((party) =>
                party.kind == PartyKind.customer &&
                (query.isEmpty ||
                    party.name.toLowerCase().contains(query) ||
                    (party.phone?.contains(query) ?? false)))
            .toList()
          ..sort((a, b) => _balanceFor(b.id).compareTo(_balanceFor(a.id)));
        final allCustomers = widget.controller.parties
            .where((party) => party.kind == PartyKind.customer)
            .toList();
        final totalDebt = allCustomers.fold<int>(
          0,
          (total, party) {
            final balance = _balanceFor(party.id);
            return total + (balance > 0 ? balance : 0);
          },
        );
        final indebtedCount =
            allCustomers.where((party) => _balanceFor(party.id) > 0).length;
        final overdueCount = widget.controller.overdueDebtEntries
            .where(
              (entry) =>
                  entry.type == LedgerType.customerDebt ||
                  entry.type == LedgerType.creditSale,
            )
            .length;

        return _PageBody(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'ديون العملاء',
                subtitle:
                    'أرصدة العملاء الناتجة من الديون والمبيعات الآجلة والدفعات',
              ),
              const SizedBox(height: 20),
              _MetricGrid(
                children: [
                  MetricCard(
                    label: 'إجمالي المستحق',
                    value: _formatMoney(totalDebt),
                    icon: Icons.account_balance_wallet_outlined,
                    color: _dangerColor,
                    highlighted: totalDebt > 0,
                  ),
                  MetricCard(
                    label: 'عملاء عليهم رصيد',
                    value: '$indebtedCount',
                    icon: Icons.people_outline_rounded,
                    color: _warningColor,
                    caption: 'من أصل ${allCustomers.length} عميل',
                  ),
                  MetricCard(
                    label: 'مواعيد متأخرة',
                    value: '$overdueCount',
                    icon: Icons.event_busy_outlined,
                    color: _dangerColor,
                    caption: 'بحسب مواعيد المبيعات الآجلة',
                  ),
                  MetricCard(
                    label: 'حسابات مسددة',
                    value: '${allCustomers.length - indebtedCount}',
                    icon: Icons.verified_outlined,
                    color: _successColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'العملاء',
                subtitle: '${customers.length} نتيجة',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SearchBox(
                      controller: _searchController,
                      hintText: 'ابحث باسم العميل أو رقم الهاتف…',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 14),
                    if (customers.isEmpty)
                      EmptyState(
                        title: query.isEmpty
                            ? 'لا يوجد عملاء بعد'
                            : 'لا توجد نتائج مطابقة',
                        description: query.isEmpty
                            ? 'أضف عميلًا من الوضع الأساسي أو أثناء تجهيز بيانات متجرك.'
                            : 'غيّر عبارة البحث وحاول مرة أخرى.',
                        icon: query.isEmpty
                            ? Icons.people_outline_rounded
                            : Icons.search_off_rounded,
                      )
                    else
                      for (var index = 0;
                          index < customers.length;
                          index++) ...[
                        _CustomerDebtRow(
                          customer: customers[index],
                          balance: _balanceFor(customers[index].id),
                          lastActivity: _lastActivityFor(customers[index].id),
                        ),
                        if (index != customers.length - 1)
                          const Divider(height: 1),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerDebtRow extends StatelessWidget {
  const _CustomerDebtRow({
    required this.customer,
    required this.balance,
    required this.lastActivity,
  });

  final PartyRecord customer;
  final int balance;
  final DateTime? lastActivity;

  @override
  Widget build(BuildContext context) {
    final owes = balance > 0;
    final hasCredit = balance < 0;
    final color = owes
        ? _dangerColor
        : hasCredit
            ? _infoColor
            : _successColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: .1),
            foregroundColor: color,
            child: Text(
              customer.name.trim().isEmpty ? '؟' : customer.name.trim()[0],
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone ??
                      (lastActivity == null
                          ? 'لا توجد حركة بعد'
                          : 'آخر حركة ${_shortDate(lastActivity!)}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .56),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(balance.abs()),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                owes
                    ? 'عليه'
                    : hasCredit
                        ? 'له رصيد'
                        : 'مسدد',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Products and inventory
// ---------------------------------------------------------------------------

enum _StockFilter { all, available, low, out }

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _StockFilter _filter = _StockFilter.all;

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Product product) {
    final stock = controller.productStocks[product.id] ?? 0;
    return switch (_filter) {
      _StockFilter.all => true,
      _StockFilter.available => stock > product.minimumStock,
      _StockFilter.low => stock > 0 && stock <= product.minimumStock,
      _StockFilter.out => stock <= 0,
    };
  }

  List<Product> _filteredProducts() {
    final query = _query.trim().toLowerCase();
    return controller.products.where((product) {
      final textMatches = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.sku?.toLowerCase().contains(query) ?? false) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
      return product.isActive && textMatches && _matchesFilter(product);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _showAddProductDialog() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final sku = TextEditingController();
    final barcode = TextEditingController();
    final salePrice = TextEditingController();
    final costPrice = TextEditingController();
    final minimum = TextEditingController(text: '0');
    final initial = TextEditingController(text: '0');
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_box_outlined),
              SizedBox(width: 10),
              Text('إضافة صنف'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصنف *',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'اكتب اسم الصنف'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: salePrice,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'سعر البيع *',
                              suffixText: 'ر.س',
                            ),
                            validator: _positiveNumberValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: costPrice,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'سعر التكلفة *',
                              suffixText: 'ر.س',
                            ),
                            validator: _nonNegativeNumberValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: initial,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'المخزون الأولي',
                            ),
                            validator: _nonNegativeNumberValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: minimum,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'حد التنبيه',
                            ),
                            validator: _nonNegativeNumberValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sku,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'رمز الصنف (اختياري)',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: barcode,
                      decoration: const InputDecoration(
                        labelText: 'الباركود (اختياري)',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        await controller.addProduct(
                          name: name.text.trim(),
                          sku: _nullIfEmpty(sku.text),
                          barcode: _nullIfEmpty(barcode.text),
                          salePrice: int.parse(salePrice.text.trim()),
                          costPrice: int.parse(costPrice.text.trim()),
                          minimumStock: int.parse(minimum.text.trim()),
                          initialStock: int.parse(initial.text.trim()),
                        );
                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _showMessage(this.context, 'تمت إضافة الصنف');
                      } catch (error) {
                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                        _showMessage(this.context, error.toString(),
                            error: true);
                      }
                    },
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(saving ? 'جارٍ الحفظ…' : 'إضافة الصنف'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    sku.dispose();
    barcode.dispose();
    salePrice.dispose();
    costPrice.dispose();
    minimum.dispose();
    initial.dispose();
  }

  Future<void> _showRestockDialog(Product product) async {
    final formKey = GlobalKey<FormState>();
    final quantity = TextEditingController();
    final cost = TextEditingController(text: '${product.costPrice}');
    final note = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مخزون'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${product.name} • المتوفر ${controller.productStocks[product.id] ?? 0}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: quantity,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'الكمية المضافة *',
                      prefixIcon: Icon(Icons.add_box_outlined),
                    ),
                    validator: _positiveNumberValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cost,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'تكلفة الوحدة *',
                      suffixText: 'ر.س',
                    ),
                    validator: _nonNegativeNumberValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        await controller.restockProduct(
                          productId: product.id,
                          quantity: int.parse(quantity.text.trim()),
                          unitCost: int.parse(cost.text.trim()),
                          note: _nullIfEmpty(note.text),
                        );
                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _showMessage(this.context, 'تمت إضافة المخزون بنجاح');
                      } catch (error) {
                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                        _showMessage(this.context, error.toString(),
                            error: true);
                      }
                    },
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(saving ? 'جارٍ الحفظ…' : 'تأكيد الإضافة'),
            ),
          ],
        ),
      ),
    );

    quantity.dispose();
    cost.dispose();
    note.dispose();
  }

  static String? _positiveNumberValidator(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'أدخل رقمًا أكبر من صفر';
    return null;
  }

  static String? _nonNegativeNumberValidator(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) return 'أدخل صفرًا أو رقمًا موجبًا';
    return null;
  }

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final products = _filteredProducts();
        final all = controller.products.where((item) => item.isActive).toList();
        final lowCount = all.where((product) {
          final stock = controller.productStocks[product.id] ?? 0;
          return stock > 0 && stock <= product.minimumStock;
        }).length;
        final outCount = all
            .where(
                (product) => (controller.productStocks[product.id] ?? 0) <= 0)
            .length;
        final units = all.fold<int>(
          0,
          (sum, product) => sum + (controller.productStocks[product.id] ?? 0),
        );

        return _PageBody(
          maxWidth: 1180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'الأصناف والمخزون',
                subtitle: 'تابع الكميات وأضف الأصناف والتوريدات بسهولة',
                primaryAction: FilledButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('صنف جديد'),
                ),
              ),
              const SizedBox(height: 20),
              _MetricGrid(
                children: [
                  MetricCard(
                    label: 'إجمالي الأصناف',
                    value: '${all.length}',
                    icon: Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  MetricCard(
                    label: 'إجمالي الوحدات',
                    value: _formatNumber(units),
                    icon: Icons.inventory_2_outlined,
                    color: _infoColor,
                  ),
                  MetricCard(
                    label: 'مخزون منخفض',
                    value: '$lowCount',
                    icon: Icons.warning_amber_rounded,
                    color: _warningColor,
                  ),
                  MetricCard(
                    label: 'أصناف نافدة',
                    value: '$outCount',
                    icon: Icons.remove_shopping_cart_outlined,
                    color: _dangerColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'قائمة الأصناف',
                subtitle: '${products.length} نتيجة',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SearchBox(
                      controller: _searchController,
                      hintText: 'ابحث بالاسم أو الرمز أو الباركود…',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'الكل',
                            selected: _filter == _StockFilter.all,
                            onSelected: () =>
                                setState(() => _filter = _StockFilter.all),
                          ),
                          _FilterChip(
                            label: 'متوفر',
                            selected: _filter == _StockFilter.available,
                            onSelected: () => setState(
                              () => _filter = _StockFilter.available,
                            ),
                          ),
                          _FilterChip(
                            label: 'منخفض',
                            count: lowCount,
                            selected: _filter == _StockFilter.low,
                            color: _warningColor,
                            onSelected: () =>
                                setState(() => _filter = _StockFilter.low),
                          ),
                          _FilterChip(
                            label: 'نفد',
                            count: outCount,
                            selected: _filter == _StockFilter.out,
                            color: _dangerColor,
                            onSelected: () =>
                                setState(() => _filter = _StockFilter.out),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (products.isEmpty)
                      EmptyState(
                        title: all.isEmpty
                            ? 'أضف أول صنف لمتجرك'
                            : 'لا توجد أصناف مطابقة',
                        description: all.isEmpty
                            ? 'أدخل الاسم والسعر والكمية، وسيصبح جاهزًا للبيع فورًا.'
                            : 'غيّر البحث أو حالة المخزون.',
                        icon: all.isEmpty
                            ? Icons.inventory_2_outlined
                            : Icons.search_off_rounded,
                        actionLabel: all.isEmpty ? 'إضافة صنف' : null,
                        onAction: all.isEmpty ? _showAddProductDialog : null,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 920 ? 2 : 1;
                          const gap = 12.0;
                          final width =
                              (constraints.maxWidth - gap * (columns - 1)) /
                                  columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final product in products)
                                SizedBox(
                                  width: width,
                                  child: _InventoryProductCard(
                                    product: product,
                                    stock:
                                        controller.productStocks[product.id] ??
                                            0,
                                    onRestock: () =>
                                        _showRestockDialog(product),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final int? count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(count == null ? label : '$label ($count)'),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: .13),
        side: BorderSide(
          color: selected
              ? (color ?? Theme.of(context).colorScheme.primary)
              : Theme.of(context).colorScheme.outline,
        ),
        labelStyle: TextStyle(
          color: selected
              ? (color ?? Theme.of(context).colorScheme.primary)
              : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({
    required this.product,
    required this.stock,
    required this.onRestock,
  });

  final Product product;
  final int stock;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final out = stock <= 0;
    final low = !out && stock <= product.minimumStock;
    final color = out
        ? _dangerColor
        : low
            ? _warningColor
            : _successColor;
    final status = out
        ? 'نفد'
        : low
            ? 'منخفض'
            : 'متوفر';
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.inventory_2_outlined, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: status,
                        tone: out
                            ? YaseerStatusTone.danger
                            : low
                                ? YaseerStatusTone.warning
                                : YaseerStatusTone.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 12,
                    runSpacing: 3,
                    children: [
                      Text(
                        'المخزون: $stock',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'البيع: ${_formatMoney(product.salePrice)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'التكلفة: ${_formatMoney(product.costPrice)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (product.sku != null || product.barcode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [product.sku, product.barcode]
                          .whereType<String>()
                          .join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .5),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'إضافة مخزون',
              onPressed: onRestock,
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More
// ---------------------------------------------------------------------------

class ProfessionalMorePage extends StatelessWidget {
  const ProfessionalMorePage({
    super.key,
    required this.controller,
    required this.onSwitchMode,
  });

  final AppController controller;
  final VoidCallback onSwitchMode;

  Future<void> _confirmSwitch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.swap_horiz_rounded),
        title: const Text('تغيير وضع التطبيق'),
        content: const Text(
          'ستعود لشاشة اختيار الوضع. بياناتك ومبيعاتك ومخزونك ستبقى محفوظة.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تغيير الوضع'),
          ),
        ],
      ),
    );
    if (confirmed == true) onSwitchMode();
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'يسير للمبيعات والحسابات',
      applicationVersion: '0.1.0',
      applicationIcon: const YaseerLogo(size: 56, showWordmark: false),
      children: const [
        Text(
          'إدارة عربية بسيطة للمبيعات والمخزون والحسابات، وتعمل محليًا حتى بدون إنترنت.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final customers = controller.parties
            .where((party) => party.kind == PartyKind.customer)
            .length;
        return _PageBody(
          maxWidth: 920,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'المزيد',
                subtitle: 'ملخص بيانات المتجر وإعدادات التطبيق',
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [Color(0xFF0F766E), Color(0xFF0B4F4A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        YaseerLogo(
                          size: 48,
                          title: 'يسير الاحترافي',
                          subtitle: 'بياناتك محفوظة على جهازك',
                          color: Colors.white,
                        ),
                        Spacer(),
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: _proColor,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroStat(
                          icon: Icons.inventory_2_outlined,
                          label: '${controller.products.length} صنف',
                        ),
                        _HeroStat(
                          icon: Icons.receipt_long_outlined,
                          label: '${controller.sales.length} عملية بيع',
                        ),
                        _HeroStat(
                          icon: Icons.people_outline_rounded,
                          label: '$customers عميل',
                        ),
                        _HeroStat(
                          icon: Icons.account_balance_wallet_outlined,
                          label: '${controller.accounts.length} حساب',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'التطبيق',
                child: Column(
                  children: [
                    QuickActionTile(
                      title: 'تغيير الوضع',
                      subtitle:
                          'الانتقال بين الأساسي والاحترافي دون حذف البيانات',
                      icon: Icons.swap_horiz_rounded,
                      color: _infoColor,
                      onTap: () => _confirmSwitch(context),
                    ),
                    const SizedBox(height: 10),
                    QuickActionTile(
                      title: 'التخزين المحلي',
                      subtitle: 'المبيعات والحسابات محفوظة على هذا الجهاز',
                      icon: Icons.cloud_done_outlined,
                      color: _successColor,
                      badge: const StatusChip(
                        label: 'يعمل بدون إنترنت',
                        tone: YaseerStatusTone.success,
                      ),
                    ),
                    const SizedBox(height: 10),
                    QuickActionTile(
                      title: 'عن يسير',
                      subtitle: 'معلومات الإصدار والمنتج',
                      icon: Icons.info_outline_rounded,
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'لا نحتاج اتصالًا بالإنترنت لحفظ عملياتك اليومية.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
