import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sms/controllers/sms_controller.dart';

class SmsHistoryScreen extends ConsumerStatefulWidget {
  const SmsHistoryScreen({super.key});

  @override
  ConsumerState<SmsHistoryScreen> createState() => _SmsHistoryScreenState();
}

class _SmsHistoryScreenState extends ConsumerState<SmsHistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sent':
        return AppTheme.secondaryColor;
      case 'Failed':
        return AppTheme.dangerColor;
      case 'Retrying':
      case 'Pending':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Sent':
        return Icons.check_circle_rounded;
      case 'Failed':
        return Icons.error_outline_rounded;
      case 'Retrying':
        return Icons.sync;
      case 'Pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = smsList.where((sms) {
      final matchesSearch = sms.recipient.contains(_searchQuery) ||
                            sms.messageType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            sms.messageContent.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Sent' && sms.status == 'Sent') return true;
      if (_selectedFilter == 'Failed' && sms.status == 'Failed') return true;
      if (_selectedFilter == 'Retrying' && (sms.status == 'Retrying' || sms.status == 'Pending')) return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('SMS Delivery Logs', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search logs by recipient, type or content...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Sent', 'Failed', 'Retrying'].map((filter) {
                      final selected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Logs List View
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: FadeIn(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sms_failed_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No SMS delivery records found.',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final sms = filteredList[index];
                      final statusColor = _getStatusColor(sms.status);
                      final statusIcon = _getStatusIcon(sms.status);
                      final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(sms.sentAt);

                      return FadeInUp(
                        duration: Duration(milliseconds: 200 + (index * 50)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCardColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Indicator badge
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(statusIcon, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 14),

                              // Text content details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          sms.recipient,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5),
                                        ),
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      sms.messageType,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      sms.messageContent,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white70 : const Color(0xff475569),
                                        height: 1.35,
                                      ),
                                    ),
                                    if (sms.retryCount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Retry Attempt Count: ${sms.retryCount}',
                                        style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.dangerColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Retry Action button for failed logs
                              if (sms.status == 'Failed') ...[
                                const SizedBox(width: 8),
                                Align(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                                    tooltip: 'Retry sending now',
                                    onPressed: () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Retrying dispatch to ${sms.recipient}...'),
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      );
                                      final sent = await ref.read(smsControllerProvider.notifier).retrySms(sms.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(sent ? 'SMS sent successfully!' : 'Retry attempt failed.'),
                                            backgroundColor: sent ? AppTheme.secondaryColor : AppTheme.dangerColor,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
