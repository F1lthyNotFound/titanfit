import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_image.dart';
import '../../widgets/week_day_strip.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late List<WeekDayItem> _weekDays;
  String? _selectedDate;
  List<MemberClass> _classes = [];
  List<UpcomingBooking> _upcoming = [];
  bool _loadingClasses = true;
  bool _loadingUpcoming = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _weekDays = WeekDayItem.currentWeek();
    _selectedDate = _weekDays.where((d) => d.isToday).map((d) => d.date).firstOrNull ??
        (_weekDays.isNotEmpty ? _weekDays.first.date : null);
    _loadClasses();
    _loadUpcoming();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null || _selectedDate == null) return;
    setState(() => _loadingClasses = true);
    final list = await MemberService.forFlavor(flavor).fetchClasses(date: _selectedDate!);
    if (!mounted) return;
    setState(() {
      _classes = list;
      _loadingClasses = false;
    });
  }

  Future<void> _loadUpcoming() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    setState(() => _loadingUpcoming = true);
    final list = await MemberService.forFlavor(flavor).fetchUpcomingBookings();
    if (!mounted) return;
    setState(() {
      _upcoming = list;
      _loadingUpcoming = false;
    });
  }

  Future<void> _enroll(MemberClass cls) async {
    final flavor = GymFlavorService.instance.flavor!;
    final res = await MemberService.forFlavor(flavor).enrollClass(cls.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Done')),
    );
    await _loadClasses();
    await _loadUpcoming();
  }

  Future<void> _cancel(UpcomingBooking booking) async {
    final flavor = GymFlavorService.instance.flavor!;
    final res = await MemberService.forFlavor(flavor).unenrollClass(booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Done')),
    );
    await _loadUpcoming();
    await _loadClasses();
  }

  void _openClassDetail(MemberClass cls) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClassDetailSheet(
        cls: cls,
        onEnroll: () async {
          Navigator.pop(ctx);
          await _enroll(cls);
        },
        onCancel: cls.isEnrolled && cls.enrollmentId != null
            ? () async {
                Navigator.pop(ctx);
                final flavor = GymFlavorService.instance.flavor!;
                final res = await MemberService.forFlavor(flavor).unenrollClass(cls.enrollmentId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Done')),
                );
                await _loadUpcoming();
                await _loadClasses();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flavor = GymFlavorService.instance.flavor!;

    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Classes'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          RefreshIndicator(
            onRefresh: _loadClasses,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Book at ${flavor.gymName}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/appointment');
                    if (mounted) {
                      await _loadUpcoming();
                      await _loadClasses();
                    }
                  },
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Book appointment with coach'),
                ),
                const SizedBox(height: 16),
                WeekDayStrip(
                  days: _weekDays,
                  selectedDate: _selectedDate,
                  onSelect: (date) {
                    setState(() => _selectedDate = date);
                    _loadClasses();
                  },
                ),
                const SizedBox(height: 16),
                if (_loadingClasses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_classes.isEmpty)
                  Text('No classes this day.', style: theme.textTheme.bodyMedium)
                else
                  ..._classes.map(
                    (cls) => _ClassCard(
                      cls: cls,
                      onTap: () => _openClassDetail(cls),
                      onEnroll: () => _enroll(cls),
                    ),
                  ),
              ],
            ),
          ),
          RefreshIndicator(
            onRefresh: _loadUpcoming,
            child: _loadingUpcoming
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  )
                : _upcoming.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 48),
                          Center(child: Text('No upcoming bookings.', style: theme.textTheme.bodyMedium)),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _upcoming.length,
                        itemBuilder: (context, i) {
                          final b = _upcoming[i];
                          return _UpcomingCard(
                            booking: b,
                            onCancel: b.canCancel ? () => _cancel(b) : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.cls,
    required this.onTap,
    required this.onEnroll,
  });

  final MemberClass cls;
  final VoidCallback onTap;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flavor = GymFlavorService.instance.flavor;
    final hasCover = cls.coverPhoto.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasCover)
              MediaImage(
                source: cls.coverPhoto,
                apiBase: flavor?.apiBase,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.timeLabel,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.title,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (cls.coachName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(cls.coachName, style: theme.textTheme.bodySmall),
                          ),
                        if (cls.exclusiveMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Members only',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (cls.maxCapacity > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${cls.spotsLeft} spots left',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (cls.isEnrolled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Enrolled', style: theme.textTheme.labelSmall),
                    )
                  else
                    FilledButton(
                      onPressed: cls.isFull ? null : onEnroll,
                      child: Text(cls.isFull ? 'Full' : 'Enroll'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassDetailSheet extends StatelessWidget {
  const _ClassDetailSheet({
    required this.cls,
    required this.onEnroll,
    this.onCancel,
  });

  final MemberClass cls;
  final VoidCallback onEnroll;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flavor = GymFlavorService.instance.flavor;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(
        color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (cls.coverPhoto.isNotEmpty)
              MediaImage(
                source: cls.coverPhoto,
                apiBase: flavor?.apiBase,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
              ),
            if (cls.coverPhoto.isNotEmpty) const SizedBox(height: 16),
            Text(cls.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '${cls.timeLabel} – ${cls.endTimeLabel}',
              style: theme.textTheme.titleMedium,
            ),
            if (cls.coachName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Text(cls.coachName, style: theme.textTheme.bodyLarge),
                ],
              ),
            ],
            if (cls.maxCapacity > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${cls.enrolled}/${cls.maxCapacity} enrolled · ${cls.spotsLeft} spots left',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
            if (cls.exclusiveMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Members only',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (cls.isEnrolled) ...[
              FilledButton(onPressed: onCancel, child: const Text('Cancel enrollment')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ] else
              FilledButton(
                onPressed: cls.isFull ? null : onEnroll,
                child: Text(cls.isFull ? 'Class is full' : 'Enroll in class'),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.booking, this.onCancel});

  final UpcomingBooking booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    var when = booking.startsAt;
    if (when.length >= 16) {
      when = when.substring(0, 16).replaceFirst('T', ' · ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(when, style: theme.textTheme.bodySmall),
                if (booking.coachName.isNotEmpty)
                  Text(booking.coachName, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          if (onCancel != null)
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
