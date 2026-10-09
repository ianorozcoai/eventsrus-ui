import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/data/booking_api.dart';
import '../../marketplace/data/quotation_api.dart';
import '../../marketplace/presentation/brand_header_bar.dart';
import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import 'event_bookings_tab.dart';
import 'event_chat_tab.dart';
import 'event_overview_tab.dart';
import 'event_quotations_tab.dart';

/// The planner's per-event hub: a header plus a 4-tab bottom nav (Overview,
/// Chat, Quotations, Booking) scoped to one event. Pushed from
/// EventsListScreen (tapping an event) or EventCreateScreen (right after
/// creating one). This bottom nav only ever appears once a specific event
/// is open - it's deliberately separate from both PlannerShell's own 3-tab
/// bar (Events/Notifications/Profile) and the vendor shell's bar, though it
/// shares the same always-branded BrandHeaderBar header both of those use
/// (no per-event title - the event's name is shown inside the Overview tab
/// instead).
class PlannerEventShell extends StatefulWidget {
  final int eventId;

  const PlannerEventShell({super.key, required this.eventId});

  @override
  State<PlannerEventShell> createState() => _PlannerEventShellState();
}

class _PlannerEventShellState extends State<PlannerEventShell> {
  PlannerEvent? _event;
  bool _loading = true;
  int _index = 0;
  int _unseenQuotations = 0;
  int _unseenBookings = 0;
  final _chatTabKey = GlobalKey<EventChatTabState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final event = await context.read<EventApi>().getEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // Unseen-tab badges are a secondary, non-blocking concern.
    try {
      final unseenQuotations =
          await context.read<QuotationApi>().unseenCountForEvent(widget.eventId);
      final unseenBookings =
          await context.read<BookingApi>().unseenCountForEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        _unseenQuotations = unseenQuotations;
        _unseenBookings = unseenBookings;
      });
    } catch (_) {}
  }

  void _onDestinationSelected(int index) {
    setState(() => _index = index);
    if (index == 2 && _unseenQuotations > 0) {
      context.read<QuotationApi>().markSeenForEvent(widget.eventId).catchError((_) {});
      setState(() => _unseenQuotations = 0);
    } else if (index == 3 && _unseenBookings > 0) {
      context.read<BookingApi>().markSeenForEvent(widget.eventId).catchError((_) {});
      setState(() => _unseenBookings = 0);
    }
  }

  void _goToChat() => _onDestinationSelected(1);

  Future<void> _onConversationStarted() async {
    await _chatTabKey.currentState?.reload();
    if (!mounted) return;
    _goToChat();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: BrandHeaderBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final event = _event;
    if (event == null) {
      return const Scaffold(
        appBar: BrandHeaderBar(),
        body: Center(child: Text('Event not found')),
      );
    }

    return Scaffold(
      appBar: const BrandHeaderBar(),
      body: Column(
        children: [
          // Overview already opens with the event's name as its own
          // heading, so this context strip is only needed on the other
          // three tabs where nothing else on screen says which event you're
          // looking at.
          if (_index != 0)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.name ?? 'Untitled event',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                EventOverviewTab(
                  event: event,
                  onGoToChat: _goToChat,
                  onConversationStarted: _onConversationStarted,
                ),
                EventChatTab(key: _chatTabKey, eventId: event.id),
                EventQuotationsTab(eventId: event.id),
                EventBookingsTab(eventId: event.id),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Overview',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: _unseenQuotations > 0
                ? Badge(
                    label: Text('$_unseenQuotations'),
                    child: const Icon(Icons.request_quote_outlined),
                  )
                : const Icon(Icons.request_quote_outlined),
            label: 'Quotations',
          ),
          NavigationDestination(
            icon: _unseenBookings > 0
                ? Badge(
                    label: Text('$_unseenBookings'),
                    child: const Icon(Icons.event_available_outlined),
                  )
                : const Icon(Icons.event_available_outlined),
            label: 'Booking',
          ),
        ],
      ),
    );
  }
}
