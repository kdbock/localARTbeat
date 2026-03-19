# ArtBeat App - English Text on All Screens
*Generated on: 2025-12-09 17:24:41*

## Summary
- **Total Screen Files Analyzed**: 12
- **Files with English Text**: 10
- **Total English Text Strings Found**: 377

## By Package

### main_app (10 files, 377 texts)

#### lib/src/screens/admin_artwork_management_screen.dart (19 texts)
1. **Line 333**: "Created: ${artwork.createdAt.toString().split("
   *Context*: `const SizedBox(height: 8),                 Text(                   'Created: ${artwork.createdAt.toS...`
2. **Line 370**: "Analytics"
   *Context*: `lignment.start,           children: [             Text(               'Analytics',               sty...`
3. **Line 431**: "No reports"
   *Context*: `padding: EdgeInsets.all(16),           child: Text(             'No reports',             style: Tex...`
4. **Line 448**: "Reports"
   *Context*: `etween,               children: [                 Text(                   'Reports',                ...`
5. **Line 455**: "${reports.length} total"
   *Context*: `),                 ),                 Text(                   '${reports.length} total',            ...`
6. **Line 480**: "Reported by: ${(report["
   *Context*: `const SizedBox(height: 4),                       Text(                         'Reported by: ${(repo...`
7. **Line 502**: "Edit Content"
   *Context*: `lignment.start,           children: [             Text(               'Edit Content',               ...`
8. **Line 529**: "Tags: ${artwork.tags?.join("
   *Context*: `const SizedBox(height: 12),             Text(               'Tags: ${artwork.tags?.join(", ") ?? "No...`
9. **Line 544**: "No comments"
   *Context*: `padding: EdgeInsets.all(16),           child: Text(             'No comments',             style: Te...`
10. **Line 561**: "Comments"
   *Context*: `etween,               children: [                 Text(                   'Comments',               ...`
11. **Line 568**: "${comments.length} total"
   *Context*: `),                 ),                 Text(                   '${comments.length} total',           ...`
12. **Line 631**: "Actions"
   *Context*: `lignment.start,           children: [             Text(               'Actions',               style...`
13. **Line 179**: "Search artwork..."
   *Context*: `decoration: InputDecoration(                   hintText: 'Search artwork...',                   pref...`
14. **Line 706**: "Reason for rejection"
   *Context*: `ller,           decoration: const InputDecoration(hintText: 'Reason for rejection'),           maxLi...`
15. **Line 734**: "Reason for deletion"
   *Context*: `ller,           decoration: const InputDecoration(hintText: 'Reason for deletion'),           maxLin...`
16. **Line 476**: "No reason provided"
   *Context*: `(report['reason'] as String?) ?? 'No reason provided',                         style: const TextStyl...`
17. **Line 649**: "Approved by admin"
   *Context*: `_updateArtworkStatus('approved', reason: 'Approved by admin'),                   ),                 ...`
18. **Line 676**: "Flagged by admin"
   *Context*: `_updateArtworkStatus('flagged', reason: 'Flagged by admin'),                   ),                 ),...`
19. **Line 225**: "${artwork.description.substring(0, 50)}..."
   *Context*: `withValues(alpha: 0.1),                           title: Text(artwork.title),                       ...`

#### lib/src/screens/admin_login_screen.dart (8 texts)
1. **Line 97**: "Email"
   *Context*: `decoration: InputDecoration(                     labelText: 'Email',                     prefixIcon:...`
2. **Line 116**: "Password"
   *Context*: `decoration: InputDecoration(                     labelText: 'Password',                     prefixIc...`
3. **Line 63**: "Unknown error"
   *Context*: `th_failed'.tr(namedArgs: {'message': e.message ?? 'Unknown error'}),         };         _isLoading =...`
4. **Line 20**: "/admin/dashboard"
   *Context*: `ntroller();   bool _isLoading = false;   String? _error;    Future<void> _handleLogin() async {     ...`
5. **Line 58**: "user-not-found"
   *Context*: `xception catch (e) {       setState(() {         _error = switch (e.code) {           'user-not-foun...`
6. **Line 63**: ".tr(namedArgs: {"
   *Context*: `_invalid_email'.tr(),           _ => 'admin_login_error_auth_failed'.tr(namedArgs: {'message': e.mes...`
7. **Line 63**: "}),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error ="
   *Context*: `'.tr(namedArgs: {'message': e.message ?? 'Unknown error'}),         };         _isLoading = false;  ...`
8. **Line 69**: ": e.toString()});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText:"
   *Context*: `= 'admin_login_error_unexpected'.tr(namedArgs: {'error': e.toString()});         _isLoading = false;...`

#### lib/src/screens/admin_payment_screen.dart (73 texts)
1. **Line 286**: "${selectedTransactions.length} transactions selected"
   *Context*: `lignment.start,           children: [             Text('${selectedTransactions.length} transactions ...`
2. **Line 287**: "Total amount: \$${selectedTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}"
   *Context*: `ions.length} transactions selected'),             Text(                 'Total amount: \$${selectedT...`
3. **Line 290**: "Are you sure you want to process refunds for all selected transactions?"
   *Context*: `const SizedBox(height: 16),             Text(                 'Are you sure you want to process refu...`
4. **Line 757**: "${_selectedTransactionIds.length} selected"
   *Context*: `SizedBox(width: 16),                 Text('${_selectedTransactionIds.length} selected'),            ...`
5. **Line 838**: "${transaction.userName} • ${transaction.displayType}"
   *Context*: `t: FontWeight.bold),         ),         subtitle: Text('${transaction.userName} • ${transaction.disp...`
6. **Line 851**: "Date: ${intl.DateFormat("
   *Context*: `nsaction_id_transactionid'.tr()),                 Text(                     'Date: ${intl.DateFormat...`
7. **Line 868**: "Process Refund"
   *Context*: `olor: Colors.red),                         label: Text('Process Refund',                            ...`
8. **Line 893**: "Revenue Breakdown"
   *Context*: `xisAlignment.start,         children: [           Text(             'Revenue Breakdown',            ...`
9. **Line 904**: "Payment Methods"
   *Context*: `)),           SizedBox(height: 32),           Text(             'Payment Methods',             style...`
10. **Line 977**: "\$${totalAmount.toStringAsFixed(2)}"
   *Context*: `const Spacer(),                   Text(                     '\$${totalAmount.toStringAsFixed(2)}',  ...`
11. **Line 1091**: "${refundTransactions.length} Refunds"
   *Context*: `,               SizedBox(width: 8),               Text(                 '${refundTransactions.length...`
12. **Line 1097**: "Total: \$${refundTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}"
   *Context*: `),               Spacer(),               Text(                 'Total: \$${refundTransactions.fold(0...`
13. **Line 1122**: "Advanced Search & Filters"
   *Context*: `xisAlignment.start,         children: [           Text(             'Advanced Search & Filters',    ...`
14. **Line 1151**: "Amount Range"
   *Context*: `t Range           SizedBox(height: 16),           Text('Amount Range',               style: TextStyl...`
15. **Line 1262**: "$label:"
   *Context*: `edBox(             width: 120,             child: Text(               '$label:',               style...`
16. **Line 719**: "Search transactions..."
   *Context*: `decoration: InputDecoration(                     hintText: 'Search transactions...',                ...`
17. **Line 1173**: "Transaction Type"
   *Context*: `ctedType,             decoration: InputDecoration(labelText: 'Transaction Type'),             items:...`
18. **Line 603**: "Refresh Data"
   *Context*: `h),             onPressed: _loadData,             tooltip: 'Refresh Data',           ),           Ic...`
19. **Line 126**: "Error loading payment data: $e"
   *Context*: `lse;       });     } catch (e) {       debugPrint('Error loading payment data: $e');       setState(...`
20. **Line 128**: "Failed to load payment data"
   *Context*: `=> _isLoading = false);       _showErrorSnackBar('Failed to load payment data');     }   }    void _...`
21. **Line 218**: "Admin processed refund"
   *Context*: `amount: transaction.amount,             reason: 'Admin processed refund',           );         } els...`
22. **Line 223**: "No paymentIntentId found for transaction ${transaction.id}."
   *Context*: `ntent ID           AppLogger.warning(             'No paymentIntentId found for transaction ${transa...`
23. **Line 224**: "Recording refund in database only."
   *Context*: `for transaction ${transaction.id}. '             'Recording refund in database only.',           ); ...`
24. **Line 253**: "Refund processed successfully"
   *Context*: `UserId,         });          _showSuccessSnackBar('Refund processed successfully');         _loadDat...`
25. **Line 256**: "Error processing refund: $e"
   *Context*: `data       } catch (e) {         AppLogger.error('Error processing refund: $e');         _showErrorS...`
26. **Line 257**: "Failed to process refund: ${e.toString()}"
   *Context*: `ocessing refund: $e');         _showErrorSnackBar('Failed to process refund: ${e.toString()}');     ...`
27. **Line 264**: "No transactions selected"
   *Context*: `ransactionIds.isEmpty) {       _showErrorSnackBar('No transactions selected');       return;     }  ...`
28. **Line 274**: "No eligible transactions for refund"
   *Context*: `dTransactions.isEmpty) {       _showErrorSnackBar('No eligible transactions for refund');       retu...`
