import 'package:flutter/material.dart';
import '../models/user_admin_model.dart';
import '../models/content_model.dart';
import '../models/transaction_model.dart';
import 'package:easy_localization/easy_localization.dart';

/// Admin search modal for searching across users, content, and transactions
class AdminSearchModal extends StatefulWidget {
  final String? initialQuery;
  final List<UserAdminModel> users;
  final List<ContentModel> content;
  final List<TransactionModel> transactions;
  final void Function(UserAdminModel) onUserSelected;

  const AdminSearchModal({
    super.key,
    this.initialQuery,
    required this.users,
    required this.content,
    required this.transactions,
    required this.onUserSelected,
  });

  @override
  State<AdminSearchModal> createState() => _AdminSearchModalState();
}

class _AdminSearchModalState extends State<AdminSearchModal>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;

  List<UserAdminModel> _filteredUsers = [];
  List<ContentModel> _filteredContent = [];
  List<TransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _tabController = TabController(length: 3, vsync: this);

    if (widget.initialQuery?.isNotEmpty == true) {
      _performSearch(widget.initialQuery!);
    } else {
      _resetFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _resetFilters();
      return;
    }

    final lowerQuery = query.toLowerCase();

    setState(() {
      _filteredUsers = widget.users
          .where((user) =>
              user.email.toLowerCase().contains(lowerQuery) ||
              user.username.toLowerCase().contains(lowerQuery) ||
              user.fullName.toLowerCase().contains(lowerQuery))
          .toList();

      _filteredContent = widget.content
          .where((content) =>
              content.title.toLowerCase().contains(lowerQuery) ||
              content.description.toLowerCase().contains(lowerQuery) ||
              content.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();

      _filteredTransactions = widget.transactions
          .where((transaction) =>
              transaction.id.toLowerCase().contains(lowerQuery) ||
              (transaction.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              transaction.userName.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _filteredUsers = widget.users;
      _filteredContent = widget.content;
      _filteredTransactions = widget.transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'admin_search_modal_title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'admin_search_modal_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _resetFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _performSearch,
            ),
          ),

          const SizedBox(height: 16),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Users (${_filteredUsers.length})'),
              Tab(text: 'Content (${_filteredContent.length})'),
              Tab(text: 'Transactions (${_filteredTransactions.length})'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildContentTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'admin_search_modal_no_users'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                user.username.isNotEmpty
                    ? user.username[0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.fullName.isNotEmpty ? user.fullName : user.username,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text(
                  'Status: ${user.isSuspended ? 'suspended' : user.isDeleted ? 'deleted' : 'active'}',
                  style: TextStyle(
                    color: user.isSuspended || user.isDeleted
                        ? Colors.red
                        : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onUserSelected(user),
          ),
        );
      },
    );
  }

  Widget _buildContentTab() {
    if (_filteredContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.content_copy_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'admin_search_modal_no_content'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredContent.length,
      itemBuilder: (context, index) {
        final content = _filteredContent[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getContentIcon(content.type),
                color: Colors.purple[800],
              ),
            ),
            title: Text(
              content.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Type: ${content.type} • Status: ${content.status}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle content selection
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('admin_search_selected_content'
                      .tr(namedArgs: {'title': content.title})),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'admin_search_modal_no_transactions'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.attach_money,
                color: Colors.green[800],
              ),
            ),
            title: Text(
              transaction.description ?? 'No description',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('admin_search_amount'.tr(namedArgs: {
                  'amount': transaction.amount.toStringAsFixed(2)
                })),
                Text(
                  'User: ${transaction.userName}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle transaction selection
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('admin_search_selected_transaction'
                      .tr(namedArgs: {'id': transaction.id})),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getContentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'artwork':
        return Icons.palette;
      case 'post':
        return Icons.article;
      case 'event':
        return Icons.event;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.content_copy;
    }
  }
}
