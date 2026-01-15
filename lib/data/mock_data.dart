import '../models/tenant.dart';
import '../models/room.dart';
import '../models/complaint.dart';
import '../models/payment.dart';

class MockData {
  static List<Tenant> getTenants() {
    return [
      Tenant(
        id: '1',
        name: 'Rajesh Kumar',
        phone: '+91 9876543210',
        email: 'rajesh@example.com',
        roomNumber: '101',
        moveInDate: DateTime(2024, 1, 15),
        monthlyRent: 15000,
        type: 'tenant',
        isActive: true,
      ),
      Tenant(
        id: '2',
        name: 'Priya Sharma',
        phone: '+91 9876543211',
        email: 'priya@example.com',
        roomNumber: '102',
        moveInDate: DateTime(2024, 2, 1),
        monthlyRent: 12000,
        type: 'paying_guest',
        isActive: true,
      ),
      Tenant(
        id: '3',
        name: 'Amit Patel',
        phone: '+91 9876543212',
        email: 'amit@example.com',
        roomNumber: '201',
        moveInDate: DateTime(2023, 12, 10),
        monthlyRent: 18000,
        type: 'tenant',
        isActive: true,
      ),
      Tenant(
        id: '4',
        name: 'Sneha Reddy',
        phone: '+91 9876543213',
        email: 'sneha@example.com',
        roomNumber: '202',
        moveInDate: DateTime(2024, 3, 5),
        monthlyRent: 14000,
        type: 'paying_guest',
        isActive: true,
      ),
    ];
  }

  static List<Room> getRooms() {
    return [
      Room(
        id: '1',
        buildingId: '1',
        number: '101',
        type: 'rented',
        status: 'occupied',
        tenantId: '1',
        rent: 15000,
        capacity: 1,
        currentOccupancy: 1,
      ),
      Room(
        id: '2',
        buildingId: '1',
        number: '102',
        type: 'pg',
        status: 'occupied',
        tenantId: '2',
        rent: 12000,
        capacity: 2,
        currentOccupancy: 1,
      ),
      Room(
        id: '3',
        buildingId: '1',
        number: '201',
        type: 'rented',
        status: 'occupied',
        tenantId: '3',
        rent: 18000,
        capacity: 1,
        currentOccupancy: 1,
      ),
      Room(
        id: '4',
        buildingId: '1',
        number: '202',
        type: 'pg',
        status: 'occupied',
        tenantId: '4',
        rent: 14000,
        capacity: 3,
        currentOccupancy: 1,
      ),
      Room(
        id: '5',
        buildingId: '1',
        number: '301',
        type: 'rented',
        status: 'vacant',
        rent: 16000,
        capacity: 1,
        currentOccupancy: 0,
      ),
      Room(
        id: '6',
        buildingId: '1',
        number: '302',
        type: 'pg',
        status: 'maintenance',
        rent: 13000,
        capacity: 2,
        currentOccupancy: 0,
      ),
    ];
  }

  static List<Complaint> getComplaints() {
    final now = DateTime.now();
    return [
      Complaint(
        id: '1',
        title: 'Water Leakage',
        description: 'Water leaking from bathroom ceiling',
        roomNumber: '101',
        tenantId: '1',
        tenantName: 'Rajesh Kumar',
        status: 'pending',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        priority: 'high',
      ),
      Complaint(
        id: '2',
        title: 'AC Not Working',
        description: 'Air conditioner not cooling properly',
        roomNumber: '201',
        tenantId: '3',
        tenantName: 'Amit Patel',
        status: 'in_progress',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        priority: 'urgent',
      ),
      Complaint(
        id: '3',
        title: 'Door Lock Issue',
        description: 'Main door lock is jammed',
        roomNumber: '102',
        tenantId: '2',
        tenantName: 'Priya Sharma',
        status: 'resolved',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 8)),
        resolvedAt: now.subtract(const Duration(days: 8)),
        priority: 'medium',
      ),
    ];
  }

  static List<Payment> getPayments() {
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    
    return [
      Payment(
        id: '1',
        tenantId: '1',
        tenantName: 'Rajesh Kumar',
        roomNumber: '101',
        amount: 15000,
        dueDate: DateTime(now.year, now.month, 1),
        paidDate: DateTime(now.year, now.month, 2),
        status: 'paid',
        type: 'rent',
        paymentMethod: 'online',
        month: monthNames[now.month - 1],
        year: now.year,
      ),
      Payment(
        id: '2',
        tenantId: '2',
        tenantName: 'Priya Sharma',
        roomNumber: '102',
        amount: 12000,
        dueDate: DateTime(now.year, now.month, 1),
        status: 'paid',
        type: 'rent',
        paymentMethod: 'cash',
        month: monthNames[now.month - 1],
        year: now.year,
      ),
      Payment(
        id: '3',
        tenantId: '3',
        tenantName: 'Amit Patel',
        roomNumber: '201',
        amount: 18000,
        dueDate: DateTime(now.year, now.month, 1),
        status: 'overdue',
        type: 'rent',
        paymentMethod: 'cash',
        month: monthNames[now.month - 1],
        year: now.year,
      ),
    ];
  }
}

