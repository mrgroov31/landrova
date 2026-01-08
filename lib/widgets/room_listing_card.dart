import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/room.dart';
import '../utils/responsive.dart';

class RoomListingCard extends StatelessWidget {
  final Room room;
  final String? tenantName;
  final String? buildingName;
  final VoidCallback? onTap;

  const RoomListingCard({
    super.key,
    required this.room,
    this.tenantName,
    this.buildingName,
    this.onTap,
  });

  Color getStatusColor() {
    if (room.hasTenant || room.isOccupied) {
      return Colors.green;
    }
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
    if (room.hasTenant || room.isOccupied) {
      return 'Occupied';
    }
    switch (room.status) {
      case 'occupied':
        return 'Occupied';
      case 'vacant':
        return 'Available';
      case 'maintenance':
        return 'Maintenance';
      default:
        return room.status;
    }
  }

  String _getRoomImageUrl() {
    // Use Picsum Photos for placeholder images (more reliable than Unsplash)
    // Generate image ID based on room number for variety
    final roomHash = room.number.hashCode;
    final imageId = (roomHash.abs() % 1000) + 1;
    return 'https://picsum.photos/seed/room$imageId/800/600';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isMobile ? 350 : 480, // Fixed height for carousel
        margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: _getRoomImageUrl(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          getStatusColor().withOpacity(0.3),
                          getStatusColor().withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: getStatusColor(),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          getStatusColor().withOpacity(0.3),
                          getStatusColor().withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        room.type == 'tenant' ? Icons.home : Icons.hotel,
                        size: 80,
                        color: getStatusColor().withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient Overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Content on top of image
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    // Top section - Status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            getStatusText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                    // Bottom section - Room details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'house ${room.number}',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (buildingName != null) ...[
                          SizedBox(height: isMobile ? 4 : 6),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: isMobile ? 14 : 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  buildingName!,
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: isMobile ? 8 : 12),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '4.${(room.number.hashCode % 10)}',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '(${(room.number.hashCode % 50) + 10} reviews)',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.white.withOpacity(0.9),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              room.type == 'tenant' ? 'Tenant Room' : 'Paying Guest',
                              Icons.person,
                              isMobile,
                            ),
                            if (room.type == 'paying_guest')
                              _buildInfoChip(
                                '${room.currentOccupancy}/${room.capacity} beds',
                                Icons.bed,
                                isMobile,
                              ),
                          ],
                        ),
                     
                        SizedBox(height: isMobile ? 12 : 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${room.rent.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'per month',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // GestureDetector(
                            //   onTap: onTap,
                            //   child: Container(
                            //     padding: EdgeInsets.symmetric(
                            //       horizontal: isMobile ? 16 : 20,
                            //       vertical: isMobile ? 10 : 12,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       color: Colors.white,
                            //       borderRadius: BorderRadius.circular(12),
                            //       boxShadow: [
                            //         BoxShadow(
                            //           color: Colors.black.withOpacity(0.3),
                            //           blurRadius: 8,
                            //           offset: const Offset(0, 2),
                            //         ),
                            //       ],
                            //     ),
                            //     child: Text(
                            //       'View Details',
                            //       style: TextStyle(
                            //         color: theme.colorScheme.primary,
                            //         fontSize: isMobile ? 13 : 14,
                            //         fontWeight: FontWeight.w600,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                               if (room.hasTenant || room.currentOccupancy > 0) ...[
                          SizedBox(height: isMobile ? 8 : 12),
                          _buildTenantAvatars(isMobile),
                        ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantAvatars(bool isMobile) {
    // Generate mock tenant data based on room occupancy
    List<Map<String, String>> tenants = [];
    
    if (room.hasTenant && room.tenant != null) {
      // Use actual tenant data if available
      tenants.add({
        'name': room.tenant!.name,
        'initial': room.tenant!.name.isNotEmpty ? room.tenant!.name[0].toUpperCase() : 'T',
      });
    } else if (tenantName != null) {
      // Use provided tenant name
      tenants.add({
        'name': tenantName!,
        'initial': tenantName!.isNotEmpty ? tenantName![0].toUpperCase() : 'T',
      });
    }
    
    // Add mock tenants for remaining occupancy (for PG rooms)
    int remainingOccupancy = room.currentOccupancy - tenants.length;
    if (remainingOccupancy > 0) {
      List<String> mockNames = ['Alex', 'Sam', 'Jordan', 'Casey', 'Taylor', 'Morgan', 'Riley', 'Avery'];
      for (int i = 0; i < remainingOccupancy && i < mockNames.length; i++) {
        tenants.add({
          'name': mockNames[i],
          'initial': mockNames[i][0],
        });
      }
    }

    if (tenants.isEmpty) return const SizedBox.shrink();

    const int maxVisibleAvatars = 4;
    final int visibleCount = tenants.length > maxVisibleAvatars ? maxVisibleAvatars : tenants.length;
    final int remainingCount = tenants.length - maxVisibleAvatars;
    final double avatarSize = isMobile ? 32.0 : 36.0;
    const double overlapOffset = 20.0;

    return Row(
      children: [
        // Icon(
        //   Icons.people_outline,
        //   size: 16,
        //   color: Colors.white.withOpacity(0.9),
        // ),
        // SizedBox(width: 8),
        SizedBox(
          width: (visibleCount * overlapOffset) + avatarSize + (remainingCount > 0 ? overlapOffset + avatarSize : 0),
          height: avatarSize,
          child: Stack(
            children: [
              // Visible tenant avatars
              ...List.generate(visibleCount, (index) {
                final tenant = tenants[index];
                final colors = [
                  Colors.blue.shade400,
                  Colors.green.shade400,
                  Colors.purple.shade400,
                  Colors.orange.shade400,
                  Colors.pink.shade400,
                  Colors.teal.shade400,
                  Colors.indigo.shade400,
                  Colors.red.shade400,
                ];
                
                return Positioned(
                  left: index * overlapOffset,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[index % colors.length],
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        tenant['initial']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              
              // "+X" indicator for remaining tenants
              if (remainingCount > 0)
                Positioned(
                  left: visibleCount * overlapOffset,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.7),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '+$remainingCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
       
        SizedBox(width: 8),
        // Text(
        //   tenants.length == 1 ? tenants[0]['name']! : '${tenants.length} tenants',
        //   style: TextStyle(
        //     fontSize: isMobile ? 13 : 14,
        //     color: Colors.white.withOpacity(0.9),
        //     fontWeight: FontWeight.w500,
        //     shadows: [
        //       Shadow(
        //         color: Colors.black.withOpacity(0.5),
        //         blurRadius: 6,
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

