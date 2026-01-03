import 'package:flutter/material.dart';
import '../models/room.dart';
import '../utils/responsive.dart';

class RoomStatusCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomStatusCard({
    super.key,
    required this.room,
    this.onTap,
  });

  Color getStatusColor() {
    switch (room.status) {
      case 'occupied':
        return Colors.green;
      case 'vacant':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String getStatusText() {
    switch (room.status) {
      case 'occupied':
        return 'Occupied';
      case 'vacant':
        return 'Vacant';
      case 'maintenance':
        return 'Maintenance';
      default:
        return room.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 4,
        vertical: isMobile ? 8 : 10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: getStatusColor().withOpacity(0.1),
          highlightColor: getStatusColor().withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                Container(
                  width: isMobile ? 60 : 70,
                  height: isMobile ? 60 : 70,
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      room.number,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 16 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.number}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: isMobile ? 16 : 18,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              getStatusText(),
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: getStatusColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              room.type == 'tenant' ? 'Tenant' : 'Paying Guest',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹${room.rent.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: isMobile ? 18 : 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (room.type == 'paying_guest') ...[
                      SizedBox(height: isMobile ? 4 : 6),
                      Text(
                        '${room.currentOccupancy}/${room.capacity} beds',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 11 : 12,
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

