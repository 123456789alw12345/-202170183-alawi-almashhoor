import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../domain/models.dart';
import '../../shared/widgets.dart';
import '../../state/app_controller.dart';

const _customerColor = Color(0xFF0F766E);
const _supplierColor = Color(0xFF2B6CB0);
const _successColor = Color(0xFF198754);
const _warningColor = Color(0xFFD98310);
const _dangerColor = Color(0xFFC43D4B);

class BasicDashboardPage extends StatelessWidget {
  const BasicDashboardPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = controller.ledgerEntries;
        final today = DateTime.now();
        final collected = entries
            .where((entry) => entry.type == LedgerType.customerPayment)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final todayIncome = entries
            .where(
              (entry) =>
                  entry.type == LedgerType.income &&
                  _isSameDay(entry.occurredAt, today),
            )
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final customerDebt = controller.parties
            .where((party) => party.kind == PartyKind.customer)
            .fold<int>(
              0,
              (sum, party) =>
                  sum + _positive(controller.partyBalance(party.id)),
            );
        final supplierDebt = controller.parties
            .where((party) => party.kind == PartyKind.supplier)
            .fold<int>(
              0,
              (sum, party) =>
                  sum + _positive(controller.partyBalance(party.id)),
            );
        final deadlines = <LedgerEntry>[
          ...controller.overdueDebtEntries,
          ...controller.dueTodayDebtEntries,
        ]..sort((a, b) =>
            (a.dueDate ?? a.occurredAt).compareTo(b.dueDate ?? b.occurredAt));

