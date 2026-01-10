import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../utils/responsive.dart';
import '../utils/custom_page_route.dart';
import '../screens/complaint_detail_screen.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback? onTap;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
  });

  Color getStatusColor() {
    switch (complaint.status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getStatusBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (complaint.status) {
      case 'pending':
        return isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50;
      case 'assigned':
        return isDark ? Colors.purple.withOpacity(0.2) : Colors.purple.shade50;
      case 'in_progress':
        return isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50;
      case 'resolved':
        return isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
      default:
        return isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade50;
    }
  }

  Color getStatusBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (complaint.status) {
      case 'pending':
        return isDark ? Colors.orange.withOpacity(0.4) : Colors.orange.shade200;
      case 'assigned':
        return isDark ? Colors.purple.withOpacity(0.4) : Colors.purple.shade200;
      case 'in_progress':
        return isDark ? Colors.blue.withOpacity(0.4) : Colors.blue.shade200;
      case 'resolved':
        return isDark ? Colors.green.withOpacity(0.4) : Colors.green.shade200;
      default:
        return isDark ? Colors.grey.withOpacity(0.4) : Colors.grey.shade200;
    }
  }

  Color getPriorityColor() {
    switch (complaint.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Debug: Print to verify tap is received
          debugPrint('Complaint card tapped: ${complaint.title}');
          
          if (onTap != null) {
            debugPrint('Using custom onTap callback');
            try {
              onTap!();
            } catch (e) {
              debugPrint('Error in onTap callback: $e');
            }
          } else {
            // Navigate to detail screen with container transform
            debugPrint('Navigating to complaint detail screen (default navigation)');
            try {
              Navigator.push(
                context,
                CustomPageRoute(
                  child: ComplaintDetailScreen(complaint: complaint),
                  transition: CustomPageTransition.containerTransform,
                ),
              ).then((result) {
                debugPrint('Navigation completed with result: $result');
                // If complaint was updated, notify parent to refresh
                if (result == true) {
                  // This will be handled by the parent screen
                }
              }).catchError((error) {
                debugPrint('Navigation error: $error');
              });
            } catch (e) {
              debugPrint('Exception during navigation: $e');
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: getStatusColor().withOpacity(0.2),
        highlightColor: getStatusColor().withOpacity(0.1),
        child: Container(
          margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: getStatusBackgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: getStatusBorderColor(context),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: getStatusColor().withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Title and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 12 : 16),
                
                // Description
                Text(
                  complaint.description,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    height: 1.4,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isMobile ? 12 : 16),
                
                // Info Row
                Wrap(
                  spacing: isMobile ? 12 : 16,
                  runSpacing: isMobile ? 8 : 10,
                  children: [
                    // Room Number
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: isMobile ? 16 : 18,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                        SizedBox(width: isMobile ? 4 : 6),
                        Text(
                          'Room ${complaint.roomNumber}',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                    // Tenant Name
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: isMobile ? 16 : 18,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                        SizedBox(width: isMobile ? 4 : 6),
                        Text(
                          complaint.tenantName,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                    // Priority
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: getPriorityColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: getPriorityColor().withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: isMobile ? 12 : 14,
                            color: getPriorityColor(),
                          ),
                          SizedBox(width: isMobile ? 3 : 4),
                          Text(
                            complaint.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              color: getPriorityColor(),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 12 : 16),
                
                // Date and Assignment Status
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: isMobile ? 14 : 16,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      'Created: ${dateFormat.format(complaint.createdAt)}',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    // Show assignment indicator if service provider is assigned
                    if (complaint.serviceProviderId != null && complaint.serviceProviderId!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_ind,
                              size: 12,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'ASSIGNED',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

