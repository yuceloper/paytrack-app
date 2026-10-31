import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/assistant/presentation/pages/assistant_page.dart';
import '../features/dashboard/application/dashboard_providers.dart';

import '../features/calendar/presentation/pages/calendar_page.dart';
import '../features/cashflow/presentation/pages/cash_flow_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/debts/presentation/pages/debt_hub_page.dart';
import '../features/incomes/presentation/pages/incomes_page.dart';
import '../features/payments/presentation/pages/payments_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _revision = 0;

  static const _pages = [
    DashboardPage(),
    CalendarPage(),
    CashFlowPage(),
    PaymentsPage(),
    IncomesPage(),
    DebtHubPage(),
  ];

  Future<void> _openAssistant() async {
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const AssistantPage()));
    if (!mounted || saved != true) return;
    ProviderScope.containerOf(context).invalidate(dashboardProvider);
    setState(() {
      _revision++;
      _index = 3;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gider eklendi.')));
  }

  Future<void> _openMore() async {
    final selected = await showModalBottomSheet<int>(
      context: context, showDragHandle: true,
      builder: (context) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.swap_vert), title: const Text('Akış'),
            selected: _index == 2, onTap: () => Navigator.pop(context, 2)),
          ListTile(leading: const Icon(Icons.trending_up), title: const Text('Gelirler'),
            selected: _index == 4, onTap: () => Navigator.pop(context, 4)),
          ListTile(leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Borçlar'), selected: _index == 5,
            onTap: () => Navigator.pop(context, 5)),
          const SizedBox(height: 12),
        ],
      )),
    );
    if (selected != null && mounted) setState(() => _index = selected);
  }

  Widget _destination(String label, IconData icon, bool selected, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(child: Semantics(selected: selected, button: true,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: selected ? colors.primary : colors.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.primary : colors.onSurfaceVariant)),
          ]),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(key: ValueKey(_revision), index: _index, children: _pages),
      bottomNavigationBar: Material(
        color: colors.surfaceContainer,
        child: SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            _destination('Ana Sayfa', Icons.home_outlined, _index == 0,
              () => setState(() => _index = 0)),
            _destination('Takvim', Icons.calendar_month_outlined, _index == 1,
              () => setState(() => _index = 1)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 64, height: 64,
                  child: FloatingActionButton(
                    heroTag: 'paytrack-assistant',
                    tooltip: 'PayTrack Asistan', shape: const CircleBorder(),
                    backgroundColor: colors.primary, foregroundColor: colors.onPrimary,
                    elevation: 3, onPressed: _openAssistant,
                    child: const Icon(Icons.auto_awesome, size: 30),
                  )),
                const SizedBox(height: 4),
                Text('Asistan', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: colors.primary)),
              ]),
            ),
            _destination('Ödemeler', Icons.receipt_long_outlined, _index == 3,
              () => setState(() => _index = 3)),
            _destination('Diğer', Icons.more_horiz, [2, 4, 5].contains(_index), _openMore),
          ]),
        )),
      ),
    );
  }
}
