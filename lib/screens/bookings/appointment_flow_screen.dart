import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_image.dart';
import '../../widgets/week_day_strip.dart';

class AppointmentFlowScreen extends StatefulWidget {
  const AppointmentFlowScreen({super.key});

  @override
  State<AppointmentFlowScreen> createState() => _AppointmentFlowScreenState();
}

class _AppointmentFlowScreenState extends State<AppointmentFlowScreen> {
  int _step = 0;
  List<MemberCoach> _coaches = [];
  List<CoachPricingTier> _pricing = [];
  List<CoachSlot> _slots = [];
  late List<WeekDayItem> _weekDays;
  String? _selectedDate;
  MemberCoach? _selectedCoach;
  CoachSlot? _selectedSlot;
  CoachPricingTier? _selectedPricing;
  bool _loading = true;
  bool _loadingSlots = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _weekDays = WeekDayItem.currentWeek();
    _selectedDate = _weekDays.where((d) => d.isToday).map((d) => d.date).firstOrNull ??
        (_weekDays.isNotEmpty ? _weekDays.first.date : null);
    _loadCoaches();
  }

  Future<void> _loadCoaches() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    setState(() => _loading = true);
    final list = await MemberService.forFlavor(flavor).fetchCoaches();
    if (!mounted) return;
    setState(() {
      _coaches = list;
      _loading = false;
    });
  }

  Future<void> _selectCoach(MemberCoach coach) async {
    final flavor = GymFlavorService.instance.flavor!;
    setState(() {
      _selectedCoach = coach;
      _selectedSlot = null;
      _selectedPricing = null;
      _step = 1;
      _loadingSlots = true;
    });
    final pricing = await MemberService.forFlavor(flavor).fetchCoachPricing(coach.id);
    if (!mounted) return;
    setState(() {
      _pricing = pricing;
      _selectedPricing = pricing.where((p) => p.isDefault).firstOrNull ?? (pricing.isNotEmpty ? pricing.first : null);
    });
    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    final flavor = GymFlavorService.instance.flavor;
    final coach = _selectedCoach;
    if (flavor == null || coach == null || _selectedDate == null) return;
    setState(() => _loadingSlots = true);
    final slots = await MemberService.forFlavor(flavor).fetchCoachAvailability(
      coachId: coach.id,
      date: _selectedDate!,
    );
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _loadingSlots = false;
      _selectedSlot = null;
    });
  }

  String _slotStartsAt(CoachSlot slot) {
    return '${_selectedDate!} ${slot.start}:00';
  }

  String _slotEndsAt(CoachSlot slot, CoachPricingTier tier) {
    final duration = tier.baseMinutes >= 30 ? tier.baseMinutes : 30;
    final endMin = slot.startMin + duration;
    final hours = (endMin ~/ 60) % 24;
    final mins = endMin % 60;
    return '${_selectedDate!} ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
  }

  Future<void> _confirmBooking() async {
    final flavor = GymFlavorService.instance.flavor;
    final coach = _selectedCoach;
    final slot = _selectedSlot;
    final pricing = _selectedPricing;
    if (flavor == null || coach == null || slot == null || pricing == null) return;

    setState(() => _submitting = true);
    final res = await MemberService.forFlavor(flavor).bookAppointment(
      coachId: coach.id,
      pricingId: pricing.id,
      startsAt: _slotStartsAt(slot),
      endsAt: _slotEndsAt(slot, pricing),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message.isNotEmpty ? res.message : (res.ok ? 'Booked' : 'Failed'))),
    );
    if (res.ok) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Book appointment'),
        backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step -= 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _step == 0
              ? _buildCoachStep(theme, isDark)
              : _step == 1
                  ? _buildScheduleStep(theme, isDark)
                  : _buildConfirmStep(theme, isDark),
    );
  }

  Widget _buildCoachStep(ThemeData theme, bool isDark) {
    if (_coaches.isEmpty) {
      return Center(child: Text('No coaches available.', style: theme.textTheme.bodyLarge));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _coaches.length,
      itemBuilder: (context, i) {
        final coach = _coaches[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: coach.avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: MediaImage(
                        source: coach.avatarUrl,
                        apiBase: GymFlavorService.instance.flavor?.apiBase,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : Text(
                      coach.displayName.isNotEmpty ? coach.displayName[0].toUpperCase() : '?',
                      style: theme.textTheme.titleMedium,
                    ),
            ),
            title: Text(coach.displayName, style: theme.textTheme.titleMedium),
            subtitle: const Text('Tap to view availability'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectCoach(coach),
          ),
        );
      },
    );
  }

  Widget _buildScheduleStep(ThemeData theme, bool isDark) {
    final coach = _selectedCoach!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Coach: ${coach.displayName}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        WeekDayStrip(
          days: _weekDays,
          selectedDate: _selectedDate,
          onSelect: (date) {
            setState(() => _selectedDate = date);
            _loadSlots();
          },
        ),
        const SizedBox(height: 16),
        if (_loadingSlots)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_slots.where((s) => s.isFree).isEmpty)
          Text('No available slots this day.', style: theme.textTheme.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots.map((slot) {
              final free = slot.isFree;
              final selected = _selectedSlot == slot;
              return FilterChip(
                label: Text('${slot.start} – ${slot.end}'),
                selected: selected,
                onSelected: free
                    ? (_) => setState(() => _selectedSlot = slot)
                    : null,
                showCheckmark: false,
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _selectedSlot != null ? () => setState(() => _step = 2) : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(ThemeData theme, bool isDark) {
    final coach = _selectedCoach!;
    final slot = _selectedSlot!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Confirm booking', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _SummaryRow(label: 'Coach', value: coach.displayName),
        _SummaryRow(label: 'Date', value: _selectedDate ?? ''),
        _SummaryRow(label: 'Time', value: '${slot.start} – ${slot.end}'),
        const SizedBox(height: 16),
        Text('Pricing tier', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ..._pricing.map((tier) {
          final selected = _selectedPricing == tier;
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            selected: selected,
            selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            title: Text(tier.name.isNotEmpty ? tier.name : 'Standard'),
            subtitle: Text('₱${tier.basePrice.toStringAsFixed(0)} / ${tier.baseMinutes} min'),
            trailing: selected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
            onTap: () => setState(() => _selectedPricing = tier),
          );
        }),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting || _selectedPricing == null ? null : _confirmBooking,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm & book'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
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
