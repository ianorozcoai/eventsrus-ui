import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../data/coordinator_api.dart';
import '../data/models/coordinator_question.dart';

/// Per-event Q&A with the Events Coordinator - the mobile equivalent of
/// eventsrus-web's planner/events.html Events Coordinator panel. A scoped
/// AI ideas/advice assistant: general event-planning brainstorming only,
/// never vendor pricing/availability/negotiation (see CoordinatorService's
/// system prompt). Capped at a daily question count that resets at
/// midnight Asia/Manila - the input is disabled once that count hits zero,
/// same as the web app.
class EventCoordinatorScreen extends StatefulWidget {
  final int eventId;
  final String? eventName;

  const EventCoordinatorScreen({super.key, required this.eventId, this.eventName});

  @override
  State<EventCoordinatorScreen> createState() => _EventCoordinatorScreenState();
}

class _EventCoordinatorScreenState extends State<EventCoordinatorScreen> {
  List<CoordinatorQuestion> _questions = [];
  int? _questionsRemainingToday;
  int? _dailyLimit;
  bool _loading = true;
  bool _asking = false;
  String? _error;

  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final history = await context.read<CoordinatorApi>().listHistory(widget.eventId);
      if (!mounted) return;
      setState(() {
        _questions = history.questions;
        _questionsRemainingToday = history.questionsRemainingToday;
        _dailyLimit = history.dailyLimit;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _asking) return;

    setState(() {
      _asking = true;
      _error = null;
    });
    try {
      final answer = await context.read<CoordinatorApi>().ask(widget.eventId, question);
      if (!mounted) return;
      _questionController.clear();
      setState(() {
        _questions = [..._questions, answer];
        if (_questionsRemainingToday != null) _questionsRemainingToday = _questionsRemainingToday! - 1;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      // A 429 here means the limit was hit between page-load and this ask -
      // refresh the remaining count so the input disables itself correctly.
      if (e.statusCode == 429) await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _questionsRemainingToday;
    final limit = _dailyLimit;
    final canAsk = remaining == null || remaining > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Coordinator'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              remaining != null && limit != null
                  ? '$remaining of $limit questions left today'
                  : widget.eventName ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _questions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Ask for event ideas, themes, or general planning advice below - '
                              "the coordinator won't discuss supplier pricing or availability, "
                              'that stays in your chat with each supplier.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) => _QuestionAndAnswer(entry: _questions[index]),
                        ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: canAsk
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _questionController,
                                  decoration: const InputDecoration(hintText: 'Ask for event ideas or advice...'),
                                  maxLength: 1000,
                                  enabled: !_asking,
                                  onSubmitted: (_) => _ask(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _asking
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : FilledButton(onPressed: _ask, child: const Text('Ask')),
                            ],
                          )
                        : const Text(
                            "You've reached today's question limit. Try again tomorrow.",
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QuestionAndAnswer extends StatelessWidget {
  final CoordinatorQuestion entry;

  const _QuestionAndAnswer({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(entry.question),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(entry.answer),
            ),
          ),
        ],
      ),
    );
  }
}
