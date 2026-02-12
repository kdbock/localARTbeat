import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/audit_trail_service.dart';
import '../widgets/admin_drawer.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final AuditTrailService _auditService = AuditTrailService();
  String? _selectedCategory;
  final List<String> _categories = [
    'all',
    'user',
    'security',
    'content',
    'system',
    'payment'
  ];

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      appBar: core.EnhancedUniversalHeader(
        title: 'Audit Logs',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: LinearGradient(
          colors: [Colors.blueGrey[800]!, Colors.blueGrey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      child: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<AuditLog>>(
              stream: _auditService.getAuditLogs(limit: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var logs = snapshot.data ?? [];
                if (_selectedCategory != null && _selectedCategory != 'all') {
                  logs = logs
                      .where((log) => log.category == _selectedCategory)
                      .toList();
                }

                if (logs.isEmpty) {
                  return const Center(child: Text('No audit logs found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) =>
                      _buildAuditLogCard(logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Text('Category:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat.toUpperCase()),
                            selected: (_selectedCategory ?? 'all') == cat,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat : 'all';
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(AuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _getSeverityIcon(log.severity),
        title: Text(log.action,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Admin: ${log.userId}'),
            Text('Time: ${_formatDate(log.timestamp)}'),
            if (log.metadata.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Metadata: ${log.metadata.toString()}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: _getCategoryChip(log.category),
        isThreeLine: true,
      ),
    );
  }

  Widget _getSeverityIcon(String severity) {
    IconData icon;
    Color color;
    switch (severity.toLowerCase()) {
      case 'critical':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'info':
      default:
        icon = Icons.info;
        color = Colors.blue;
        break;
    }
    return Icon(icon, color: color);
  }

  Widget _getCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
