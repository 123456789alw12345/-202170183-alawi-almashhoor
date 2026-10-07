import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../shared/widgets.dart';
import '../state/app_controller.dart';
import 'basic/basic_pages.dart';
import 'professional/pro_pages.dart';

class YaseerShell extends StatefulWidget {
  const YaseerShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<YaseerShell> createState() => _YaseerShellState();
}

class _YaseerShellState extends State<YaseerShell> {
  int _index = 0;

  AppMode get _mode => widget.controller.mode ?? AppMode.basic;

  List<_Destination> get _destinations => _mode == AppMode.basic
      ? const [
          _Destination('الرئيسية', Icons.home_rounded, Icons.home_outlined),
          _Destination(
              'العملاء', Icons.people_rounded, Icons.people_outline_rounded),
          _Destination('الموردون', Icons.local_shipping_rounded,
              Icons.local_shipping_outlined),
          _Destination(
              'الحركة', Icons.swap_horiz_rounded, Icons.swap_horiz_outlined),
          _Destination(
              'المزيد', Icons.grid_view_rounded, Icons.grid_view_outlined),
        ]
      : const [
          _Destination('الرئيسية', Icons.home_rounded, Icons.home_outlined),
          _Destination('البيع', Icons.point_of_sale_rounded,
              Icons.point_of_sale_outlined),
          _Destination('الديون', Icons.receipt_long_rounded,
              Icons.receipt_long_outlined),
          _Destination(
              'الأصناف', Icons.inventory_2_rounded, Icons.inventory_2_outlined),
          _Destination(
              'المزيد', Icons.grid_view_rounded, Icons.grid_view_outlined),
        ];

  List<Widget> get _pages => _mode == AppMode.basic
      ? [
          BasicDashboardPage(controller: widget.controller),
          PartiesPage(controller: widget.controller, kind: PartyKind.customer),
          PartiesPage(controller: widget.controller, kind: PartyKind.supplier),
          ActivityPage(controller: widget.controller),
          BasicMorePage(
              controller: widget.controller, onSwitchMode: _switchMode),
        ]
      : [
          ProfessionalDashboardPage(controller: widget.controller),
          PosPage(controller: widget.controller),
          DebtsPage(controller: widget.controller),
          ProductsPage(controller: widget.controller),
          ProfessionalMorePage(
              controller: widget.controller, onSwitchMode: _switchMode),
        ];

  void _switchMode() {
    widget.controller.resetMode();
  }

  void _select(int value) {
    if (value == _index) return;
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final pages = _pages;
    if (_index >= pages.length) _index = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final railExtended = constraints.maxWidth >= 1180;
        final content = IndexedStack(index: _index, children: pages);

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 68,
            titleSpacing: desktop ? 28 : 16,
            title: Row(
              children: [
                const YaseerLogo(size: 38, showWordmark: true),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _mode == AppMode.professional
                        ? const Color(0xFFFFF3D3)
                        : const Color(0xFFE7F5F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _mode == AppMode.professional ? 'الاحترافي' : 'الأساسي',
                    style: TextStyle(
                      color: _mode == AppMode.professional
                          ? const Color(0xFF7A4A00)
                          : const Color(0xFF0B4F4A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (desktop) ...[
                  const SizedBox(width: 12),
                  const _LocalStatus(),
                ],
              ],
            ),
          ),
          body: desktop
              ? Row(
                  children: [
                    NavigationRail(
                      extended: railExtended,
                      minExtendedWidth: 220,
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      labelType: railExtended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      groupAlignment: -0.72,
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 18),
                        child: Icon(
                          _mode == AppMode.professional
                              ? Icons.workspace_premium_rounded
                              : Icons.auto_awesome_rounded,
                          color: _mode == AppMode.professional
                              ? const Color(0xFFF4B740)
                              : const Color(0xFF0F766E),
                        ),
                      ),
                      destinations: [
                        for (final item in destinations)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final item in destinations)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _LocalStatus extends StatelessWidget {
  const _LocalStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD7E1DE)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done_outlined, size: 16, color: Color(0xFF147A52)),
          SizedBox(width: 6),
          Text('محفوظ محليًا',
              style: TextStyle(fontSize: 12, color: Color(0xFF60706C))),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.selectedIcon, this.icon);

  final String label;
  final IconData selectedIcon;
  final IconData icon;
}