29. **Line 315**: "Admin authentication required"
   *Context*: `rentAdmin == null) {           _showErrorSnackBar('Admin authentication required');           return...`
30. **Line 329**: "Bulk admin refund"
   *Context*: `e': transaction.userName,               'reason': 'Bulk admin refund',               'processedBy': ...`
31. **Line 352**: "Part of bulk refund operation"
   *Context*: `userId: transaction.userId,               notes: 'Part of bulk refund operation',             );    ...`
32. **Line 357**: "Failed to refund transaction ${transaction.id}: $e"
   *Context*: `+;           } catch (e) {             debugPrint('Failed to refund transaction ${transaction.id}: $...`
33. **Line 361**: "Successfully processed $successCount refunds"
   *Context*: `}         }          _showSuccessSnackBar('Successfully processed $successCount refunds');         _...`
34. **Line 365**: "Error processing bulk refund: $e"
   *Context*: `fresh data       } catch (e) {         debugPrint('Error processing bulk refund: $e');         _show...`
35. **Line 366**: "Failed to process bulk refunds"
   *Context*: `ing bulk refund: $e');         _showErrorSnackBar('Failed to process bulk refunds');       }     }  ...`
36. **Line 412**: "Export completed successfully (${selectedTransactions.length} records)"
   *Context*: `,       );        _showSuccessSnackBar(           'Export completed successfully (${selectedTransact...`
37. **Line 415**: "Error exporting transactions: $e"
   *Context*: `arSelection();     } catch (e) {       debugPrint('Error exporting transactions: $e');       _showEr...`
38. **Line 416**: "Failed to export transactions"
   *Context*: `ting transactions: $e');       _showErrorSnackBar('Failed to export transactions');     }   }    Fut...`
39. **Line 464**: "Export completed successfully (${_filteredTransactions.length} records)"
   *Context*: `,       );        _showSuccessSnackBar(           'Export completed successfully (${_filteredTransac...`
40. **Line 500**: "STATUS_UPDATE"
   *Context*: `adminEmail: currentAdmin.email,           action: 'STATUS_UPDATE',           transactionId: transact...`
41. **Line 513**: "Successfully updated ${_selectedTransactionIds.length} transactions"
   *Context*: `h.commit();       _showSuccessSnackBar(           'Successfully updated ${_selectedTransactionIds.le...`
42. **Line 517**: "Error updating transaction statuses: $e"
   *Context*: `/ Refresh data     } catch (e) {       debugPrint('Error updating transaction statuses: $e');       ...`
43. **Line 518**: "Failed to update transaction statuses"
   *Context*: `nsaction statuses: $e');       _showErrorSnackBar('Failed to update transaction statuses');     }   ...`
44. **Line 589**: "Payment Management"
   *Context*: `oldKey,       appBar: AdminHeader(         title: 'Payment Management',         actions: [          ...`
45. **Line 597**: "Exit Selection Mode"
   *Context*: `tooltip: _isSelectionMode                 ? 'Exit Selection Mode'                 : 'Enter Selection...`
46. **Line 598**: "Enter Selection Mode"
   *Context*: `? 'Exit Selection Mode'                 : 'Enter Selection Mode',           ),           IconButton(...`
47. **Line 611**: "Export Selected"
   *Context*: `lectedTransactionIds.isNotEmpty                 ? 'Export Selected'                 : 'Export All', ...`
48. **Line 630**: "Transactions"
   *Context*: `tabs: const [                       Tab(text: 'Transactions', icon: Icon(Icons.receipt)),...`
49. **Line 665**: "Total Revenue"
   *Context*: `child: AdminMetricsCard(               title: 'Total Revenue',               value: '\$${_totalReven...`
50. **Line 675**: "Total Transactions"
   *Context*: `child: AdminMetricsCard(               title: 'Total Transactions',               value: _totalTrans...`
51. **Line 685**: "Avg Transaction"
   *Context*: `child: AdminMetricsCard(               title: 'Avg Transaction',               value: '\$${_averageT...`
52. **Line 695**: "Total Refunds"
   *Context*: `child: AdminMetricsCard(               title: 'Total Refunds',               value: '\$${_totalRefun...`
53. **Line 995**: "Success Rate"
   *Context*: `child: _buildStatItem(                         'Success Rate', '${successRate.toStringAsFixed(1)}%')...`
54. **Line 1232**: "Payment Method"
   *Context*: `tus.toUpperCase()),               _buildDetailRow('Payment Method', transaction.paymentMethod),     ...`
55. **Line 1235**: "MMM dd, yyyy HH:mm"
   *Context*: `'Date',                   intl.DateFormat('MMM dd, yyyy HH:mm')                       .format(transa...`
56. **Line 1240**: "Description"
   *Context*: `cription != null)                 _buildDetailRow('Description', transaction.description!),         ...`
57. **Line 1309**: "Transaction ID,User ID,User Name,Type,Amount,Currency,Status,Payment Method,Transaction Date,Description,Item Title"
   *Context*: `);      // CSV Header     buffer.writeln(         'Transaction ID,User ID,User Name,Type,Amount,Curr...`
58. **Line 1388**: "Exported transaction data"
   *Context*: `e.share(           ShareParams(             text: 'Exported transaction data',             subject: ...`
59. **Line 1389**: "Transaction Export"
   *Context*: `'Exported transaction data',             subject: 'Transaction Export',           ),         );     ...`
60. **Line 1394**: "Error downloading CSV file: $e"
   *Context*: `);       }     } catch (e) {       debugPrint('Error downloading CSV file: $e');       throw Excepti...`
61. **Line 1395**: "Failed to download CSV file"
   *Context*: `downloading CSV file: $e');       throw Exception('Failed to download CSV file');     }   } }...`
