import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/calendar/hindu_calendar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';

/// Sacred calendar with weekday, tithi and auspicious-day highlights.
class CalendarFeatureScreen extends ConsumerStatefulWidget {
  const CalendarFeatureScreen({super.key});

  @override
  ConsumerState<CalendarFeatureScreen> createState() =>
      _CalendarFeatureScreenState();
}

class _CalendarFeatureScreenState extends ConsumerState<CalendarFeatureScreen> {
  CalendarDay? _selected;

  static const _headers = ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final month = ref.watch(calendarMonthProvider);
    final daysAsync = ref.watch(calendarProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureCalendar)),
      body: AsyncBody(
        value: daysAsync,
        onRetry: () => ref.invalidate(calendarProvider),
        builder: (days) {
          final selected =
              _selected ??
              days.firstWhere((d) => d.isToday, orElse: () => days.first);
          final blanks = HinduCalendar.leadingBlanks(month);
          final monthLabel = '${_monthHi(month.month)} ${month.year}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              SoftCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(calendarMonthProvider.notifier)
                                .setMonth(DateTime(month.year, month.month - 1));
                            setState(() => _selected = null);
                          },
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            monthLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(calendarMonthProvider.notifier)
                                .setMonth(DateTime(month.year, month.month + 1));
                            setState(() => _selected = null);
                          },
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children:
                          _headers
                              .map(
                                (h) => Expanded(
                                  child: Center(
                                    child: Text(
                                      h,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.copyWith(
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: blanks + days.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemBuilder: (context, index) {
                        if (index < blanks) return const SizedBox.shrink();
                        final day = days[index - blanks];
                        final selectedDay =
                            selected.date.day == day.date.day &&
                            selected.date.month == day.date.month &&
                            selected.date.year == day.date.year;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selected = day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              color:
                                  day.isSpecial
                                      ? AppColors.orange
                                      : selectedDay
                                      ? AppColors.orangeSoft
                                      : AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  day.isToday
                                      ? Border.all(
                                        color: AppColors.orangeDeep,
                                        width: 2,
                                      )
                                      : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.date.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color:
                                        day.isSpecial
                                            ? Colors.white
                                            : AppColors.ink,
                                  ),
                                ),
                                if (day.isSpecial)
                                  const Text(
                                    '•',
                                    style: TextStyle(
                                      height: 0.8,
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        _LegendDot(color: AppColors.orange, label: 'शुभ दिन'),
                        SizedBox(width: 12),
                        _LegendDot(
                          color: AppColors.orangeDeep,
                          label: 'आज',
                          bordered: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selected.date.day} ${_monthHi(selected.date.month)} ${selected.date.year}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.calendar_view_day_rounded,
                      label: 'वार',
                      value:
                          locale == 'en'
                              ? selected.weekdayEn
                              : selected.weekdayHi,
                    ),
                    _InfoRow(
                      icon: Icons.brightness_2_rounded,
                      label: 'तिथि',
                      value:
                          locale == 'en' ? selected.tithiEn : selected.tithiHi,
                    ),
                    _InfoRow(
                      icon: Icons.auto_awesome_rounded,
                      label: 'विशेष',
                      value:
                          selected.isSpecial
                              ? selected.title
                              : (locale == 'en'
                                  ? 'Ordinary day'
                                  : 'सामान्य दिन'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selected.note,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'इस माह के शुभ दिन',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...days
                  .where((d) => d.isSpecial)
                  .map(
                    (day) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        onTap: () => setState(() => _selected = day),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.orangeSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${day.date.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orangeDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    locale == 'en'
                                        ? '${day.weekdayEn} · ${day.tithiEn}'
                                        : '${day.weekdayHi} · ${day.tithiHi}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  String _monthHi(int month) {
    const names = [
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर',
    ];
    return names[month - 1];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bordered ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: bordered ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