        return SingleChildScrollView(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'مرحبًا بك في يسير',
                  subtitle: 'ملخص واضح لحساباتك وما يحتاج انتباهك اليوم.',
                  primaryAction: FilledButton.icon(
                    onPressed: () => _openPartyTransaction(
                      context,
                      controller,
                      kind: PartyKind.customer,
                      isDebt: true,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة دين'),
                  ),
                ),
                const SizedBox(height: 24),
                _ResponsiveGrid(
                  minItemWidth: 210,
                  children: [
                    MetricCard(
                      label: 'ديون العملاء المتبقية',
                      value: _money(customerDebt),
                      icon: Icons.people_alt_rounded,
                      caption:
                          '${_countByKind(controller, PartyKind.customer)} عميل',
                      color: _customerColor,
                      highlighted: customerDebt > 0,
                    ),
                    MetricCard(
                      label: 'المحصّل من العملاء',
                      value: _money(collected),
                      icon: Icons.payments_rounded,
                      caption: 'إجمالي الدفعات المسجلة',
                      color: _successColor,
                    ),
                    MetricCard(
                      label: 'مستحق للموردين',
                      value: _money(supplierDebt),
                      icon: Icons.local_shipping_rounded,
                      caption:
                          '${_countByKind(controller, PartyKind.supplier)} مورد',
                      color: _supplierColor,
                    ),
                    MetricCard(
                      label: 'مستحق اليوم',
                      value: _money(controller.dueTodayDebtAmount),
                      icon: Icons.today_rounded,
                      caption: '${controller.dueTodayDebtEntries.length} موعد',
                      color: _warningColor,
                      highlighted: controller.dueTodayDebtAmount > 0,
                    ),
                    MetricCard(
                      label: 'متأخر',
                      value: _money(controller.overdueDebtAmount),
                      icon: Icons.notification_important_rounded,
                      caption:
                          '${controller.overdueDebtEntries.length} موعد متأخر',
                      color: _dangerColor,
                      highlighted: controller.overdueDebtAmount > 0,
                    ),
                    MetricCard(
                      label: 'دخل اليوم',
                      value: _money(todayIncome),
                      icon: Icons.south_west_rounded,
                      caption: 'الدخل المباشر المسجل',
                      color: _successColor,
                    ),
                    MetricCard(
                      label: 'مصروف اليوم',
                      value: _money(controller.todayExpenseAmount),
                      icon: Icons.north_east_rounded,
                      caption: 'المصروف المباشر المسجل',
                      color: _dangerColor,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('إجراءات سريعة',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _ResponsiveGrid(
                  minItemWidth: 250,
                  children: [
                    QuickActionTile(
                      title: 'إضافة دين',
                      subtitle: 'سجّل مبلغًا على عميل',
                      icon: Icons.receipt_long_rounded,
                      color: _customerColor,
                      onTap: () => _openPartyTransaction(
                        context,
                        controller,
                        kind: PartyKind.customer,
                        isDebt: true,
                      ),
                    ),
                    QuickActionTile(
                      title: 'تسجيل دفعة',
                      subtitle: 'استلم مبلغًا من عميل',
                      icon: Icons.price_check_rounded,
                      color: _successColor,
                      onTap: () => _openPartyTransaction(
                        context,
                        controller,
                        kind: PartyKind.customer,
                        isDebt: false,
                      ),
                    ),
                    QuickActionTile(
                      title: 'إضافة عميل',
                      subtitle: 'الاسم ورقم الهاتف يكفيان',
                      icon: Icons.person_add_alt_1_rounded,
                      onTap: () => _openAddParty(
                        context,
                        controller,
                        PartyKind.customer,
                      ),
                    ),
                    QuickActionTile(
                      title: 'تسجيل مصروف',
                      subtitle: 'احفظ المبلغ وسبب الصرف',
                      icon: Icons.payments_outlined,
                      color: _dangerColor,
                      onTap: () => _openCashFlow(
                        context,
                        controller,
                        isIncome: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SectionCard(
                  title: 'المواعيد التي تحتاج انتباهك',
                  subtitle: 'المبالغ المتأخرة والمستحقة اليوم',
                  trailing: deadlines.isEmpty
                      ? const StatusChip(
                          label: 'كل شيء مرتب',
                          tone: YaseerStatusTone.success,
                          icon: Icons.check_circle_outline_rounded,
                        )
                      : StatusChip(
                          label: '${deadlines.length} موعد',
                          tone: YaseerStatusTone.warning,
                        ),
                  child: deadlines.isEmpty
                      ? const _CompactEmpty(
                          icon: Icons.event_available_rounded,
                          title: 'لا توجد مبالغ مستحقة اليوم',
                          subtitle: 'ستظهر هنا المواعيد القادمة والمتأخرة.',
                        )
                      : Column(
                          children: [
                            for (var index = 0;
                                index < deadlines.length && index < 5;
                                index++) ...[
                              _DeadlineRow(
                                controller: controller,
                                entry: deadlines[index],
                              ),
                              if (index < deadlines.length - 1 && index < 4)
                                const Divider(height: 24),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PartiesPage extends StatefulWidget {
  const PartiesPage({
    super.key,
    required this.controller,
    required this.kind,
  });

  final AppController controller;
  final PartyKind kind;

  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.kind == PartyKind.customer;
    final singular = isCustomer ? 'عميل' : 'مورد';
    final plural = isCustomer ? 'العملاء' : 'الموردون';

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final all = widget.controller.parties
            .where((party) => party.kind == widget.kind)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        final normalized = _query.trim().toLowerCase();
        final visible = normalized.isEmpty
            ? all
            : all.where((party) {
                return party.name.toLowerCase().contains(normalized) ||
                    (party.phone ?? '').contains(normalized) ||
                    (party.note ?? '').toLowerCase().contains(normalized);
              }).toList();
        final outstanding = all.fold<int>(
          0,
          (sum, party) =>
              sum + _positive(widget.controller.partyBalance(party.id)),
        );

        return SingleChildScrollView(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: plural,
                  subtitle: isCustomer
                      ? 'تابع الديون والدفعات وافتح كشف كل عميل.'
                      : 'تابع المبالغ المستحقة والمدفوعات لكل مورد.',
                  primaryAction: FilledButton.icon(
                    onPressed: () => _openAddParty(
                      context,
                      widget.controller,
                      widget.kind,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text('إضافة $singular'),
                  ),
                ),
                const SizedBox(height: 20),
                _ResponsiveGrid(
                  minItemWidth: 260,
                  children: [
                    MetricCard(
                      label: 'عدد $plural',
                      value: '${all.length}',
                      icon: isCustomer
                          ? Icons.people_alt_rounded
                          : Icons.local_shipping_rounded,
                      caption:
                          all.isEmpty ? 'أضف أول $singular' : 'مسجل في الدفتر',
                      color: isCustomer ? _customerColor : _supplierColor,
                    ),
                    MetricCard(
                      label: isCustomer
                          ? 'المتبقي على العملاء'
                          : 'المتبقي للموردين',
                      value: _money(outstanding),
                      icon: Icons.account_balance_wallet_rounded,
                      caption: 'بعد خصم جميع الدفعات',
                      color: outstanding > 0 ? _warningColor : _successColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SearchBox(
                  controller: _searchController,
                  hintText: 'ابحث بالاسم أو رقم الهاتف…',
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () => setState(() => _query = ''),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  EmptyState(
                    title: all.isEmpty
                        ? 'لا يوجد ${isCustomer ? 'عملاء' : 'موردون'} بعد'
                        : 'لا توجد نتائج مطابقة',
                    description: all.isEmpty
                        ? 'ابدأ بإضافة $singular، ثم سجّل حسابه بسهولة.'
                        : 'جرّب اسمًا أو رقم هاتف مختلفًا.',
                    icon: all.isEmpty
                        ? Icons.person_add_alt_1_rounded
                        : Icons.search_off_rounded,
                    actionLabel:
                        all.isEmpty ? 'إضافة أول $singular' : 'مسح البحث',
                    onAction: all.isEmpty
                        ? () => _openAddParty(
                              context,
                              widget.controller,
                              widget.kind,
                            )
                        : () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                  )
                else
                  Column(
                    children: [
                      for (final party in visible) ...[
                        _PartyCard(
                          controller: widget.controller,
                          party: party,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

enum _ActivityFilter { all, debts, payments, income, expense, transfers }

class _ActivityPageState extends State<ActivityPage> {
  final _searchController = TextEditingController();
  _ActivityFilter _filter = _ActivityFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final rows = _activityRows(widget.controller).where((entry) {
          if (!_matchesFilter(entry, _filter)) return false;
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) return true;
          final party = entry.partyId == null
              ? null
              : widget.controller.partyById(entry.partyId!);
          final account = entry.accountId == null
              ? null
              : widget.controller.accountById(entry.accountId!);
          return _entryTitle(entry.type).contains(query) ||
              (entry.description ?? '').toLowerCase().contains(query) ||
              (party?.name ?? '').toLowerCase().contains(query) ||
              (account?.name ?? '').toLowerCase().contains(query);
        }).toList();

        return SingleChildScrollView(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'الحركة',
                  subtitle: 'كل ما سُجل في حساباتك مرتب من الأحدث.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openTransfer(context, widget.controller),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('تحويل'),
                    ),
                  ],
                  primaryAction: FilledButton.icon(
                    onPressed: () => _openCashFlow(
                      context,
                      widget.controller,
                      isIncome: false,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('مصروف'),
                  ),
                ),
                const SizedBox(height: 20),
                SearchBox(
                  controller: _searchController,
                  hintText: 'ابحث عن عملية أو طرف أو حساب…',
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () => setState(() => _query = ''),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in _ActivityFilter.values) ...[
                        FilterChip(
                          selected: _filter == filter,
                          label: Text(_filterLabel(filter)),
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (rows.isEmpty)
                  EmptyState(
                    title: widget.controller.ledgerEntries.isEmpty
                        ? 'لا توجد حركات بعد'
                        : 'لا توجد حركات مطابقة',
                    description: widget.controller.ledgerEntries.isEmpty
                        ? 'عند تسجيل دين أو دفعة أو مصروف ستظهر العملية هنا.'
                        : 'غيّر البحث أو اختر نوعًا آخر.',
                    icon: Icons.receipt_long_outlined,
                  )
                else
                  Column(
                    children: [
                      for (final entry in rows) ...[
                        _ActivityCard(
                          controller: widget.controller,
                          entry: entry,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BasicMorePage extends StatelessWidget {
  const BasicMorePage({
    super.key,
    required this.controller,
    required this.onSwitchMode,
  });

  final AppController controller;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final accounts = controller.accounts
            .where((account) => !account.isArchived)
            .toList();
        final total = accounts.fold<int>(
          0,
          (sum, account) => sum + controller.accountBalance(account.id),
        );

        return SingleChildScrollView(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'المزيد',
                  subtitle: 'الحسابات المالية والأدوات الإضافية.',
                  primaryAction: FilledButton.icon(
                    onPressed: () => _openAddAccount(context, controller),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('حساب جديد'),
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'الحسابات المالية',
                  subtitle: 'اضغط على أي حساب لعرض حركته.',
                  trailing: MoneyText(
                    amount: total,
                    currency: 'ر.ي',
                    decimalDigits: 0,
                    color: total < 0 ? _dangerColor : _customerColor,
                  ),
                  child: accounts.isEmpty
                      ? _CompactEmpty(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'لا يوجد حساب مالي نشط',
                          subtitle: 'أضف صندوقًا أو بنكًا لبدء تسجيل الدفعات.',
                          actionLabel: 'إضافة حساب',
                          onAction: () => _openAddAccount(context, controller),
                        )
                      : Column(
                          children: [
                            for (var index = 0;
                                index < accounts.length;
                                index++) ...[
                              _AccountRow(
                                controller: controller,
                                account: accounts[index],
                              ),
                              if (index < accounts.length - 1)
                                const Divider(height: 20),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                Text('القبض والصرف',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _ResponsiveGrid(
                  minItemWidth: 245,
                  children: [
                    QuickActionTile(
                      title: 'تسجيل دخل',
                      subtitle: 'مبلغ دخل إلى أحد الحسابات',
                      icon: Icons.south_west_rounded,
                      color: _successColor,
                      onTap: () => _openCashFlow(
                        context,
                        controller,
                        isIncome: true,
                      ),
                    ),
                    QuickActionTile(
                      title: 'تسجيل مصروف',
                      subtitle: 'مبلغ خرج من أحد الحسابات',
                      icon: Icons.north_east_rounded,
                      color: _dangerColor,
                      onTap: () => _openCashFlow(
                        context,
                        controller,
                        isIncome: false,
                      ),
                    ),
                    QuickActionTile(
                      title: 'تحويل بين الحسابات',
                      subtitle: 'لا يُحسب دخلًا أو مصروفًا',
                      icon: Icons.swap_horiz_rounded,
                      color: _supplierColor,
                      onTap: () => _openTransfer(context, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'النظام',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.swap_calls_rounded),
                    ),
                    title: const Text('العودة لاختيار النظام'),
                    subtitle: const Text('لن تُحذف بياناتك أو حركاتك المسجلة.'),
                    trailing:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    onTap: () => _confirmSwitchMode(context),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSwitchMode(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.swap_calls_rounded),
        title: const Text('العودة لاختيار النظام؟'),
        content: const Text(
          'ستعود إلى شاشة الاختيار، وستبقى كل بيانات العملاء والحسابات محفوظة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed == true) onSwitchMode();
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.controller, required this.entry});

  final AppController controller;
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final party =
        entry.partyId == null ? null : controller.partyById(entry.partyId!);
    final dueDate = entry.dueDate;
    final overdue = dueDate != null &&
        _dateOnly(dueDate).isBefore(_dateOnly(DateTime.now()));
    final remaining = controller.outstandingDebt(entry.id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: party == null
          ? null
          : () => _openPartyDetails(context, controller, party),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (overdue ? _dangerColor : _warningColor)
                  .withValues(alpha: .1),
              foregroundColor: overdue ? _dangerColor : _warningColor,
              child: Icon(
                  overdue ? Icons.priority_high_rounded : Icons.today_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party?.name ?? 'طرف غير متاح',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueDate == null
                        ? 'بدون موعد'
                        : overdue
                            ? 'متأخر منذ ${_date(dueDate)}'
                            : 'مستحق اليوم • ${_date(dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: overdue ? _dangerColor : _warningColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            MoneyText(
              amount: remaining,
              currency: 'ر.ي',
              decimalDigits: 0,
              color: overdue ? _dangerColor : _warningColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.controller, required this.party});

  final AppController controller;
  final PartyRecord party;

  @override
  Widget build(BuildContext context) {
    final balance = controller.partyBalance(party.id);
    final isCustomer = party.kind == PartyKind.customer;
    final accent = isCustomer ? _customerColor : _supplierColor;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: YaseerRadii.card,
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPartyDetails(context, controller, party),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: accent.withValues(alpha: .1),
                    foregroundColor: accent,
                    child: Text(
                      party.name.trim().isEmpty ? '؟' : party.name.trim()[0],
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(party.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (party.phone != null) ...[
                          const SizedBox(height: 3),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              party.phone!,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PartyBalanceBadge(party: party, balance: balance),
                ],
              ),
              if (party.note != null) ...[
                const SizedBox(height: 10),
                Text(
                  party.note!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .62),
                      ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openPartyTransaction(
                      context,
                      controller,
                      kind: party.kind,
                      isDebt: true,
                      initialPartyId: party.id,
                    ),
                    icon: const Icon(Icons.add_card_rounded, size: 19),
                    label: Text(isCustomer ? 'إضافة دين' : 'دين مورد'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: balance > 0
                        ? () => _openPartyTransaction(
                              context,
                              controller,
                              kind: party.kind,
                              isDebt: false,
                              initialPartyId: party.id,
                            )
                        : null,
                    icon: const Icon(Icons.price_check_rounded, size: 19),
                    label: Text(isCustomer ? 'تسجيل دفعة' : 'دفع للمورد'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _openPartyDetails(context, controller, party),
                    icon: const Icon(Icons.receipt_long_outlined, size: 19),
                    label: const Text('كشف الحساب'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyBalanceBadge extends StatelessWidget {
  const _PartyBalanceBadge({required this.party, required this.balance});

  final PartyRecord party;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final isCustomer = party.kind == PartyKind.customer;
    final label = balance == 0
        ? 'مسدّد'
        : balance > 0
            ? (isCustomer ? 'عليه ${_money(balance)}' : 'له ${_money(balance)}')
            : (isCustomer
                ? 'له ${_money(balance.abs())}'
                : 'لك ${_money(balance.abs())}');
    return StatusChip(
      label: label,
      tone: balance == 0
          ? YaseerStatusTone.success
          : balance > 0
              ? YaseerStatusTone.warning
              : YaseerStatusTone.info,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.controller, required this.entry});

  final AppController controller;
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final party =
        entry.partyId == null ? null : controller.partyById(entry.partyId!);
    final account = entry.accountId == null
        ? null
        : controller.accountById(entry.accountId!);
    final related = entry.relatedAccountId == null
        ? null
        : controller.accountById(entry.relatedAccountId!);
    final tone = _entryTone(entry.type);
    final detail = entry.type == LedgerType.transferOut
        ? 'من ${account?.name ?? 'حساب غير متاح'} إلى ${related?.name ?? 'حساب غير متاح'}'
        : party?.name ?? account?.name ?? 'بدون طرف محدد';

    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tone.icon, color: tone.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_entryTitle(entry.type),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  entry.description == null
                      ? detail
                      : '$detail • ${entry.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .62),
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  _dateTime(entry.occurredAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          MoneyText(
            amount: entry.amount,
            currency: 'ر.ي',
            decimalDigits: 0,
            color: tone.color,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.controller, required this.account});

  final AppController controller;
  final FinancialAccount account;

  @override
  Widget build(BuildContext context) {
    final balance = controller.accountBalance(account.id);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _AccountDetailsPage(
            controller: controller,
            accountId: account.id,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const CircleAvatar(
                child: Icon(Icons.account_balance_wallet_rounded)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    balance < 0 ? 'رصيد سالب' : 'الرصيد المتاح',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            MoneyText(
              amount: balance,
              currency: 'ر.ي',
              decimalDigits: 0,
              color: balance < 0 ? _dangerColor : _customerColor,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
          ],
        ),
      ),
    );
  }
}

class _PartyDetailsPage extends StatelessWidget {
  const _PartyDetailsPage({
    required this.controller,
    required this.partyId,
  });

  final AppController controller;
  final String partyId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final party = controller.partyById(partyId);
        if (party == null) {
          return const Scaffold(
            body: SafeArea(
              child: EmptyState(
                title: 'هذا الطرف غير متاح',
                description: 'ربما لم يعد موجودًا في البيانات الحالية.',
              ),
            ),
          );
        }

        final isCustomer = party.kind == PartyKind.customer;
        final entries = controller.ledgerEntries
            .where((entry) => entry.partyId == party.id)
            .toList()
          ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
        var runningBalance = 0;
        final statement = <_StatementItem>[];
        for (final entry in entries) {
          runningBalance += _partyDelta(entry, party.kind);
          statement.add(_StatementItem(entry, runningBalance));
        }
        final newestFirst = statement.reversed.toList();
        final totalDebt = entries
            .where(
              (entry) => isCustomer
                  ? entry.type == LedgerType.customerDebt ||
                      entry.type == LedgerType.creditSale
                  : entry.type == LedgerType.supplierDebt,
            )
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final paymentType = isCustomer
            ? LedgerType.customerPayment
            : LedgerType.supplierPayment;
        final totalPaid = entries
            .where((entry) => entry.type == paymentType)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final balance = controller.partyBalance(party.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(party.name),
            actions: [
              if (party.phone != null)
                IconButton(
                  tooltip: 'تذكير واتساب',
                  onPressed: () => _previewAndLaunch(
                    context,
                    party: party,
                    balance: balance,
                    channel: _ShareChannel.whatsapp,
                    statement: newestFirst,
                  ),
                  icon: const Icon(Icons.chat_rounded),
                ),
              if (party.phone != null)
                IconButton(
                  tooltip: 'تذكير SMS',
                  onPressed: () => _previewAndLaunch(
                    context,
                    party: party,
                    balance: balance,
                    channel: _ShareChannel.sms,
                    statement: newestFirst,
                  ),
                  icon: const Icon(Icons.sms_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveContent(
                maxWidth: 1000,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              (isCustomer ? _customerColor : _supplierColor)
                                  .withValues(alpha: .12),
                          child: Text(
                            party.name.isEmpty ? '؟' : party.name[0],
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: isCustomer
                                      ? _customerColor
                                      : _supplierColor,
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                party.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(isCustomer ? 'عميل' : 'مورد'),
                              if (party.phone != null) ...[
                                const SizedBox(height: 3),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    party.phone!,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _PartyBalanceBadge(party: party, balance: balance),
                      ],
                    ),
                    if (party.note != null) ...[
                      const SizedBox(height: 12),
                      Text(party.note!),
                    ],
                    const SizedBox(height: 22),
                    _ResponsiveGrid(
                      minItemWidth: 205,
                      children: [
                        MetricCard(
                          label: isCustomer ? 'إجمالي الدين' : 'إجمالي المستحق',
                          value: _money(totalDebt),
                          icon: Icons.receipt_long_rounded,
                          color: _warningColor,
                        ),
                        MetricCard(
                          label: 'إجمالي المدفوع',
                          value: _money(totalPaid),
                          icon: Icons.price_check_rounded,
                          color: _successColor,
                        ),
                        MetricCard(
                          label: 'المتبقي',
                          value: _money(balance),
                          icon: Icons.account_balance_wallet_rounded,
                          color: balance > 0 ? _dangerColor : _successColor,
                          highlighted: balance > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openPartyTransaction(
                            context,
                            controller,
                            kind: party.kind,
                            isDebt: true,
                            initialPartyId: party.id,
                          ),
                          icon: const Icon(Icons.add_card_rounded),
                          label: Text(isCustomer ? 'إضافة دين' : 'دين مورد'),
                        ),
                        OutlinedButton.icon(
                          onPressed: balance > 0
                              ? () => _openPartyTransaction(
                                    context,
                                    controller,
                                    kind: party.kind,
                                    isDebt: false,
                                    initialPartyId: party.id,
                                  )
                              : null,
                          icon: const Icon(Icons.price_check_rounded),
                          label: Text(isCustomer ? 'تسجيل دفعة' : 'دفع للمورد'),
                        ),
                        if (party.phone != null)
                          OutlinedButton.icon(
                            onPressed: () => _previewAndLaunch(
                              context,
                              party: party,
                              balance: balance,
                              channel: _ShareChannel.whatsapp,
                              statement: newestFirst,
                            ),
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text('واتساب'),
                          ),
                        if (party.phone != null)
                          OutlinedButton.icon(
                            onPressed: () => _previewAndLaunch(
                              context,
                              party: party,
                              balance: balance,
                              channel: _ShareChannel.sms,
                              statement: newestFirst,
                            ),
                            icon: const Icon(Icons.sms_outlined),
                            label: const Text('SMS'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text('كشف الحساب',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'التاريخ، العملية، المبلغ والرصيد بعد كل حركة.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (newestFirst.isEmpty)
                      const SectionCard(
                        child: _CompactEmpty(
                          icon: Icons.receipt_long_outlined,
                          title: 'لا توجد حركة في هذا الحساب',
                          subtitle: 'سجّل أول دين أو دفعة لتظهر هنا.',
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final item in newestFirst) ...[
                            _StatementRow(kind: party.kind, item: item),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatementItem {
  const _StatementItem(this.entry, this.runningBalance);

  final LedgerEntry entry;
  final int runningBalance;
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.kind, required this.item});

  final PartyKind kind;
  final _StatementItem item;

  @override
  Widget build(BuildContext context) {
    final delta = _partyDelta(item.entry, kind);
    final isDebt = delta >= 0;
    return SectionCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDebt ? _warningColor : _successColor)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isDebt ? Icons.receipt_long_rounded : Icons.price_check_rounded,
              color: isDebt ? _warningColor : _successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entryTitle(item.entry.type),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  item.entry.description ?? _dateTime(item.entry.occurredAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.entry.description != null)
                  Text(
                    _dateTime(item.entry.occurredAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                amount: item.entry.amount,
                currency: 'ر.ي',
                decimalDigits: 0,
                color: isDebt ? _warningColor : _successColor,
              ),
              const SizedBox(height: 3),
              Text(
                'الرصيد ${_money(item.runningBalance)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountDetailsPage extends StatelessWidget {
  const _AccountDetailsPage({
    required this.controller,
    required this.accountId,
  });

  final AppController controller;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final account = controller.accountById(accountId);
        if (account == null) {
          return const Scaffold(
            body: EmptyState(title: 'الحساب غير متاح'),
          );
        }
        final entries = controller.ledgerEntries
            .where((entry) => entry.accountId == account.id)
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        final incoming = entries
            .where((entry) => _isAccountIncoming(entry.type))
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final outgoing = entries
            .where((entry) => _isAccountOutgoing(entry.type))
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final balance = controller.accountBalance(account.id);

        return Scaffold(
          appBar: AppBar(title: Text(account.name)),
          body: SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveContent(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      title: account.name,
                      subtitle: 'كشف حركة الحساب المالي.',
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => _openTransfer(context, controller),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('تحويل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ResponsiveGrid(
                      minItemWidth: 210,
                      children: [
                        MetricCard(
                          label: 'الرصيد الحالي',
                          value: _money(balance),
                          icon: Icons.account_balance_wallet_rounded,
                          color: balance < 0 ? _dangerColor : _customerColor,
                          highlighted: true,
                        ),
                        MetricCard(
                          label: 'إجمالي الداخل',
                          value: _money(incoming),
                          icon: Icons.south_west_rounded,
                          color: _successColor,
                        ),
                        MetricCard(
                          label: 'إجمالي الخارج',
                          value: _money(outgoing),
                          icon: Icons.north_east_rounded,
                          color: _dangerColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('الحركات',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      const SectionCard(
                        child: _CompactEmpty(
                          icon: Icons.receipt_long_outlined,
                          title: 'لا توجد حركة في هذا الحساب',
                          subtitle: 'سيظهر الدخل والمصروف والتحويل هنا.',
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final entry in entries) ...[
                            _ActivityCard(controller: controller, entry: entry),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openAddParty(
  BuildContext context,
  AppController controller,
  PartyKind kind,
) async {
  final saved = await _showAdaptiveForm<bool>(
    context,
    (formContext) => _AddPartyForm(controller: controller, kind: kind),
  );
  if (saved == true && context.mounted) {
    _showSuccess(
      context,
      kind == PartyKind.customer ? 'تمت إضافة العميل' : 'تمت إضافة المورد',
    );
  }
}

Future<void> _openPartyTransaction(
  BuildContext context,
  AppController controller, {
  required PartyKind kind,
  required bool isDebt,
  String? initialPartyId,
}) async {
  final available = controller.parties.where((party) => party.kind == kind);
  if (available.isEmpty) {
    _showNotice(
      context,
      kind == PartyKind.customer
          ? 'أضف عميلًا أولًا ثم سجّل العملية.'
          : 'أضف موردًا أولًا ثم سجّل العملية.',
    );
    await _openAddParty(context, controller, kind);
    return;
  }
  if (!isDebt &&
      controller.accounts.where((item) => !item.isArchived).isEmpty) {
    _showNotice(context, 'أضف حسابًا ماليًا لاستكمال الدفعة.');
    await _openAddAccount(context, controller);
    return;
  }

  final saved = await _showAdaptiveForm<bool>(
    context,
    (formContext) => _PartyTransactionForm(
      controller: controller,
      kind: kind,
      isDebt: isDebt,
      initialPartyId: initialPartyId,
    ),
  );
  if (saved == true && context.mounted) {
    final message = isDebt
        ? (kind == PartyKind.customer
            ? 'تم تسجيل الدين'
            : 'تم تسجيل دين المورد')
        : (kind == PartyKind.customer
            ? 'تم تسجيل الدفعة'
            : 'تم تسجيل دفع المورد');
    _showSuccess(context, message);
  }
}

Future<void> _openCashFlow(
  BuildContext context,
  AppController controller, {
  required bool isIncome,
}) async {
  if (controller.accounts.where((item) => !item.isArchived).isEmpty) {
    _showNotice(context, 'أضف حسابًا ماليًا أولًا.');
    await _openAddAccount(context, controller);
    return;
  }
  final saved = await _showAdaptiveForm<bool>(
    context,
    (formContext) => _CashFlowForm(
      controller: controller,
      isIncome: isIncome,
    ),
  );
  if (saved == true && context.mounted) {
    _showSuccess(context, isIncome ? 'تم تسجيل الدخل' : 'تم تسجيل المصروف');
  }
}

Future<void> _openAddAccount(
  BuildContext context,
  AppController controller,
) async {
  final saved = await _showAdaptiveForm<bool>(
    context,
    (formContext) => _AddAccountForm(controller: controller),
  );
  if (saved == true && context.mounted) {
    _showSuccess(context, 'تمت إضافة الحساب المالي');
  }
}

Future<void> _openTransfer(
  BuildContext context,
  AppController controller,
) async {
  final activeAccounts =
      controller.accounts.where((account) => !account.isArchived).length;
  if (activeAccounts < 2) {
    _showNotice(context, 'التحويل يحتاج حسابين ماليين على الأقل.');
    await _openAddAccount(context, controller);
    return;
  }
  final saved = await _showAdaptiveForm<bool>(
    context,
    (formContext) => _TransferForm(controller: controller),
  );
  if (saved == true && context.mounted) {
    _showSuccess(context, 'تم التحويل بين الحسابات');
  }
}

Future<T?> _showAdaptiveForm<T>(
  BuildContext context,
  WidgetBuilder builder,
) {
  if (MediaQuery.sizeOf(context).width >= 720) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * .9,
          ),
          child: builder(dialogContext),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: builder,
  );
}

mixin _FormSubmission<T extends StatefulWidget> on State<T> {
  bool submitting = false;
  String? submitError;

  Future<void> submit(Future<void> Function() action) async {
    if (submitting) return;
    setState(() {
      submitting = true;
      submitError = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        submitting = false;
        submitError = _friendlyError(error);
      });
    }
  }
}

class _AddPartyForm extends StatefulWidget {
  const _AddPartyForm({required this.controller, required this.kind});

  final AppController controller;
  final PartyKind kind;

  @override
  State<_AddPartyForm> createState() => _AddPartyFormState();
}

class _AddPartyFormState extends State<_AddPartyForm>
    with _FormSubmission<_AddPartyForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await submit(
      () async {
        await widget.controller.addParty(
          name: _name.text,
          kind: widget.kind,
          phone: _phone.text,
          note: _note.text,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.kind == PartyKind.customer;
    return _FormSurface(
      formKey: _formKey,
      title: isCustomer ? 'إضافة عميل' : 'إضافة مورد',
      subtitle: 'الاسم مطلوب، وبقية المعلومات اختيارية.',
      icon: isCustomer
          ? Icons.person_add_alt_1_rounded
          : Icons.local_shipping_rounded,
      submitting: submitting,
      error: submitError,
      submitLabel: isCustomer ? 'حفظ العميل' : 'حفظ المورد',
      onSubmit: _save,
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: isCustomer ? 'اسم العميل *' : 'اسم المورد *',
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'اكتب الاسم' : null,
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.left,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف (اختياري)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'ملاحظة (اختيارية)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }
}

class _PartyTransactionForm extends StatefulWidget {
  const _PartyTransactionForm({
    required this.controller,
    required this.kind,
    required this.isDebt,
    this.initialPartyId,
  });

  final AppController controller;
  final PartyKind kind;
  final bool isDebt;
  final String? initialPartyId;

  @override
  State<_PartyTransactionForm> createState() => _PartyTransactionFormState();
}

class _PartyTransactionFormState extends State<_PartyTransactionForm>
    with _FormSubmission<_PartyTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String? _partyId;
  String? _accountId;
  DateTime? _dueDate;

  List<PartyRecord> get _parties => widget.controller.parties
      .where((party) => party.kind == widget.kind)
      .toList();

  List<FinancialAccount> get _accounts => widget.controller.accounts
      .where((account) => !account.isArchived)
      .toList();

  @override
  void initState() {
    super.initState();
    final parties = _parties;
    _partyId = parties.any((party) => party.id == widget.initialPartyId)
        ? widget.initialPartyId
        : (parties.isEmpty ? null : parties.first.id);
    final accounts = _accounts;
    _accountId = accounts.isEmpty ? null : accounts.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = _dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: 'اختر موعد السداد',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (selected != null) setState(() => _dueDate = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final partyId = _partyId;
    final amount = _parseAmount(_amount.text);
    if (partyId == null || amount == null) return;
    await submit(
      () async {
        if (widget.kind == PartyKind.customer) {
          if (widget.isDebt) {
            await widget.controller.recordCustomerDebt(
              customerId: partyId,
              amount: amount,
              dueDate: _dueDate,
              description: _description.text,
            );
          } else {
            await widget.controller.recordCustomerPayment(
              customerId: partyId,
              amount: amount,
              accountId: _accountId,
              description: _description.text,
            );
          }
        } else if (widget.isDebt) {
          await widget.controller.recordSupplierDebt(
            supplierId: partyId,
            amount: amount,
            dueDate: _dueDate,
            description: _description.text,
          );
        } else {
          await widget.controller.recordSupplierPayment(
            supplierId: partyId,
            amount: amount,
            accountId: _accountId,
            description: _description.text,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.kind == PartyKind.customer;
    final title = widget.isDebt
        ? (isCustomer ? 'إضافة دين على عميل' : 'تسجيل دين مورد')
        : (isCustomer ? 'تسجيل دفعة من عميل' : 'دفع مبلغ لمورد');
    final selectedBalance =
        _partyId == null ? 0 : widget.controller.partyBalance(_partyId!);

    return _FormSurface(
      formKey: _formKey,
      title: title,
      subtitle: widget.isDebt
          ? 'أدخل المبلغ، ويمكنك تحديد موعد للسداد.'
          : 'اختر الحساب المالي الذي دخلت أو خرجت منه الدفعة.',
      icon: widget.isDebt
          ? Icons.receipt_long_rounded
          : Icons.price_check_rounded,
      submitting: submitting,
      error: submitError,
      submitLabel: 'حفظ العملية',
      onSubmit: _save,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _partyId,
          decoration: InputDecoration(
            labelText: isCustomer ? 'العميل *' : 'المورد *',
            prefixIcon: Icon(
              isCustomer
                  ? Icons.person_outline_rounded
                  : Icons.local_shipping_outlined,
            ),
          ),
          items: [
            for (final party in _parties)
              DropdownMenuItem(value: party.id, child: Text(party.name)),
          ],
          onChanged:
              submitting ? null : (value) => setState(() => _partyId = value),
          validator: (value) => value == null ? 'اختر الطرف' : null,
        ),
        if (!widget.isDebt) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'المتبقي: ${_money(selectedBalance)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selectedBalance > 0 ? _warningColor : _successColor,
                  ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _MoneyField(
          controller: _amount,
          label: 'المبلغ *',
          autofocus: false,
          validator: (value) {
            final amount = _parseAmount(value ?? '');
            if (amount == null || amount <= 0) return 'أدخل مبلغًا أكبر من صفر';
            if (!widget.isDebt && amount > selectedBalance) {
              return 'المبلغ أكبر من المتبقي (${_money(selectedBalance)})';
            }
            return null;
          },
        ),
        if (!widget.isDebt) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            decoration: const InputDecoration(
              labelText: 'الحساب المالي *',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: [
              for (final account in _accounts)
                DropdownMenuItem(value: account.id, child: Text(account.name)),
            ],
            onChanged: submitting
                ? null
                : (value) => setState(() => _accountId = value),
            validator: (value) => value == null ? 'اختر الحساب المالي' : null,
          ),
        ],
        if (widget.isDebt) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: submitting ? null : _pickDueDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _dueDate == null
                  ? 'تحديد موعد سداد (اختياري)'
                  : 'موعد السداد: ${_date(_dueDate!)}',
            ),
          ),
          if (_dueDate != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed:
                    submitting ? null : () => setState(() => _dueDate = null),
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('إزالة الموعد'),
              ),
            ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _description,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText:
                widget.isDebt ? 'سبب الدين أو ملاحظة' : 'ملاحظة (اختيارية)',
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }
}

class _CashFlowForm extends StatefulWidget {
  const _CashFlowForm({required this.controller, required this.isIncome});

  final AppController controller;
  final bool isIncome;

  @override
  State<_CashFlowForm> createState() => _CashFlowFormState();
}

class _CashFlowFormState extends State<_CashFlowForm>
    with _FormSubmission<_CashFlowForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String? _accountId;

  List<FinancialAccount> get _accounts => widget.controller.accounts
      .where((account) => !account.isArchived)
      .toList();

  @override
  void initState() {
    super.initState();
    final accounts = _accounts;
    _accountId = accounts.isEmpty ? null : accounts.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_amount.text);
    if (amount == null) return;
    await submit(
      () async {
        if (widget.isIncome) {
          await widget.controller.recordIncome(
            amount: amount,
            accountId: _accountId,
            description: _description.text,
          );
        } else {
          await widget.controller.recordExpense(
            amount: amount,
            accountId: _accountId,
            description: _description.text,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormSurface(
      formKey: _formKey,
      title: widget.isIncome ? 'تسجيل دخل' : 'تسجيل مصروف',
      subtitle: widget.isIncome
          ? 'أضف المبلغ إلى الحساب المالي المختار.'
          : 'اخصم المبلغ من الحساب المالي المختار.',
      icon:
          widget.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
      iconColor: widget.isIncome ? _successColor : _dangerColor,
      submitting: submitting,
      error: submitError,
      submitLabel: widget.isIncome ? 'حفظ الدخل' : 'حفظ المصروف',
      onSubmit: _save,
      children: [
        _MoneyField(
          controller: _amount,
          label: 'المبلغ *',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _accountId,
          decoration: const InputDecoration(
            labelText: 'الحساب المالي *',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          items: [
            for (final account in _accounts)
              DropdownMenuItem(value: account.id, child: Text(account.name)),
          ],
          onChanged:
              submitting ? null : (value) => setState(() => _accountId = value),
          validator: (value) => value == null ? 'اختر الحساب المالي' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _description,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: widget.isIncome ? 'سبب الدخل *' : 'سبب المصروف *',
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? (widget.isIncome ? 'اكتب سبب الدخل' : 'اكتب سبب المصروف')
              : null,
        ),
      ],
    );
  }
}

class _AddAccountForm extends StatefulWidget {
  const _AddAccountForm({required this.controller});

  final AppController controller;

  @override
  State<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<_AddAccountForm>
    with _FormSubmission<_AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _openingBalance = TextEditingController(text: '0');

  @override
  void dispose() {
    _name.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await submit(
      () async {
        await widget.controller.addAccount(
          name: _name.text,
          openingBalance: _parseSignedAmount(_openingBalance.text) ?? 0,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormSurface(
      formKey: _formKey,
      title: 'إضافة حساب مالي',
      subtitle: 'مثل الصندوق أو البنك أو المحفظة.',
      icon: Icons.account_balance_wallet_rounded,
      submitting: submitting,
      error: submitError,
      submitLabel: 'حفظ الحساب',
      onSubmit: _save,
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'اسم الحساب *',
            hintText: 'مثال: الصندوق، البنك، المحفظة',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'اكتب اسم الحساب';
            final duplicate = widget.controller.accounts.any(
              (account) =>
                  account.name.trim().toLowerCase() ==
                  value.trim().toLowerCase(),
            );
            return duplicate ? 'يوجد حساب بهذا الاسم' : null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _openingBalance,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9,]*')),
          ],
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            labelText: 'الرصيد الافتتاحي',
            suffixText: 'ر.ي',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          validator: (value) => _parseSignedAmount(value ?? '') == null
              ? 'اكتب رقمًا صحيحًا'
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          'اتركه صفرًا للحساب الجديد، أو أدخل رصيده الحالي.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TransferForm extends StatefulWidget {
  const _TransferForm({required this.controller});

  final AppController controller;

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm>
    with _FormSubmission<_TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;

  List<FinancialAccount> get _accounts => widget.controller.accounts
      .where((account) => !account.isArchived)
      .toList();

  @override
  void initState() {
    super.initState();
    final accounts = _accounts;
    if (accounts.isNotEmpty) _fromAccountId = accounts.first.id;
    if (accounts.length > 1) _toAccountId = accounts[1].id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_amount.text);
    if (amount == null || _fromAccountId == null || _toAccountId == null) {
      return;
    }
    await submit(
      () => widget.controller.transfer(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: amount,
        description: _description.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceBalance = _fromAccountId == null
        ? 0
        : widget.controller.accountBalance(_fromAccountId!);
    return _FormSurface(
      formKey: _formKey,
      title: 'تحويل بين الحسابات',
      subtitle: 'التحويل لا يُحسب دخلًا أو مصروفًا.',
      icon: Icons.swap_horiz_rounded,
      iconColor: _supplierColor,
      submitting: submitting,
      error: submitError,
      submitLabel: 'تنفيذ التحويل',
      onSubmit: _save,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _fromAccountId,
          decoration: const InputDecoration(
            labelText: 'من حساب *',
            prefixIcon: Icon(Icons.upload_rounded),
          ),
          items: [
            for (final account in _accounts)
              DropdownMenuItem(value: account.id, child: Text(account.name)),
          ],
          onChanged: submitting
              ? null
              : (value) => setState(() {
                    _fromAccountId = value;
                    if (_toAccountId == value) {
                      _toAccountId = _accounts
                          .where((account) => account.id != value)
                          .first
                          .id;
                    }
                  }),
          validator: (value) => value == null ? 'اختر حساب المصدر' : null,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'الرصيد المتاح: ${_money(sourceBalance)}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _toAccountId,
          decoration: const InputDecoration(
            labelText: 'إلى حساب *',
            prefixIcon: Icon(Icons.download_rounded),
          ),
          items: [
            for (final account in _accounts)
              if (account.id != _fromAccountId)
                DropdownMenuItem(value: account.id, child: Text(account.name)),
          ],
          onChanged: submitting
              ? null
              : (value) => setState(() => _toAccountId = value),
          validator: (value) {
            if (value == null) return 'اختر حساب الوجهة';
            if (value == _fromAccountId) return 'اختر حسابًا مختلفًا';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _MoneyField(
          controller: _amount,
          label: 'مبلغ التحويل *',
          autofocus: true,
          validator: (value) {
            final amount = _parseAmount(value ?? '');
            if (amount == null || amount <= 0) return 'أدخل مبلغًا أكبر من صفر';
            if (amount > sourceBalance) return 'المبلغ أكبر من الرصيد المتاح';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _description,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'ملاحظة (اختيارية)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }
}

class _FormSurface extends StatelessWidget {
  const _FormSurface({
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.submitting,
    required this.submitLabel,
    required this.onSubmit,
    required this.children,
    this.error,
    this.iconColor,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final bool submitting;
  final String submitLabel;
  final VoidCallback onSubmit;
  final String? error;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? Theme.of(context).colorScheme.primary;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: .64),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        submitting ? null : () => Navigator.maybePop(context),
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...children,
              if (error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _dangerColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _dangerColor.withValues(alpha: .25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: _dangerColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(color: _dangerColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(submitting ? 'جارٍ الحفظ…' : submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'ر.ي',
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
      validator: validator ??
          (value) {
            final amount = _parseAmount(value ?? '');
            return amount == null || amount <= 0
                ? 'أدخل مبلغًا أكبر من صفر'
                : null;
          },
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    this.minItemWidth = 220,
  });

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final available = constraints.maxWidth;
        final count = ((available + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, 4);
        final itemWidth = (available - (count - 1) * spacing) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _EntryTone {
  const _EntryTone(this.color, this.icon);

  final Color color;
  final IconData icon;
}

_EntryTone _entryTone(LedgerType type) {
  return switch (type) {
    LedgerType.customerPayment ||
    LedgerType.income ||
    LedgerType.cashSale =>
      const _EntryTone(_successColor, Icons.south_west_rounded),
    LedgerType.supplierPayment ||
    LedgerType.expense =>
      const _EntryTone(_dangerColor, Icons.north_east_rounded),
    LedgerType.transferIn ||
    LedgerType.transferOut =>
      const _EntryTone(_supplierColor, Icons.swap_horiz_rounded),
    LedgerType.customerDebt ||
    LedgerType.supplierDebt ||
    LedgerType.creditSale =>
      const _EntryTone(_warningColor, Icons.receipt_long_rounded),
  };
}

List<LedgerEntry> _activityRows(AppController controller) {
  final entries = controller.ledgerEntries.toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final outgoingReferences = entries
      .where((entry) => entry.type == LedgerType.transferOut)
      .map((entry) => entry.referenceId)
      .whereType<String>()
      .toSet();
  return entries.where((entry) {
    if (entry.type != LedgerType.transferIn) return true;
    return entry.referenceId == null ||
        !outgoingReferences.contains(entry.referenceId);
  }).toList();
}

bool _matchesFilter(LedgerEntry entry, _ActivityFilter filter) {
  return switch (filter) {
    _ActivityFilter.all => true,
    _ActivityFilter.debts => entry.type == LedgerType.customerDebt ||
        entry.type == LedgerType.supplierDebt ||
        entry.type == LedgerType.creditSale,
    _ActivityFilter.payments => entry.type == LedgerType.customerPayment ||
        entry.type == LedgerType.supplierPayment,
    _ActivityFilter.income =>
      entry.type == LedgerType.income || entry.type == LedgerType.cashSale,
    _ActivityFilter.expense => entry.type == LedgerType.expense,
    _ActivityFilter.transfers => entry.type == LedgerType.transferIn ||
        entry.type == LedgerType.transferOut,
  };
}

String _filterLabel(_ActivityFilter filter) {
  return switch (filter) {
    _ActivityFilter.all => 'الكل',
    _ActivityFilter.debts => 'الديون',
    _ActivityFilter.payments => 'الدفعات',
    _ActivityFilter.income => 'الدخل',
    _ActivityFilter.expense => 'المصروف',
    _ActivityFilter.transfers => 'التحويلات',
  };
}

String _entryTitle(LedgerType type) {
  return switch (type) {
    LedgerType.customerDebt => 'دين عميل',
    LedgerType.customerPayment => 'دفعة عميل',
    LedgerType.supplierDebt => 'دين مورد',
    LedgerType.supplierPayment => 'دفع لمورد',
    LedgerType.income => 'دخل',
    LedgerType.expense => 'مصروف',
    LedgerType.transferIn || LedgerType.transferOut => 'تحويل بين الحسابات',
    LedgerType.cashSale => 'بيع نقدي',
    LedgerType.creditSale => 'بيع آجل',
  };
}

bool _isAccountIncoming(LedgerType type) {
  return type == LedgerType.customerPayment ||
      type == LedgerType.income ||
      type == LedgerType.transferIn ||
      type == LedgerType.cashSale;
}

bool _isAccountOutgoing(LedgerType type) {
  return type == LedgerType.supplierPayment ||
      type == LedgerType.expense ||
      type == LedgerType.transferOut;
}

int _partyDelta(LedgerEntry entry, PartyKind kind) {
  if (kind == PartyKind.customer) {
    if (entry.type == LedgerType.customerDebt ||
        entry.type == LedgerType.creditSale) {
      return entry.amount;
    }
    if (entry.type == LedgerType.customerPayment) return -entry.amount;
  } else {
    if (entry.type == LedgerType.supplierDebt) return entry.amount;
    if (entry.type == LedgerType.supplierPayment) return -entry.amount;
  }
  return 0;
}

int _positive(int value) => value > 0 ? value : 0;

int _countByKind(AppController controller, PartyKind kind) =>
    controller.parties.where((party) => party.kind == kind).length;

int? _parseAmount(String value) {
  final normalized = value.replaceAll(',', '').trim();
  return int.tryParse(normalized);
}

int? _parseSignedAmount(String value) {
  final normalized = value.replaceAll(',', '').trim();
  return int.tryParse(normalized);
}

String _money(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final result = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    result.write(digits[index]);
    final remaining = digits.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) result.write(',');
  }
  return '${negative ? '-' : ''}${result.toString()} ر.ي';
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool _isSameDay(DateTime first, DateTime second) =>
    _dateOnly(first) == _dateOnly(second);

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  return '${_date(local)} • $hour:$minute';
}

String _friendlyError(Object error) {
  var message = error.toString().trim();
  const prefixes = <String>[
    'Invalid argument(s): ',
    'Bad state: ',
    'FormatException: ',
    'Exception: ',
  ];
  for (final prefix in prefixes) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length);
      break;
    }
  }
  final namedArgument = RegExp(r'^Invalid argument \([^)]*\):\s*');
  message = message.replaceFirst(namedArgument, '');
  return message.isEmpty ? 'تعذر حفظ العملية. حاول مرة أخرى.' : message;
}

void _showSuccess(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

void _showNotice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

void _openPartyDetails(
  BuildContext context,
  AppController controller,
  PartyRecord party,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _PartyDetailsPage(
        controller: controller,
        partyId: party.id,
      ),
    ),
  );
}

enum _ShareChannel { whatsapp, sms }

Future<void> _previewAndLaunch(
  BuildContext context, {
  required PartyRecord party,
  required int balance,
  required _ShareChannel channel,
  required List<_StatementItem> statement,
}) async {
  final phone = party.phone?.trim();
  if (phone == null || phone.isEmpty) {
    _showNotice(context, 'أضف رقم هاتف للطرف أولًا.');
    return;
  }
  final message = _buildReminderMessage(party, balance, statement);
  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        channel == _ShareChannel.whatsapp
            ? Icons.chat_rounded
            : Icons.sms_outlined,
      ),
      title: const Text('معاينة الرسالة'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: .45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(message),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(
            channel == _ShareChannel.whatsapp ? 'فتح واتساب' : 'فتح الرسائل',
          ),
        ),
      ],
    ),
  );
  if (shouldOpen != true || !context.mounted) return;

  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = channel == _ShareChannel.whatsapp
      ? Uri.https(
          'wa.me',
          '/${digits.replaceFirst(RegExp(r'^\+'), '')}',
          <String, String>{'text': message},
        )
      : Uri(
          scheme: 'sms',
          path: digits,
          queryParameters: <String, String>{'body': message},
        );

  try {
    final available = await canLaunchUrl(uri);
    final launched =
        available && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showNotice(
        context,
        channel == _ShareChannel.whatsapp
            ? 'تعذر فتح واتساب على هذا الجهاز.'
            : 'تعذر فتح تطبيق الرسائل على هذا الجهاز.',
      );
    }
  } catch (error) {
    if (context.mounted) _showNotice(context, _friendlyError(error));
  }
}

String _buildReminderMessage(
  PartyRecord party,
  int balance,
  List<_StatementItem> statement,
) {
  final isCustomer = party.kind == PartyKind.customer;
  final buffer = StringBuffer()
    ..writeln('مرحبًا ${party.name}،')
    ..writeln()
    ..writeln(
      balance > 0
          ? (isCustomer
              ? 'المتبقي عليك: ${_money(balance)}'
              : 'المتبقي لك علينا: ${_money(balance)}')
          : balance == 0
              ? 'الحساب مسدّد بالكامل.'
              : (isCustomer
                  ? 'لديك رصيد: ${_money(balance.abs())}'
                  : 'لدينا رصيد عندك: ${_money(balance.abs())}'),
    );
  if (statement.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('آخر الحركات:');
    for (final item in statement.take(4)) {
      buffer.writeln(
        '• ${_date(item.entry.occurredAt)} — ${_entryTitle(item.entry.type)} — ${_money(item.entry.amount)}',
      );
    }
  }
  buffer
    ..writeln()
    ..write('رسالة من تطبيق يسير. يرجى مراجعة الحساب، وشكرًا لك.');
  return buffer.toString();
}
