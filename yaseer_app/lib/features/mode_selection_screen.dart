import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../shared/widgets.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key, required this.onSelect});

  final ValueChanged<AppMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color(0xFFE7F5F2), Color(0xFFF7F9F8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 48 : 20,
                  vertical: wide ? 44 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      children: [
                        const YaseerLogo(showWordmark: true),
                        const SizedBox(height: 34),
                        Text(
                          'اختر ما يناسب عملك',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF14201E),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ابدأ بما تحتاجه فقط، وتوسع وقت ما تحتاج.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF60706C),
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يمكنك تغيير النظام لاحقًا، وبياناتك تبقى محفوظة.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF60706C),
                                  ),
                        ),
                        SizedBox(height: wide ? 42 : 28),
                        if (wide)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ModeCard(
                                    title: 'التطبيق الأساسي',
                                    eyebrow: 'دفتر حسابات ذكي',
                                    description:
                                        'ديون وحسابات العملاء والموردين بكل بساطة.',
                                    features: const [
                                      'عملاء وديون ودفعات',
                                      'موردون وقبض وصرف',
                                      'مواعيد وتذكيرات',
                                    ],
                                    icon: Icons.menu_book_rounded,
                                    buttonLabel: 'ابدأ بالأساسي',
                                    color: const Color(0xFF0F766E),
                                    onTap: () => onSelect(AppMode.basic),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _ModeCard(
                                    title: 'التطبيق الاحترافي',
                                    eyebrow: 'إدارة كاملة للمحل',
                                    description:
                                        'مبيعات ومخزون وأرباح ونقطة بيع سريعة.',
                                    features: const [
                                      'نقطة بيع وفواتير',
                                      'أصناف ومخزون وباركود',
                                      'أرباح وتقارير يومية',
                                    ],
                                    icon: Icons.storefront_rounded,
                                    buttonLabel: 'ابدأ بالاحترافي',
                                    color: const Color(0xFF0B4F4A),
                                    recommended: true,
                                    onTap: () => onSelect(AppMode.professional),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          _ModeCard(
                            title: 'التطبيق الأساسي',
                            eyebrow: 'دفتر حسابات ذكي',
                            description:
                                'ديون وحسابات العملاء والموردين بكل بساطة.',
                            features: const [
                              'عملاء وديون ودفعات',
                              'موردون وقبض وصرف',
                              'مواعيد وتذكيرات',
                            ],
                            icon: Icons.menu_book_rounded,
                            buttonLabel: 'ابدأ بالأساسي',
                            color: const Color(0xFF0F766E),
                            onTap: () => onSelect(AppMode.basic),
                          ),
                          const SizedBox(height: 16),
                          _ModeCard(
                            title: 'التطبيق الاحترافي',
                            eyebrow: 'إدارة كاملة للمحل',
                            description:
                                'مبيعات ومخزون وأرباح ونقطة بيع سريعة.',
                            features: const [
                              'نقطة بيع وفواتير',
                              'أصناف ومخزون وباركود',
                              'أرباح وتقارير يومية',
                            ],
                            icon: Icons.storefront_rounded,
                            buttonLabel: 'ابدأ بالاحترافي',
                            color: const Color(0xFF0B4F4A),
                            recommended: true,
                            onTap: () => onSelect(AppMode.professional),
                          ),
                        ],
                        const SizedBox(height: 26),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 18, color: Color(0xFF60706C)),
                            SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'بياناتك محفوظة محليًا على جهازك وتعمل حتى بدون إنترنت',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF60706C), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.features,
    required this.icon,
    required this.buttonLabel,
    required this.color,
    required this.onTap,
    this.recommended = false,
  });

  final String title;
  final String eyebrow;
  final String description;
  final List<String> features;
  final IconData icon;
  final String buttonLabel;
  final Color color;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title، $description',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: recommended
                      ? const Color(0xFFF4B740)
                      : const Color(0xFFD7E1DE),
                  width: recommended ? 1.5 : 1),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F0B4F4A),
                    blurRadius: 24,
                    offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Spacer(),
                    if (recommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D3),
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('الأكثر شمولًا',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF7A4A00))),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(eyebrow,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 6),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF60706C), height: 1.55)),
                const SizedBox(height: 20),
                for (final feature in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 19, color: color),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text(feature,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: onTap,
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