62. **Line 126**: ");
      setState(() => _isLoading = false);
      _showErrorSnackBar("
   *Context*: `se;       });     } catch (e) {       debugPrint('Error loading payment data: $e');       setState((...`
63. **Line 365**: ");
        _showErrorSnackBar("
   *Context*: `resh data       } catch (e) {         debugPrint('Error processing bulk refund: $e');         _showE...`
64. **Line 415**: ");
      _showErrorSnackBar("
   *Context*: `rSelection();     } catch (e) {       debugPrint('Error exporting transactions: $e');       _showErr...`
65. **Line 1394**: ");
      throw Exception("
   *Context*: `);       }     } catch (e) {       debugPrint('Error downloading CSV file: $e');       throw Excepti...`
66. **Line 140**: "All"
   *Context*: `tains(searchTerm) ||             (transaction.itemTitle?.toLowerCase().contains(searchTerm) ??      ...`
67. **Line 1131**: "All dates"
   *Context*: `in_payment_text_date_range'.tr()),             subtitle: Text(_dateRange == null                 ? '...`
68. **Line 1237**: "Item"
   *Context*: `nsactionDate)),               if (transaction.itemTitle != null)                 _buildDetailRow('It...`
69. **Line 1309**: ");

    // CSV Data rows
    for (final transaction in transactions) {
      final description =
          transaction.description?.replaceAll("
   *Context*: `,Payment Method,Transaction Date,Description,Item Title');      // CSV Data rows     for (final tran...`
70. **Line 1320**: ",
      );
    }

    return buffer.toString();
  }

  /// Download CSV file (web) or save to device
  Future<void> _downloadCsvFile(String csvContent, String fileName) async {
    try {
      if (kIsWeb) {
        // Web implementation using data URL for download
        final bytes = utf8.encode(csvContent);
        final base64Data = base64Encode(bytes);
        final dataUrl ="
   *Context*: `ntMethod},"$transactionDate","$description","$itemTitle"',       );     }      return buffer.toStrin...`
71. **Line 631**: "Analytics"
   *Context*: `icon: Icon(Icons.receipt)),                       Tab(text: 'Analytics', icon: Icon(Icons.analytics)...`
72. **Line 632**: "Refunds"
   *Context*: `on: Icon(Icons.analytics)),                       Tab(text: 'Refunds', icon: Icon(Icons.undo)),     ...`
73. **Line 633**: "Search"
   *Context*: `', icon: Icon(Icons.undo)),                       Tab(text: 'Search', icon: Icon(Icons.search)),    ...`

#### lib/src/screens/admin_security_center_screen.dart (22 texts)
1. **Line 212**: "Admin Access Control"
   *Context*: `children: [         // Admin Permissions         Text(           'Admin Access Control',           s...`
2. **Line 226**: "IP Whitelist"
   *Context*: `Box(height: 24),          // IP Whitelist         Text(           'IP Whitelist',           style: T...`
3. **Line 354**: "2024-12-${(index + 1).toString().padLeft(2,"
   *Context*: `events[index % events.length]),         subtitle: Text(             '2024-12-${(index + 1).toString(...`
4. **Line 434**: "User: ${users[index % users.length]} | IP: 192.168.1.${100 + index}"
   *Context*: `tions[index % actions.length]),         subtitle: Text(             'User: ${users[index % users.len...`
5. **Line 437**: "${10 + index}:${(index * 3).toString().padLeft(2,"
   *Context*: `1.${100 + index}'),         trailing:             Text('${10 + index}:${(index * 3).toString().padLe...`
6. **Line 559**: "Timestamp: 2024-12-24 ${10 + index}:${(index * 3).toString().padLeft(2,"
   *Context*: `ty_center_text_log_id_log1000'.tr()),             Text(                 'Timestamp: 2024-12-24 ${10 ...`
7. **Line 280**: "Search logs..."
   *Context*: `decoration: InputDecoration(                     hintText: 'Search logs...',                     pre...`
8. **Line 501**: "Office Network"
   *Context*: `labelText: 'Description',                 hintText: 'Office Network',               ),             )...`
9. **Line 494**: "IP Address/Range"
   *Context*: `decoration: InputDecoration(                 labelText: 'IP Address/Range',                 hintText...`
10. **Line 500**: "Description"
   *Context*: `decoration: InputDecoration(                 labelText: 'Description',                 hintText: 'Of...`
11. **Line 290**: "Data Access"
   *Context*: `e: 'All',                 items: ['All', 'Login', 'Data Access', 'Settings Change']                 ...`
12. **Line 290**: "Settings Change"
   *Context*: `items: ['All', 'Login', 'Data Access', 'Settings Change']                     .map((e) => DropdownMe...`
13. **Line 381**: "Sarah Security"
   *Context*: `ard(int index) {     final users = ['John Admin', 'Sarah Security', 'Mike Manager'];      return Car...`
14. **Line 381**: "Mike Manager"
   *Context*: `final users = ['John Admin', 'Sarah Security', 'Mike Manager'];      return Card(       margin: Edge...`
15. **Line 416**: "Data Export"
   *Context*: `{     final actions = [       'User Login',       'Data Export',       'Settings Change',       'Use...`
16. **Line 418**: "User Created"
   *Context*: `'Data Export',       'Settings Change',       'User Created',       'Content Deleted'     ];     fin...`
17. **Line 419**: "Content Deleted"
   *Context*: `'Settings Change',       'User Created',       'Content Deleted'     ];     final users = [       'j...`
18. **Line 532**: "Edit permissions for $user"
   *Context*: `ch (value) {       case 'edit':         message = 'Edit permissions for $user';         break;      ...`
19. **Line 535**: "Disabled account for $user"
   *Context*: `break;       case 'disable':         message = 'Disabled account for $user';         break;       ca...`
20. **Line 538**: "Removed admin privileges for $user"
   *Context*: `break;       case 'remove':         message = 'Removed admin privileges for $user';         break;  ...`
21. **Line 541**: "Unknown action"
   *Context*: `;         break;       default:         message = 'Unknown action';     }      ScaffoldMessenger.of(...`
22. **Line 363**: "John Admin"
   *Context*: `);   }    Widget _buildThreatCard(       String title, String description, String severity, Color co...`

#### lib/src/screens/admin_settings_screen.dart (37 texts)
1. **Line 119**: "Save"
   *Context*: `onPressed: _saveSettings,               child: Text(                 'Save',                 style: ...`
2. **Line 160**: "Error loading settings"
   *Context*: `),           SizedBox(height: 16),           Text(             'Error loading settings',            ...`
3. **Line 554**: "Are you sure you want to create a backup of the database?"
   *Context*: `ngs_text_backup_database'.tr()),         content: Text(             'Are you sure you want to create...`
4. **Line 607**: "Are you sure you want to reset all settings to default values?"
   *Context*: `ings_text_reset_settings'.tr()),         content: Text(             'Are you sure you want to reset ...`
5. **Line 110**: "Admin Settings"
   *Context*: `appBar: EnhancedUniversalHeader(         title: 'Admin Settings',         showBackButton: true,     ...`
6. **Line 213**: "General Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'General Settings',       children: [         _buil...`
7. **Line 222**: "App Description"
   *Context*: `,         ),         _buildTextSetting(           'App Description',           _settings!.appDescrip...`
8. **Line 228**: "Maintenance Mode"
   *Context*: `),         _buildSwitchSetting(           'Maintenance Mode',           _settings!.maintenanceMode,...`
9. **Line 234**: "Enable Registration"
   *Context*: `),         _buildSwitchSetting(           'Enable Registration',           _settings!.registrationEn...`
10. **Line 245**: "User Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'User Settings',       children: [         _buildNu...`
11. **Line 248**: "Max Upload Size (MB)"
   *Context*: `hildren: [         _buildNumberSetting(           'Max Upload Size (MB)',           _settings!.maxUp...`
12. **Line 254**: "Max Artworks per User"
   *Context*: `),         _buildNumberSetting(           'Max Artworks per User',           _settings!.maxArtworksP...`
13. **Line 260**: "Require Email Verification"
   *Context*: `),         _buildSwitchSetting(           'Require Email Verification',           _settings!.require...`
14. **Line 266**: "Auto-approve Content"
   *Context*: `),         _buildSwitchSetting(           'Auto-approve Content',           _settings!.autoApproveCo...`
15. **Line 277**: "Content Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'Content Settings',       children: [         _buil...`
16. **Line 280**: "Enable Comments"
   *Context*: `hildren: [         _buildSwitchSetting(           'Enable Comments',           _settings!.commentsEn...`
17. **Line 286**: "Enable Artwork Ratings"
   *Context*: `),         _buildSwitchSetting(           'Enable Artwork Ratings',           _settings!.ratingsEnab...`
18. **Line 292**: "Enable Content Reporting"
   *Context*: `),         _buildSwitchSetting(           'Enable Content Reporting',           _settings!.reporting...`
19. **Line 298**: "Banned Words (comma-separated)"
   *Context*: `,         ),         _buildTextSetting(           'Banned Words (comma-separated)',           _setti...`
20. **Line 316**: "Security Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'Security Settings',       children: [         _bui...`
21. **Line 319**: "Max Login Attempts"
   *Context*: `hildren: [         _buildNumberSetting(           'Max Login Attempts',           _settings!.maxLogi...`
22. **Line 325**: "Login Attempt Window (minutes)"
   *Context*: `),         _buildNumberSetting(           'Login Attempt Window (minutes)',           _settings!.log...`
23. **Line 331**: "Enable Two-Factor Authentication"
   *Context*: `),         _buildSwitchSetting(           'Enable Two-Factor Authentication',           _settings!.t...`
24. **Line 337**: "Enable IP Blocking"
   *Context*: `),         _buildSwitchSetting(           'Enable IP Blocking',           _settings!.ipBlockingEnabl...`
25. **Line 348**: "System Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'System Settings',       children: [         _build...`
26. **Line 351**: "Enable Analytics"
   *Context*: `hildren: [         _buildSwitchSetting(           'Enable Analytics',           _settings!.analytics...`
27. **Line 357**: "Enable Error Logging"
   *Context*: `),         _buildSwitchSetting(           'Enable Error Logging',           _settings!.errorLoggingE...`
28. **Line 363**: "Enable Performance Monitoring"
   *Context*: `),         _buildSwitchSetting(           'Enable Performance Monitoring',           _settings!.perf...`
29. **Line 371**: "Cache Duration (hours)"
   *Context*: `),         _buildNumberSetting(           'Cache Duration (hours)',           _settings!.cacheDurati...`
30. **Line 382**: "Notification Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'Notification Settings',       children: [         ...`
31. **Line 385**: "Enable Push Notifications"
   *Context*: `hildren: [         _buildSwitchSetting(           'Enable Push Notifications',           _settings!....`
32. **Line 391**: "Enable Email Notifications"
   *Context*: `),         _buildSwitchSetting(           'Enable Email Notifications',           _settings!.emailNo...`
33. **Line 397**: "Enable Admin Alerts"
   *Context*: `),         _buildSwitchSetting(           'Enable Admin Alerts',           _settings!.adminAlertsEna...`
34. **Line 408**: "Maintenance Settings"
   *Context*: `{     return _buildSettingsSection(       title: 'Maintenance Settings',       children: [         _...`
35. **Line 411**: "Maintenance Message"
   *Context*: `children: [         _buildTextSetting(           'Maintenance Message',           _settings!.mainten...`
36. **Line 438**: "Danger Zone"
   *Context*: `{     return _buildSettingsSection(       title: 'Danger Zone',       color: Colors.red.shade50,    ...`
37. **Line 357**: ",
          _settings!.errorLoggingEnabled,
          (value) => _updateSetting(value, (s) => s.errorLoggingEnabled,
              (s, v) => s.copyWith(errorLoggingEnabled: v)),
        ),
        _buildSwitchSetting("
   *Context*: `),         _buildSwitchSetting(           'Enable Error Logging',           _settings!.errorLoggingE...`

#### lib/src/screens/admin_system_monitoring_screen.dart (33 texts)
1. **Line 211**: "System Status: ${_systemMetrics["
   *Context*: `rt,                 children: [                   Text(                     'System Status: ${_syste...`
2. **Line 217**: "Last updated: ${DateTime.now().toString().substring(0, 19)}"
   *Context*: `),                   ),                   Text(                     'Last updated: ${DateTime.now()....`
3. **Line 310**: "Server Status"
   *Context*: `rt,                 children: [                   Text(                     'Server Status',        ...`
4. **Line 335**: "Recent Alerts"
   *Context*: `children: [                       Text(                         'Recent Alerts',                    ...`
5. **Line 381**: "Real-time Performance"
   *Context*: `rt,                 children: [                   Text(                     'Real-time Performance',...`
6. **Line 405**: "Performance Metrics"
   *Context*: `rt,                 children: [                   Text(                     'Performance Metrics',  ...`
7. **Line 479**: "System Alerts"
   *Context*: `rt,                 children: [                   Text(                     'System Alerts',        ...`
8. **Line 550**: "Active Users"
   *Context*: `rt,                 children: [                   Text(                     'Active Users',         ...`
9. **Line 605**: "${server["
   *Context*: `tWeight.bold),                 ),                 Text(                   '${server['location'] ?? '...`
10. **Line 750**: "Performance Chart\n(Real-time data visualization)"
   *Context*: `),       child: const Center(         child: Text(           'Performance Chart\n(Real-time data vis...`
11. **Line 159**: "Refresh Data"
   *Context*: `onPressed: _loadSystemData,             tooltip: 'Refresh Data',           ),         ],         bot...`
12. **Line 154**: "Pause Real-time"
   *Context*: `},             tooltip: _isRealTimeEnabled ? 'Pause Real-time' : 'Start Real-time',           ),    ...`
13. **Line 154**: "Start Real-time"
   *Context*: `tooltip: _isRealTimeEnabled ? 'Pause Real-time' : 'Start Real-time',           ),           IconButt...`
14. **Line 169**: "Performance"
   *Context*: `on: Icon(Icons.dashboard)),             Tab(text: 'Performance', icon: Icon(Icons.speed)),          ...`
15. **Line 275**: "Memory Usage"
   *Context*: `AdminMetricsCard(                 title: 'Memory Usage',                 value:                     ...`
16. **Line 291**: "Response Time"
   *Context*: `AdminMetricsCard(                 title: 'Response Time',                 value:                    ...`
17. **Line 451**: "Critical Alerts"
   *Context*: `child: AdminMetricsCard(                   title: 'Critical Alerts',                   value:       ...`
18. **Line 461**: "Warning Alerts"
   *Context*: `child: AdminMetricsCard(                   title: 'Warning Alerts',                   value:        ...`
19. **Line 521**: "Online Users"
   *Context*: `AdminMetricsCard(                 title: 'Online Users',                 value: '${_systemMetrics['o...`
20. **Line 533**: "Avg Session"
   *Context*: `AdminMetricsCard(                 title: 'Avg Session',                 value:                     '...`
21. **Line 562**: "Session Time"
   *Context*: `'Location',                       'Session Time',                       'Actions',...`
22. **Line 602**: "Unknown Server"
   *Context*: `t(                   server['name'] as String? ?? 'Unknown Server',                   style: const T...`
23. **Line 657**: "Unknown alert"
   *Context*: `alert['message'] as String? ?? 'Unknown alert',                   style: const TextStyle(fontWei...`
24. **Line 661**: "Unknown time"
   *Context*: `alert['timestamp'] as String? ?? 'Unknown time',                   style: TextStyle(...`
25. **Line 684**: "No details available"
   *Context*: `subtitle: Text(alert['details'] as String? ?? 'No details available'),         trailing: Column(    ...`
26. **Line 717**: ":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Simplified chart representation
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text("
   *Context*: `ase 'critical':       case 'offline':       case 'error':         color = Colors.red;         break;...`
27. **Line 267**: "CPU Usage"
   *Context*: `[               AdminMetricsCard(                 title: 'CPU Usage',                 value:        ...`
28. **Line 407**: "Metric"
   *Context*: `style: Theme.of(context).textTheme.titleLarge?.copyWith(                           fontWeight: FontW...`
29. **Line 527**: "Peak Today"
   *Context*: `,               AdminMetricsCard(                 title: 'Peak Today',                 value: '${_sy...`
30. **Line 552**: "User"
   *Context*: `style: Theme.of(context).textTheme.titleLarge?.copyWith(                           fontWeight: FontW...`
31. **Line 168**: "Overview"
   *Context*: `Colors.white,           tabs: const [             Tab(text: 'Overview', icon: Icon(Icons.dashboard))...`
32. **Line 170**: "Alerts"
   *Context*: `rformance', icon: Icon(Icons.speed)),             Tab(text: 'Alerts', icon: Icon(Icons.warning)),   ...`
33. **Line 171**: "Users"
   *Context*: `'Alerts', icon: Icon(Icons.warning)),             Tab(text: 'Users', icon: Icon(Icons.people)),     ...`

#### lib/src/screens/admin_user_detail_screen.dart (38 texts)
1. **Line 319**: "Recent Activity"
   *Context*: `xisAlignment.start,         children: [           Text(             'Recent Activity',             s...`
2. **Line 335**: "Activity Summary"
   *Context*: `rt,                 children: [                   Text(                     'Activity Summary',     ...`
3. **Line 388**: "Admin Information"
   *Context*: `xisAlignment.start,         children: [           Text(             'Admin Information',            ...`
4. **Line 405**: "User Suspended"
   *Context*: `SizedBox(width: 8),                         Text(                           'User Suspended',       ...`
5. **Line 421**: "Suspended: ${_formatDateTime(_currentUser.suspendedAt!)}"
   *Context*: `const SizedBox(height: 4),                       Text(                           'Suspended: ${_form...`
6. **Line 440**: "Admin Actions"
   *Context*: `rt,                 children: [                   Text(                     'Admin Actions',        ...`
7. **Line 485**: "Admin Notes"
   *Context*: `children: [                     Text(                       'Admin Notes',                       sty...`
8. **Line 508**: "By: ${noteData["
   *Context*: `SizedBox(height: 4),                             Text(                               'By: ${noteData...`
9. **Line 528**: "Admin Flags"
   *Context*: `children: [                     Text(                       'Admin Flags',                       sty...`
10. **Line 559**: "User Management"
   *Context*: `rt,                 children: [                   Text(                     'User Management',      ...`
11. **Line 632**: "Image Management"
   *Context*: `// Image Management                   Text('Image Management',                       style: TextStyl...`
12. **Line 649**: "User Type"
   *Context*: `SizedBox(height: 16),                   Text('User Type',                       style: TextStyle(fon...`
13. **Line 679**: "Status Management"
   *Context*: `erification and Featured Status                   Text('Status Management',                       st...`
14. **Line 965**: "Are you sure you want to remove this user\"
   *Context*: `ext_remove_profile_image'.tr()),         content: Text(             'Are you sure you want to remove...`
15. **Line 1024**: "User ${newFeaturedStatus ?"
   *Context*: `ckBar(           SnackBar(               content: Text(                   'User ${newFeaturedStatus ...`
16. **Line 1085**: "User ${!_currentUser.isVerified ?"
   *Context*: `ckBar(           SnackBar(               content: Text(                   'User ${!_currentUser.isVe...`
17. **Line 571**: "Full Name"
   *Context*: `decoration: const InputDecoration(labelText: 'Full Name'),                     ),                   ...`
18. **Line 576**: "Username"
   *Context*: `decoration: const InputDecoration(labelText: 'Username'),                     ),                    ...`
19. **Line 581**: "Email"
   *Context*: `decoration: InputDecoration(labelText: 'Email'),                     ),                     Size...`
20. **Line 586**: "Bio"
   *Context*: `decoration: InputDecoration(labelText: 'Bio'),                       maxLines: 3,...`
21. **Line 592**: "Location"
   *Context*: `decoration: InputDecoration(labelText: 'Location'),                     ),                     Size...`
22. **Line 597**: "Zip Code"
   *Context*: `decoration: InputDecoration(labelText: 'Zip Code'),                     ),                     Size...`
23. **Line 73**: "User Details"
   *Context*: `appBar: EnhancedUniversalHeader(         title: 'User Details',         showBackButton: true,       ...`
24. **Line 251**: "Personal Information"
   *Context*: `children: [           _buildDetailSection('Personal Information', [             _buildDetailRow('Ful...`
25. **Line 267**: "Account Information"
   *Context*: `zedBox(height: 24),           _buildDetailSection('Account Information', [             _buildDetailR...`
26. **Line 282**: "Last Active"
   *Context*: `_buildDetailRow(                   'Last Active', _formatDateTime(_currentUser.lastActiveAt!)),...`
27. **Line 295**: "Achievements"
   *Context*: `dBox(height: 24),             _buildDetailSection('Achievements', [               Wrap(             ...`
28. **Line 355**: "Account Created"
   *Context*: `_buildActivityItem(                     'Account Created',                     _formatDateTime(_curr...`
29. **Line 362**: "Profile Updated"
   *Context*: `_buildActivityItem(                       'Profile Updated',                       _formatDateTime(_...`
30. **Line 368**: "Active User"
   *Context*: `_buildActivityItem(                     'Active User',                     _currentUser.isActiveUser...`
31. **Line 446**: "Report Count"
   *Context*: `_buildAdminActionTile(                     'Report Count',                     '${_currentUser.repor...`
32. **Line 458**: "Email Verified"
   *Context*: `_buildAdminActionTile(                     'Email Verified',                     _currentUser.emailV...`
33. **Line 466**: "Password Reset Required"
   *Context*: `_buildAdminActionTile(                     'Password Reset Required',                     _currentUs...`
34. **Line 509**: "Unknown time"
   *Context*: `me((noteData['addedAt'] as Timestamp).toDate()) : 'Unknown time'}',                             ),...`
35. **Line 90**: "Overview"
   *Context*: `F63),               tabs: const [                 Tab(text: 'Overview', icon: Icon(Icons.person)),  ...`
36. **Line 91**: "Details"
   *Context*: `view', icon: Icon(Icons.person)),                 Tab(text: 'Details', icon: Icon(Icons.info)),     ...`
37. **Line 92**: "Activity"
   *Context*: `etails', icon: Icon(Icons.info)),                 Tab(text: 'Activity', icon: Icon(Icons.history)), ...`
38. **Line 93**: "Admin"
   *Context*: `ity', icon: Icon(Icons.history)),                 Tab(text: 'Admin', icon: Icon(Icons.admin_panel_se...`

#### lib/src/screens/migration_screen.dart (10 texts)
1. **Line 196**: "This migration adds standardized moderation status fields to all content collections (posts, comments, artwork, captures, ads)."
   *Context*: `const SizedBox(height: 8),                     Text(                       'This migration adds stan...`
2. **Line 351**: "${status.migratedDocuments}/${status.totalDocuments} documents migrated"
   *Context*: `.start,               children: [                 Text(                   '${status.migratedDocument...`
3. **Line 364**: "${(status.migrationProgress * 100).toStringAsFixed(1)}%"
   *Context*: `],             ),             trailing: Text(               '${(status.migrationProgress * 100).toSt...`
4. **Line 198**: "Existing content will be marked as"
   *Context*: `artwork, captures, ads). '                       'Existing content will be marked as "approved" by d...`
5. **Line 276**: "Migrating..."
   *Context*: `abel:                         Text(_isMigrating ? 'Migrating...' : 'Run Migration'),                ...`
6. **Line 276**: "Run Migration"
   *Context*: `Text(_isMigrating ? 'Migrating...' : 'Run Migration'),                     style: ElevatedButton.sty...`
7. **Line 42**: ": e.toString()});
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    final confirmed = await _showConfirmationDialog("
   *Context*: `ration_error_check_status_failed'.tr(namedArgs: {'error': e.toString()});         _isLoading = false...`
8. **Line 73**: ": e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<void> _rollbackMigration() async {
    final confirmed = await _showConfirmationDialog("
   *Context*: `= 'admin_migration_error_failed'.tr(namedArgs: {'error': e.toString()});         _isMigrating = fals...`
9. **Line 104**: ": e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<void> _migrateGeoFields() async {
    final confirmed = await _showConfirmationDialog("
   *Context*: `_migration_error_rollback_failed'.tr(namedArgs: {'error': e.toString()});         _isMigrating = fal...`
10. **Line 132**: ": e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("
   *Context*: `admin_migration_error_geo_failed'.tr(namedArgs: {'error': e.toString()});         _isMigrating = fal...`

#### lib/src/screens/modern_unified_admin_dashboard.dart (83 texts)
1. **Line 352**: "Loading admin data..."
   *Context*: `,           const SizedBox(height: 20),           Text(             'Loading admin data...',        ...`
2. **Line 391**: "Oops! Something went wrong"
   *Context*: `const SizedBox(height: 16),             const Text(               'Oops! Something went wrong',     ...`
3. **Line 474**: "Performance Overview"
   *Context*: `const Expanded(                 child: Text(                   'Performance Overview',              ...`
4. **Line 647**: "Quick Actions"
   *Context*: `const Expanded(                 child: Text(                   'Quick Actions',                   st...`
5. **Line 823**: "Recent Activity"
   *Context*: `const Expanded(                 child: Text(                   'Recent Activity',                   ...`
6. **Line 846**: "No recent activity"
   *Context*: `const SizedBox(height: 8),                   Text(                     'No recent activity',        ...`
7. **Line 951**: "System Health"
   *Context*: `const Expanded(                 child: Text(                   'System Health',                   st...`
8. **Line 1074**: "User Management"
   *Context*: `SizedBox(width: 12),                       const Text(                         'User Management',   ...`
9. **Line 1270**: "$label ($count)"
   *Context*: `te.withValues(alpha: 0.2)),       ),       child: Text(         '$label ($count)',         style: co...`
10. **Line 1408**: "Joined ${_formatDate(user.createdAt)}"
   *Context*: `Expanded(                       child: Text(                         'Joined ${_formatDate(user.crea...`
11. **Line 1518**: "Content Moderation"
   *Context*: `SizedBox(width: 12),                       const Text(                         'Content Moderation',...`
12. **Line 1670**: "Pending Reviews"
   *Context*: `children: [                     const Text(                       'Pending Reviews',                ...`
13. **Line 1701**: "Recent Content"
   *Context*: `children: [                   const Text(                     'Recent Content',                     ...`
14. **Line 1893**: "By ${review.authorName}"
   *Context*: `),           const SizedBox(height: 8),           Text(             'By ${review.authorName}',      ...`
15. **Line 2009**: "By ${content.authorName}"
   *Context*: `Expanded(                       child: Text(                         'By ${content.authorName}',    ...`
16. **Line 2054**: "View Details"
   *Context*: `view',                 child:                     Text('View Details', style: TextStyle(color: Color...`
17. **Line 2059**: "Edit Content"
   *Context*: `edit',                 child:                     Text('Edit Content', style: TextStyle(color: Color...`
18. **Line 2063**: "Delete Content"
   *Context*: `value: 'delete',                 child: Text('Delete Content',                     style: TextStyle(...`
19. **Line 2332**: "Media"
   *Context*: `true)) ...[                         const Text(                           'Media',                  ...`
20. **Line 2403**: "Description"
   *Context*: `cription.isNotEmpty) ...[                         Text(                           'Description',    ...`
21. **Line 2447**: "Tags"
   *Context*: `nst SizedBox(height: 24),                         Text(                           'Tags',           ...`
22. **Line 2501**: "Review cleared successfully"
   *Context*: `content: Text(                                             'Review cleared successfully'),          ...`
23. **Line 2646**: "$label: $value"
   *Context*: `te.withValues(alpha: 0.2)),       ),       child: Text(         '$label: $value',         style: con...`
24. **Line 2709**: "Title"
   *Context*: `[                 // Title field                 Text(                   'Title',                   ...`
25. **Line 2786**: "Status"
   *Context*: `// Status dropdown                 Text(                   'Status',                   style: TextSt...`
26. **Line 2840**: "Cancel"
   *Context*: `) => Navigator.pop(context),               child: Text(                 'Cancel',                 st...`
27. **Line 2899**: "Are you sure you want to delete this ${content.type}?"
   *Context*: `lignment.start,           children: [             Text(               'Are you sure you want to dele...`
28. **Line 2924**: "by ${content.authorName}"
   *Context*: `const SizedBox(height: 4),                   Text(                     'by ${content.authorName}',  ...`
29. **Line 2935**: "This action cannot be undone."
   *Context*: `const SizedBox(height: 16),             Text(               'This action cannot be undone.',        ...`
30. **Line 3143**: "Financial Analytics"
   *Context*: `SizedBox(width: 12),                       const Text(                         'Financial Analytics'...`
31. **Line 3240**: "Revenue Breakdown"
   *Context*: `children: [                   const Text(                     'Revenue Breakdown',                  ...`
32. **Line 3290**: "Recent Transactions"
   *Context*: `children: [                   const Text(                     'Recent Transactions',                ...`
33. **Line 3312**: "Financial Insights"
   *Context*: `children: [                   const Text(                     'Financial Insights',                 ...`
34. **Line 3460**: "Revenue Chart"
   *Context*: `,           const SizedBox(height: 16),           Text(             'Revenue Chart',             sty...`
35. **Line 3469**: "Chart visualization will be implemented\nwith real Firebase data using fl_chart"
   *Context*: `),           const SizedBox(height: 8),           Text(             'Chart visualization will be imp...`
36. **Line 3492**: "$percentage%"
   *Context*: `child: Column(         children: [           Text(             '$percentage%',             style: Te...`
37. **Line 3527**: "No Recent Transactions"
   *Context*: `const SizedBox(height: 16),             Text(               'No Recent Transactions',               ...`
38. **Line 3536**: "Transaction data will appear here once payments are processed."
   *Context*: `const SizedBox(height: 8),             Text(               'Transaction data will appear here once p...`
39. **Line 1143**: "Search users by name, email, or username..."
   *Context*: `ecoration: InputDecoration(                       hintText: 'Search users by name, email, or usernam...`
40. **Line 1601**: "Search content by title, author, or description..."
   *Context*: `ecoration: InputDecoration(                       hintText:                           'Search conten...`
41. **Line 2721**: "Enter title"
   *Context*: `decoration: InputDecoration(                     hintText: 'Enter title',                     hintSt...`
42. **Line 2760**: "Enter description"
   *Context*: `decoration: InputDecoration(                     hintText: 'Enter description',                     ...`
43. **Line 252**: "Refresh Data"
   *Context*: `onPressed: _loadAllData,             tooltip: 'Refresh Data',           ),         ),       ],     )...`
44. **Line 114**: "Failed to load admin data: $e"
   *Context*: `catch (e) {       setState(() {         _error = 'Failed to load admin data: $e';       });     } fi...`
45. **Line 146**: "Failed to load dashboard data: $e"
   *Context*: `catch (e) {       setState(() {         _error = 'Failed to load dashboard data: $e';         _isLoa...`
46. **Line 234**: "Admin Command Center"
   *Context*: `return EnhancedUniversalHeader(       title: 'Admin Command Center',       showBackButton: false,   ...`
47. **Line 401**: "Unknown error occurred"
   *Context*: `ht: 8),             Text(               _error ?? 'Unknown error occurred',               style: Tex...`
48. **Line 499**: "Total Users"
   *Context*: `_buildModernKPICard(                     'Total Users',                     _users.length.toString()...`
49. **Line 515**: "Total Content"
   *Context*: `_buildModernKPICard(                     'Total Content',                     _allContent.length.toS...`
50. **Line 665**: "Review Content"
   *Context*: `_buildModernActionCard(                 'Review Content',                 'Moderate pending submissi...`
51. **Line 666**: "Moderate pending submissions"
   *Context*: `'Review Content',                 'Moderate pending submissions',                 Icons.rate_review_...`
52. **Line 675**: "Manage Users"
   *Context*: `_buildModernActionCard(                 'Manage Users',                 'User administration tools',...`
53. **Line 676**: "User administration tools"
   *Context*: `(                 'Manage Users',                 'User administration tools',                 Icons...`
54. **Line 682**: "Financial Reports"
   *Context*: `_buildModernActionCard(                 'Financial Reports',                 'Revenue and analytics'...`
55. **Line 683**: "Revenue and analytics"
   *Context*: `'Financial Reports',                 'Revenue and analytics',                 Icons.analytics_rounde...`
56. **Line 689**: "System Settings"
   *Context*: `_buildModernActionCard(                 'System Settings',                 'Configure platform setti...`
57. **Line 690**: "Configure platform settings"
   *Context*: `'System Settings',                 'Configure platform settings',                 Icons.settings_rou...`
58. **Line 970**: "API Services"
   *Context*: `_buildModernHealthIndicator(                   'API Services', true, Icons.api_rounded),            ...`
59. **Line 973**: "File Storage"
   *Context*: `_buildModernHealthIndicator(                   'File Storage', true, Icons.cloud_rounded),          ...`
60. **Line 1103**: "Verified Users"
   *Context*: `_buildUserStatCard(                             'Verified Users',                             _users...`
61. **Line 1109**: "Featured Users"
   *Context*: `_buildUserStatCard(                             'Featured Users',                             _users...`
62. **Line 1115**: "Suspended Users"
   *Context*: `_buildUserStatCard(                             'Suspended Users',                             _user...`
63. **Line 2162**: "Failed to trigger capture approval rewards: $e"
   *Context*: `}       }     } catch (e) {       AppLogger.error('Failed to trigger capture approval rewards: $e');...`
64. **Line 2179**: "Rejected by admin"
   *Context*: `rejectContent(review.contentId,           reason: 'Rejected by admin');        // Refresh the conten...`
65. **Line 3166**: "Total Revenue"
   *Context*: `uildFinancialKPICard(                             'Total Revenue',                             _anal...`
66. **Line 3182**: "Monthly Recurring"
   *Context*: `uildFinancialKPICard(                             'Monthly Recurring',                             _...`
67. **Line 3199**: "Total Transactions"
   *Context*: `uildFinancialKPICard(                             'Total Transactions',                             ...`
68. **Line 3212**: "Avg Transaction"
   *Context*: `uildFinancialKPICard(                             'Avg Transaction',                             _an...`
69. **Line 3220**: "Per transaction"
   *Context*: `Metrics != null                                 ? 'Per transaction'                                 ...`
70. **Line 3255**: "Advertisements"
   *Context*: `buildRevenueSourceCard(                           'Advertisements',                           _reven...`
71. **Line 3263**: "Subscriptions"
   *Context*: `buildRevenueSourceCard(                           'Subscriptions',                           _revenu...`
72. **Line 3271**: "Artwork Sales"
   *Context*: `buildRevenueSourceCard(                           'Artwork Sales',                           _revenu...`
73. **Line 3322**: "Revenue Growth"
   *Context*: `_buildFinancialInsightCard(                     'Revenue Growth',                     _analytics?.fi...`
74. **Line 3324**: "Revenue ${_analytics!.financialMetrics.revenueGrowth >= 0 ?"
   *Context*: `inancialMetrics != null                         ? 'Revenue ${_analytics!.financialMetrics.revenueGro...`
75. **Line 3325**: "Revenue growth data will appear here"
   *Context*: `ompared to last period'                         : 'Revenue growth data will appear here',           ...`
76. **Line 3334**: "Transaction Volume"
   *Context*: `_buildFinancialInsightCard(                     'Transaction Volume',                     _analytics...`
77. **Line 3337**: "Transaction data will appear here"
   *Context*: `transactions processed'                         : 'Transaction data will appear here',              ...`
78. **Line 3343**: "Average Revenue"
   *Context*: `_buildFinancialInsightCard(                     'Average Revenue',                     _analytics?.f...`
79. **Line 3345**: "Average revenue per transaction: ${_formatCurrency(_analytics!.financialMetrics.averageRevenuePerUser)}"
   *Context*: `inancialMetrics != null                         ? 'Average revenue per transaction: ${_formatCurrenc...`
80. **Line 3346**: "Average revenue data will appear here"
   *Context*: `verageRevenuePerUser)}'                         : 'Average revenue data will appear here',          ...`
81. **Line 66**: "All"
   *Context*: `// State   bool _isLoading = true;   String? _error;    // Search controllers for future use   final...`
82. **Line 1024**: ",
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PLACEHOLDER TABS ====================
  Widget _buildModernUserManagementTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8C52FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Statistics Overview
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text("
   *Context*: `d: Text(                 isHealthy ? 'Healthy' : 'Error',                 style: TextStyle(         ...`
83. **Line 1602**: ",
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildContentFilterChip("
   *Context*: `ext:                           'Search content by title, author, or description...',                ...`

#### lib/src/screens/unified_admin_dashboard.dart (54 texts)
1. **Line 278**: "Key Performance Indicators"
   *Context*: `nt.start,           children: [             const Text(               'Key Performance Indicators', ...`
2. **Line 367**: "Quick Actions"
   *Context*: `lignment.start,           children: [             Text(               'Quick Actions',              ...`
3. **Line 424**: "Recent Activity"
   *Context*: `lignment.start,           children: [             Text(               'Recent Activity',            ...`
4. **Line 463**: "System Health"
   *Context*: `lignment.start,           children: [             Text(               'System Health',              ...`
5. **Line 586**: "${_selectedUserIds.length} users selected"
   *Context*: `...[             SizedBox(height: 8),             Text(               '${_selectedUserIds.length} us...`
6. **Line 644**: "Role: ${user.userType ??"
   *Context*: `Text(user.email),                   Text(                     'Role: ${user.userType ?? 'User'} • St...`
7. **Line 866**: "REPORTED CONTENT"
   *Context*: `if (isReported)                         Text(                           'REPORTED CONTENT',         ...`
8. **Line 985**: "Ad Management"
   *Context*: `xisAlignment.start,         children: [           Text(             'Ad Management',             sty...`
9. **Line 1006**: "Payout Management"
   *Context*: `xisAlignment.start,         children: [           Text(             'Payout Management',            ...`
10. **Line 1042**: "Recent Ad Activity"
   *Context*: `lignment.start,           children: [             Text(               'Recent Ad Activity',         ...`
11. **Line 1082**: "Payout Summary"
   *Context*: `lignment.start,           children: [             Text(               'Payout Summary',             ...`
12. **Line 1120**: "Recent Payouts"
   *Context*: `lignment.start,           children: [             Text(               'Recent Payouts',             ...`
13. **Line 1132**: "Processed on ${DateTime.now().subtract(Duration(days: index)).toString().split("
   *Context*: `ayout_index_1'.tr()),                   subtitle: Text('Processed on ${DateTime.now().subtract(Durat...`
14. **Line 1133**: "\$${(100 + (index * 50)).toStringAsFixed(2)}"
   *Context*: `g().split(' ')[0]}'),                   trailing: Text(                     '\$${(100 + (index * 50)...`
15. **Line 1193**: "Financial Overview"
   *Context*: `lignment.start,           children: [             Text(               'Financial Overview',         ...`
16. **Line 1254**: "Revenue Trend"
   *Context*: `lignment.start,           children: [             Text(               'Revenue Trend',              ...`
17. **Line 1318**: "User ${user.statusText =="
   *Context*: `nackBar(           SnackBar(             content: Text(                 'User ${user.statusText == '...`
18. **Line 1392**: "${_selectedContentIds.length} items approved successfully"
   *Context*: `ckBar(           SnackBar(               content: Text(                   '${_selectedContentIds.len...`
19. **Line 1418**: "${_selectedContentIds.length} items rejected successfully"
   *Context*: `ckBar(           SnackBar(               content: Text(                   '${_selectedContentIds.len...`
20. **Line 532**: "Search users..."
   *Context*: `decoration: InputDecoration(               hintText: 'Search users...',               prefixIcon: co...`
21. **Line 777**: "Search content..."
   *Context*: `r,         decoration: InputDecoration(           hintText: 'Search content...',           prefixIco...`
22. **Line 158**: "Refresh Data"
   *Context*: `onPressed: _loadAllData,             tooltip: 'Refresh Data',           ),         ],       ),      ...`
23. **Line 543**: "Approve Selected"
   *Context*: `: null,                           tooltip: 'Approve Selected',                         ),...`
24. **Line 550**: "Ban Selected"
   *Context*: `: null,                           tooltip: 'Ban Selected',                         ),...`
25. **Line 560**: "Exit Selection Mode"
   *Context*: `},                           tooltip: 'Exit Selection Mode',                         ),...`
26. **Line 571**: "Enter Selection Mode"
   *Context*: `);                       },                       tooltip: 'Enter Selection Mode',                  ...`
27. **Line 795**: "Reject Selected"
   *Context*: `: null,                       tooltip: 'Reject Selected',                     ),                    ...`
28. **Line 100**: "Failed to load admin data: $e"
   *Context*: `catch (e) {       setState(() {         _error = 'Failed to load admin data: $e';       });     } fi...`
29. **Line 149**: "Admin Dashboard"
   *Context*: `appBar: EnhancedUniversalHeader(         title: 'Admin Dashboard',         showBackButton: false,   ...`
30. **Line 295**: "Total Users"
   *Context*: `_buildKPICard(                       'Total Users',                       _users.length.toString(),...`
31. **Line 301**: "Pending Reviews"
   *Context*: `_buildKPICard(                       'Pending Reviews',                       _pendingReviews.length...`
32. **Line 307**: "Total Content"
   *Context*: `_buildKPICard(                       'Total Content',                       _allContent.length.toStr...`
33. **Line 377**: "Review Content"
   *Context*: `_buildQuickActionButton(                   'Review Content',                   Icons.rate_review,...`
34. **Line 382**: "Manage Users"
   *Context*: `_buildQuickActionButton(                   'Manage Users',                   Icons.people,...`
35. **Line 387**: "Financial Reports"
   *Context*: `_buildQuickActionButton(                   'Financial Reports',                   Icons.analytics,...`
36. **Line 392**: "System Settings"
   *Context*: `_buildQuickActionButton(                   'System Settings',                   Icons.settings,...`
37. **Line 698**: "Pending Review"
   *Context*: `2FF),             tabs: [               Tab(text: 'Pending Review'),               Tab(text: 'All Co...`
38. **Line 699**: "All Content"
   *Context*: `(text: 'Pending Review'),               Tab(text: 'All Content'),               Tab(text: 'Reported'...`
39. **Line 1028**: "Total Events"
   *Context*: `eViews ?? 0, Colors.blue),         _buildStatCard('Total Events', _analytics?.totalEvents ?? 0, Colo...`
40. **Line 1029**: "Bounce Rate"
   *Context*: `vents ?? 0, Colors.green),         _buildStatCard('Bounce Rate', '${(_analytics?.bounceRate ?? 0.0)....`
41. **Line 1091**: "Total Paid Out"
   *Context*: `child: _buildFinancialMetric(                     'Total Paid Out',                     financial !=...`
42. **Line 1099**: "Pending Payouts"
   *Context*: `child: _buildFinancialMetric(                     'Pending Payouts',                     financial !...`
43. **Line 1202**: "Total Revenue"
   *Context*: `child: _buildFinancialMetric(                     'Total Revenue',                     financial != ...`
44. **Line 1212**: "Monthly Revenue"
   *Context*: `child: _buildFinancialMetric(                     'Monthly Revenue',                     financial !...`
45. **Line 181**: "Dashboard"
   *Context*: `rcularProgressIndicator())                     : _error != null                         ? _buildErro...`
46. **Line 491**: "Healthy"
   *Context*: `isHealthy ? Icons.check_circle : Icons.error,           color: isHealthy ? Colors.green : Colors.red...`
47. **Line 501**: ",
          style: TextStyle(
            fontSize: 10,
            color: isHealthy ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  // ==================== USER MANAGEMENT TAB ====================
  Widget _buildUserManagementTab() {
    return Column(
      children: [
        _buildUserSearchAndFilters(),
        Expanded(
          child: _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildUserSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText:"
   *Context*: `Text(           isHealthy ? 'Healthy' : 'Error',           style: TextStyle(             fontSize: 1...`
48. **Line 213**: "Users"
   *Context*: `cons.dashboard, size: 20),           ),           Tab(             text: 'Users',             icon: ...`
49. **Line 217**: "Content"
   *Context*: `n(Icons.people, size: 20),           ),           Tab(             text: 'Content',             icon...`
50. **Line 221**: "Financial"
   *Context*: `s.content_copy, size: 20),           ),           Tab(             text: 'Financial',             ic...`
51. **Line 700**: "Reported"
   *Context*: `Tab(text: 'All Content'),               Tab(text: 'Reported'),             ],           ),          ...`
52. **Line 947**: "Revenue"
   *Context*: `or(0xFF8C52FF),             tabs: [               Tab(text: 'Revenue'),               Tab(text: 'Ads...`
53. **Line 948**: "Ads"
   *Context*: `Tab(text: 'Revenue'),               Tab(text: 'Ads'),               Tab(text: 'Payouts'),...`
54. **Line 949**: "Payouts"
   *Context*: `'),               Tab(text: 'Ads'),               Tab(text: 'Payouts'),             ],           ), ...`

## All Unique English Texts (Alphabetical)
1. "$label ($count)"
2. "$label:"
3. "$label: $value"
4. "$percentage%"
5. "${(status.migrationProgress * 100).toStringAsFixed(1)}%"
6. "${10 + index}:${(index * 3).toString().padLeft(2,"
7. "${_selectedContentIds.length} items approved successfully"
8. "${_selectedContentIds.length} items rejected successfully"
9. "${_selectedTransactionIds.length} selected"
10. "${_selectedUserIds.length} users selected"
11. "${artwork.description.substring(0, 50)}..."
12. "${comments.length} total"
13. "${refundTransactions.length} Refunds"
14. "${reports.length} total"
15. "${selectedTransactions.length} transactions selected"
16. "${server["
17. "${status.migratedDocuments}/${status.totalDocuments} documents migrated"
18. "${transaction.userName} • ${transaction.displayType}"
19. ");

    // CSV Data rows
    for (final transaction in transactions) {
      final description =
          transaction.description?.replaceAll("
20. ");
        _showErrorSnackBar("
21. ");
      _showErrorSnackBar("
22. ");
      setState(() => _isLoading = false);
      _showErrorSnackBar("
23. ");
      throw Exception("
24. ",
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildContentFilterChip("
25. ",
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PLACEHOLDER TABS ====================
  Widget _buildModernUserManagementTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8C52FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Statistics Overview
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text("
26. ",
          _settings!.errorLoggingEnabled,
          (value) => _updateSetting(value, (s) => s.errorLoggingEnabled,
              (s, v) => s.copyWith(errorLoggingEnabled: v)),
        ),
        _buildSwitchSetting("
27. ",
          style: TextStyle(
            fontSize: 10,
            color: isHealthy ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  // ==================== USER MANAGEMENT TAB ====================
  Widget _buildUserManagementTab() {
    return Column(
      children: [
        _buildUserSearchAndFilters(),
        Expanded(
          child: _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildUserSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText:"
28. ",
      );
    }

    return buffer.toString();
  }

  /// Download CSV file (web) or save to device
  Future<void> _downloadCsvFile(String csvContent, String fileName) async {
    try {
      if (kIsWeb) {
        // Web implementation using data URL for download
        final bytes = utf8.encode(csvContent);
        final base64Data = base64Encode(bytes);
        final dataUrl ="
29. ".tr(namedArgs: {"
30. "/admin/dashboard"
31. "2024-12-${(index + 1).toString().padLeft(2,"
32. ":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Simplified chart representation
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text("
33. ": e.toString()});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText:"
34. ": e.toString()});
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    final confirmed = await _showConfirmationDialog("
35. ": e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("
36. ": e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<void> _migrateGeoFields() async {
    final confirmed = await _showConfirmationDialog("
37. ": e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<void> _rollbackMigration() async {
    final confirmed = await _showConfirmationDialog("
38. "API Services"
39. "Account Created"
40. "Account Information"
41. "Achievements"
42. "Actions"
43. "Active User"
44. "Active Users"
45. "Activity"
46. "Activity Summary"
47. "Ad Management"
48. "Admin"
49. "Admin Access Control"
50. "Admin Actions"
51. "Admin Command Center"
52. "Admin Dashboard"
53. "Admin Flags"
54. "Admin Information"
55. "Admin Notes"
56. "Admin Settings"
57. "Admin authentication required"
58. "Admin processed refund"
59. "Ads"
60. "Advanced Search & Filters"
61. "Advertisements"
62. "Alerts"
63. "All"
64. "All Content"
65. "All dates"
66. "Amount Range"
67. "Analytics"
68. "App Description"
69. "Approve Selected"
70. "Approved by admin"
71. "Are you sure you want to create a backup of the database?"
72. "Are you sure you want to delete this ${content.type}?"
73. "Are you sure you want to process refunds for all selected transactions?"
74. "Are you sure you want to remove this user\"
75. "Are you sure you want to reset all settings to default values?"
76. "Artwork Sales"
77. "Auto-approve Content"
78. "Average Revenue"
79. "Average revenue data will appear here"
80. "Average revenue per transaction: ${_formatCurrency(_analytics!.financialMetrics.averageRevenuePerUser)}"
81. "Avg Session"
82. "Avg Transaction"
83. "Ban Selected"
84. "Banned Words (comma-separated)"
85. "Bio"
86. "Bounce Rate"
87. "Bulk admin refund"
88. "By ${content.authorName}"
89. "By ${review.authorName}"
90. "By: ${noteData["
91. "CPU Usage"
92. "Cache Duration (hours)"
93. "Cancel"
94. "Chart visualization will be implemented\nwith real Firebase data using fl_chart"
95. "Comments"
96. "Configure platform settings"
97. "Content"
98. "Content Deleted"
99. "Content Moderation"
100. "Content Settings"
101. "Created: ${artwork.createdAt.toString().split("
102. "Critical Alerts"
103. "Danger Zone"
104. "Dashboard"
105. "Data Access"
106. "Data Export"
107. "Date: ${intl.DateFormat("
108. "Delete Content"
109. "Description"
110. "Details"
111. "Disabled account for $user"
112. "Edit Content"
113. "Edit permissions for $user"
114. "Email"
115. "Email Verified"
116. "Enable Admin Alerts"
117. "Enable Analytics"
118. "Enable Artwork Ratings"
119. "Enable Comments"
120. "Enable Content Reporting"
121. "Enable Email Notifications"
122. "Enable Error Logging"
123. "Enable IP Blocking"
124. "Enable Performance Monitoring"
125. "Enable Push Notifications"
126. "Enable Registration"
127. "Enable Two-Factor Authentication"
128. "Enter Selection Mode"
129. "Enter description"
130. "Enter title"
131. "Error downloading CSV file: $e"
132. "Error exporting transactions: $e"
133. "Error loading payment data: $e"
134. "Error loading settings"
135. "Error processing bulk refund: $e"
136. "Error processing refund: $e"
137. "Error updating transaction statuses: $e"
138. "Existing content will be marked as"
139. "Exit Selection Mode"
140. "Export Selected"
141. "Export completed successfully (${_filteredTransactions.length} records)"
142. "Export completed successfully (${selectedTransactions.length} records)"
143. "Exported transaction data"
144. "Failed to download CSV file"
145. "Failed to export transactions"
146. "Failed to load admin data: $e"
147. "Failed to load dashboard data: $e"
148. "Failed to load payment data"
149. "Failed to process bulk refunds"
150. "Failed to process refund: ${e.toString()}"
151. "Failed to refund transaction ${transaction.id}: $e"
152. "Failed to trigger capture approval rewards: $e"
153. "Failed to update transaction statuses"
154. "Featured Users"
155. "File Storage"
156. "Financial"
157. "Financial Analytics"
158. "Financial Insights"
159. "Financial Overview"
160. "Financial Reports"
161. "Flagged by admin"
162. "Full Name"
163. "General Settings"
164. "Healthy"
165. "IP Address/Range"
166. "IP Whitelist"
167. "Image Management"
168. "Item"
169. "John Admin"
170. "Joined ${_formatDate(user.createdAt)}"
171. "Key Performance Indicators"
172. "Last Active"
173. "Last updated: ${DateTime.now().toString().substring(0, 19)}"
174. "Loading admin data..."
175. "Location"
176. "Login Attempt Window (minutes)"
177. "MMM dd, yyyy HH:mm"
178. "Maintenance Message"
179. "Maintenance Mode"
180. "Maintenance Settings"
181. "Manage Users"
182. "Max Artworks per User"
183. "Max Login Attempts"
184. "Max Upload Size (MB)"
185. "Media"
186. "Memory Usage"
187. "Metric"
188. "Migrating..."
189. "Mike Manager"
190. "Moderate pending submissions"
191. "Monthly Recurring"
192. "Monthly Revenue"
193. "No Recent Transactions"
194. "No comments"
195. "No details available"
196. "No eligible transactions for refund"
197. "No paymentIntentId found for transaction ${transaction.id}."
198. "No reason provided"
199. "No recent activity"
200. "No reports"
201. "No transactions selected"
202. "Notification Settings"
203. "Office Network"
204. "Online Users"
205. "Oops! Something went wrong"
206. "Overview"
207. "Part of bulk refund operation"
208. "Password"
209. "Password Reset Required"
210. "Pause Real-time"
211. "Payment Management"
212. "Payment Method"
213. "Payment Methods"
214. "Payout Management"
215. "Payout Summary"
216. "Payouts"
217. "Peak Today"
218. "Pending Payouts"
219. "Pending Review"
220. "Pending Reviews"
221. "Per transaction"
222. "Performance"
223. "Performance Chart\n(Real-time data visualization)"
224. "Performance Metrics"
225. "Performance Overview"
226. "Personal Information"
227. "Process Refund"
228. "Processed on ${DateTime.now().subtract(Duration(days: index)).toString().split("
229. "Profile Updated"
230. "Quick Actions"
231. "REPORTED CONTENT"
232. "Real-time Performance"
233. "Reason for deletion"
234. "Reason for rejection"
235. "Recent Activity"
236. "Recent Ad Activity"
237. "Recent Alerts"
238. "Recent Content"
239. "Recent Payouts"
240. "Recent Transactions"
241. "Recording refund in database only."
242. "Refresh Data"
243. "Refund processed successfully"
244. "Refunds"
245. "Reject Selected"
246. "Rejected by admin"
247. "Removed admin privileges for $user"
248. "Report Count"
249. "Reported"
250. "Reported by: ${(report["
251. "Reports"
252. "Require Email Verification"
253. "Response Time"
254. "Revenue"
255. "Revenue ${_analytics!.financialMetrics.revenueGrowth >= 0 ?"
256. "Revenue Breakdown"
257. "Revenue Chart"
258. "Revenue Growth"
259. "Revenue Trend"
260. "Revenue and analytics"
261. "Revenue growth data will appear here"
262. "Review Content"
263. "Review cleared successfully"
264. "Role: ${user.userType ??"
265. "Run Migration"
266. "STATUS_UPDATE"
267. "Sarah Security"
268. "Save"
269. "Search"
270. "Search artwork..."
271. "Search content by title, author, or description..."
272. "Search content..."
273. "Search logs..."
274. "Search transactions..."
275. "Search users by name, email, or username..."
276. "Search users..."
277. "Security Settings"
278. "Server Status"
279. "Session Time"
280. "Settings Change"
281. "Start Real-time"
282. "Status"
283. "Status Management"
284. "Subscriptions"
285. "Success Rate"
286. "Successfully processed $successCount refunds"
287. "Successfully updated ${_selectedTransactionIds.length} transactions"
288. "Suspended Users"
289. "Suspended: ${_formatDateTime(_currentUser.suspendedAt!)}"
290. "System Alerts"
291. "System Health"
292. "System Settings"
293. "System Status: ${_systemMetrics["
294. "Tags"
295. "Tags: ${artwork.tags?.join("
296. "This action cannot be undone."
297. "This migration adds standardized moderation status fields to all content collections (posts, comments, artwork, captures, ads)."
298. "Timestamp: 2024-12-24 ${10 + index}:${(index * 3).toString().padLeft(2,"
299. "Title"
300. "Total Content"
301. "Total Events"
302. "Total Paid Out"
303. "Total Refunds"
304. "Total Revenue"
305. "Total Transactions"
306. "Total Users"
307. "Total amount: \$${selectedTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}"
308. "Total: \$${refundTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}"
309. "Transaction Export"
310. "Transaction ID,User ID,User Name,Type,Amount,Currency,Status,Payment Method,Transaction Date,Description,Item Title"
311. "Transaction Type"
312. "Transaction Volume"
313. "Transaction data will appear here"
314. "Transaction data will appear here once payments are processed."
315. "Transactions"
316. "Unknown Server"
317. "Unknown action"
318. "Unknown alert"
319. "Unknown error"
320. "Unknown error occurred"
321. "Unknown time"
322. "User"
323. "User ${!_currentUser.isVerified ?"
324. "User ${newFeaturedStatus ?"
325. "User ${user.statusText =="
326. "User Created"
327. "User Details"
328. "User Management"
329. "User Settings"
330. "User Suspended"
331. "User Type"
332. "User administration tools"
333. "User: ${users[index % users.length]} | IP: 192.168.1.${100 + index}"
334. "Username"
335. "Users"
336. "Verified Users"
337. "View Details"
338. "Warning Alerts"
339. "Zip Code"
340. "\$${(100 + (index * 50)).toStringAsFixed(2)}"
341. "\$${totalAmount.toStringAsFixed(2)}"
342. "by ${content.authorName}"
343. "user-not-found"
344. "}),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error ="