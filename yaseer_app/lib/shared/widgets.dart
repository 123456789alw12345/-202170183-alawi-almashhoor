import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A compact, asset-free mark that works at launcher and in-app sizes.
class YaseerLogo extends StatelessWidget {
  const YaseerLogo({
    super.key,
    this.size = 48,
    this.showWordmark = true,
    this.color,
    this.title = 'يسير',
    this.subtitle,
  });

  final double size;
  final bool showWordmark;
  final Color? color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final brandColor = color ?? Theme.of(context).colorScheme.primary;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [brandColor, YaseerColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: .2),
            blurRadius: size * .32,
            offset: Offset(0, size * .1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: size * .52,
          ),
          PositionedDirectional(
            start: size * .1,
            bottom: size * .08,
            child: Container(
              width: size * .32,
              height: size * .32,
              decoration: const BoxDecoration(
                color: YaseerColors.pro,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: YaseerColors.primaryDark,
                size: size * .22,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: 'شعار يسير',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (showWordmark) ...[
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .62),
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A page title that gracefully stacks its actions on small widths.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.primaryAction,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? primaryAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = <Widget>[
      ...actions,
      if (primaryAction != null) primaryAction!,
    ];

    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .64),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                if (actionWidgets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actionWidgets,
                  ),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heading),
              if (actionWidgets.isNotEmpty) ...[
                const SizedBox(width: 24),
                Wrap(spacing: 8, runSpacing: 8, children: actionWidgets),
              ],
            ],
          );
        },
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.color,
    this.trailing,
    this.onTap,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Material(
      color: highlighted
          ? accent.withValues(alpha: .08)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: YaseerRadii.card,
        side: BorderSide(
          color: highlighted
              ? accent.withValues(alpha: .3)
              : theme.colorScheme.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .62),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 8),
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .56),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.color,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: YaseerRadii.card,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: .6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  badge!,
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: .4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum YaseerStatusTone { neutral, success, warning, danger, info, pro }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = YaseerStatusTone.neutral,
    this.icon,
    this.color,
    this.outlined = false,
  });

  final String label;
  final YaseerStatusTone tone;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  Color _toneColor(BuildContext context) {
    if (color != null) return color!;
    return switch (tone) {
      YaseerStatusTone.success => YaseerColors.success,
      YaseerStatusTone.warning => YaseerColors.warning,
      YaseerStatusTone.danger => YaseerColors.danger,
      YaseerStatusTone.info => YaseerColors.info,
      YaseerStatusTone.pro => YaseerColors.pro,
      YaseerStatusTone.neutral =>
        Theme.of(context).colorScheme.onSurface.withValues(alpha: .64),
    };
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _toneColor(context);
    final foreground =
        tone == YaseerStatusTone.pro ? YaseerColors.primaryDark : chipColor;

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              outlined ? Colors.transparent : chipColor.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipColor.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackAction = actionLabel != null
        ? FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel!),
          )
        : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .62),
                  ),
                ),
              ],
              if (action != null || fallbackAction != null) ...[
                const SizedBox(height: 22),
                action ?? fallbackAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.currency = 'ر.س',
    this.decimalDigits = 2,
    this.showPlus = false,
    this.color,
    this.style,
    this.compact = false,
  });

  final num amount;
  final String currency;
  final int decimalDigits;
  final bool showPlus;
  final Color? color;
  final TextStyle? style;
  final bool compact;

  String _formatAmount() {
    if (compact && amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} م';
    }
    if (compact && amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} ألف';
    }

    final negative = amount < 0;
    final absolute = amount.abs().toStringAsFixed(decimalDigits);
    final parts = absolute.split('.');
    final digits = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      grouped.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) grouped.write(',');
    }
    final fraction = decimalDigits > 0 ? '.${parts.last}' : '';
    final sign = negative ? '-' : (showPlus && amount > 0 ? '+' : '');
    return '$sign$grouped$fraction';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ))
        ?.copyWith(color: color);
    final value = _formatAmount();

    return Semantics(
      label: '$value $currency',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value, style: effectiveStyle),
              TextSpan(
                text: '  $currency',
                style: effectiveStyle?.copyWith(
                  fontSize: (effectiveStyle.fontSize ?? 16) * .72,
                  fontWeight: FontWeight.w700,
                  color: color ??
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .6),
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || subtitle != null || trailing != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!, style: theme.textTheme.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: .6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 18),
          ],
          child,
        ],
      ),
    );

    return Padding(
      padding: margin,
      child: Material(
        color: backgroundColor ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: YaseerRadii.card,
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'ابحث بالاسم أو الرقم…',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
    this.trailing,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;
  final Widget? trailing;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _controller.removeListener(_refresh);
    if (oldWidget.controller == null) _controller.dispose();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: widget.trailing ??
            (_controller.text.isNotEmpty
                ? IconButton(
                    onPressed: _clear,
                    tooltip: 'مسح البحث',
                    icon: const Icon(Icons.close_rounded),
                  )
                : null),
      ),
    );
  }
}

