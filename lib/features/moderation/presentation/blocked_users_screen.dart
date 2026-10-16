import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../data/moderation_api.dart';
import '../data/moderation_models.dart';

/// People the signed-in user has blocked, with a way to unblock them.
/// Reached from the header menu (three dots) in both the planner and vendor shells.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blocked = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blocked = await context.read<ModerationApi>().listBlocked();
      if (!mounted) return;
      setState(() {
        _blocked = blocked;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    final api = context.read<ModerationApi>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await api.unblockUser(user.userId);
      if (!mounted) return;
      setState(() => _blocked = _blocked.where((b) => b.userId != user.userId).toList());
      messenger.showSnackBar(SnackBar(content: Text('${user.displayName} is unblocked.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _blocked.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('You have not blocked anyone.'),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _blocked.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _blocked[index];
                        return ListTile(
                          title: Text(user.displayName),
                          trailing: TextButton(
                            onPressed: () => _unblock(user),
                            child: const Text('Unblock'),
                          ),
                        );
                      },
                    ),
    );
  }
}
