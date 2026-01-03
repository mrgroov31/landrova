import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/complaint.dart';
import '../models/payment.dart';

class ApiService {
  // Simulate API calls by loading JSON files
  static Future<Map<String, dynamic>> fetchRooms() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/rooms.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchTenants() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/tenants.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchComplaints() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/complaints.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchPayments() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/payments.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/dashboard.json');
    return json.decode(response);
  }

  // Parse responses to models
  static List<Room> parseRooms(Map<String, dynamic> response) {
    final List<dynamic> roomsData = response['data']['rooms'];
    return roomsData.map((json) => Room.fromJson(json)).toList();
  }

  static List<Tenant> parseTenants(Map<String, dynamic> response) {
    final List<dynamic> tenantsData = response['data']['tenants'];
    return tenantsData.map((json) => Tenant.fromJson(json)).toList();
  }

  static List<Complaint> parseComplaints(Map<String, dynamic> response) {
    final List<dynamic> complaintsData = response['data']['complaints'];
    return complaintsData.map((json) => Complaint.fromJson(json)).toList();
  }

  static List<Payment> parsePayments(Map<String, dynamic> response) {
    final List<dynamic> paymentsData = response['data']['payments'];
    return paymentsData.map((json) => Payment.fromJson(json)).toList();
  }
}