/// Centers page content and applies responsive gutters.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1280,
    this.padding,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: width >= 1200 ? 32 : (width >= 600 ? 24 : 16),
          vertical: width >= 600 ? 24 : 16,
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}

/// A light page scaffold for standalone flows such as onboarding and forms.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.appBar,
    this.actions = const [],
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.maxContentWidth = 1280,
    this.padding,
    this.scrollable = false,
    this.safeArea = true,
    this.forceRtl = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final PreferredSizeWidget? appBar;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final double maxContentWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool safeArea;
  final bool forceRtl;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    Widget page = ResponsiveContent(
      maxWidth: maxContentWidth,
      padding: padding,
      child: body,
    );
    if (scrollable) page = SingleChildScrollView(child: page);
    if (safeArea) page = SafeArea(child: page);

    final scaffold = Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar ??
          (title == null
              ? null
              : AppBar(title: Text(title!), actions: actions)),
      drawer: drawer,
      body: page,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );

    if (!forceRtl) return scaffold;
    return Directionality(textDirection: TextDirection.rtl, child: scaffold);
  }
}

class YaseerNavigationItem {
  const YaseerNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? tooltip;
}

/// A controller-free adaptive shell: bottom navigation on phones and a
/// navigation rail on larger screens.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.body,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.mobileTitle,
    this.mobileActions = const [],
    this.floatingActionButton,
    this.railHeader,
    this.railFooter,
    this.showNavigation = true,
    this.forceRtl = true,
    this.desktopBreakpoint = 960,
    this.extendedRailBreakpoint = 1280,
  });

  final Widget body;
  final List<YaseerNavigationItem> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final String? mobileTitle;
  final List<Widget> mobileActions;
  final Widget? floatingActionButton;
  final Widget? railHeader;
  final Widget? railFooter;
  final bool showNavigation;
  final bool forceRtl;
  final double desktopBreakpoint;
  final double extendedRailBreakpoint;

  int get _safeIndex {
    if (destinations.isEmpty) return 0;
    if (selectedIndex < 0) return 0;
    if (selectedIndex >= destinations.length) return destinations.length - 1;
    return selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    Widget shell = LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= desktopBreakpoint;
        final hasNavigation = showNavigation && destinations.isNotEmpty;

        if (desktop) {
          final extended = constraints.maxWidth >= extendedRailBreakpoint;
          return Scaffold(
            body: Row(
              children: [
                if (hasNavigation) ...[
                  SafeArea(
                    child: NavigationRail(
                      extended: extended,
                      minExtendedWidth: 220,
                      selectedIndex: _safeIndex,
                      onDestinationSelected: onDestinationSelected,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: railHeader ??
                            YaseerLogo(
                              size: 42,
                              showWordmark: extended,
                            ),
                      ),
                      trailing: railFooter == null
                          ? null
                          : Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: railFooter,
                                ),
                              ),
                            ),
                      destinations: [
                        for (final item in destinations)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon ?? item.icon),
                            label: Text(item.label),
                            padding: const EdgeInsets.symmetric(vertical: 3),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        return Scaffold(
          appBar: mobileTitle == null && mobileActions.isEmpty
              ? null
              : AppBar(
                  title: mobileTitle == null
                      ? const YaseerLogo(size: 36)
                      : Text(mobileTitle!),
                  actions: mobileActions,
                ),
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: hasNavigation
              ? NavigationBar(
                  selectedIndex: _safeIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    for (final item in destinations)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon ?? item.icon),
                        label: item.label,
                        tooltip: item.tooltip,
                      ),
                  ],
                )
              : null,
        );
      },
    );

    if (forceRtl) {
      shell = Directionality(textDirection: TextDirection.rtl, child: shell);
    }
    return shell;
  }
}
