import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import 'cancer_dashboard_screen.dart';

class CancerAuditLogsScreen extends ConsumerStatefulWidget {
  const CancerAuditLogsScreen({super.key});

  @override
  ConsumerState<CancerAuditLogsScreen> createState() => _CancerAuditLogsScreenState();
}

class _CancerAuditLogsScreenState extends ConsumerState<CancerAuditLogsScreen> {
  List<CancerAuditLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    final currentRole = ref.read(cancerRoleProvider);
    if (currentRole != 'Administrator') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final repo = ref.read(cancerRepositoryProvider);
    try {
      final list = await repo.getAuditLogs(currentRole, 'LAKSHMI_001');
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = ref.watch(cancerRoleProvider);
    final isAdmin = currentRole == 'Administrator';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Security & Access Logs', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isAdmin ? () {
              setState(() {
                _isLoading = true;
              });
              _fetchAuditLogs();
            } : null,
          )
        ],
      ),
      body: !isAdmin
          ? Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel_rounded, size: 56, color: AppTheme.dangerColor),
                      const SizedBox(height: 20),
                      Text(
                        'ACCESS RESTRICTED',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Audit logs contain sensitive HIPAA and NHM security records. You must switch your role to "Administrator" in the top bar of the Cancer Dashboard to access this console.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No logs generated yet.', style: GoogleFonts.inter(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final timeStr = DateFormat('dd-MM-yy HH:mm:ss').format(log.timestamp);

                        return FadeInUp(
                          duration: Duration(milliseconds: 100 + (index * 40)),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: _getActionColor(log.action).withOpacity(0.1),
                                child: Icon(_getActionIcon(log.action), color: _getActionColor(log.action), size: 18),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(log.action, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 10.5)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.details, style: GoogleFonts.inter(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('Operator: ${log.userId} ', style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text(log.role, style: const TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('REGISTER')) return Icons.person_add_rounded;
    if (action.contains('SCREEN')) return Icons.analytics_rounded;
    if (action.contains('TREATMENT')) return Icons.healing_rounded;
    if (action.contains('REFERRAL')) return Icons.launch_rounded;
    if (action.contains('ACCESS')) return Icons.lock_open_rounded;
    return Icons.info_outline_rounded;
  }

  Color _getActionColor(String action) {
    if (action.contains('REGISTER')) return AppTheme.primaryColor;
    if (action.contains('SCREEN')) return AppTheme.secondaryColor;
    if (action.contains('TREATMENT')) return Colors.purple.shade600;
    if (action.contains('REFERRAL')) return Colors.teal.shade600;
    if (action.contains('ACCESS')) return AppTheme.dangerColor;
    return Colors.grey;
  }
}
