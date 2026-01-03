import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ServiceProvider extends HiveObject {
  String id;
  String name;
  String serviceType; // 'electrician', 'plumber', 'carpenter', 'painter', etc.
  String phone;
  String? email;
  double rating;
  int totalJobs;
  String? address;
  List<String> specialties;
  bool isAvailable;
  String? image;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.phone,
    this.email,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.address,
    this.specialties = const [],
    this.isAvailable = true,
    this.image,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'].toString(),
      name: json['name'].toString(),
      serviceType: json['serviceType'].toString(),
      phone: json['phone'].toString(),
      email: json['email']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: json['totalJobs'] as int? ?? 0,
      address: json['address']?.toString(),
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : [],
      isAvailable: json['isAvailable'] as bool? ?? true,
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serviceType': serviceType,
      'phone': phone,
      'email': email,
      'rating': rating,
      'totalJobs': totalJobs,
      'address': address,
      'specialties': specialties,
      'isAvailable': isAvailable,
      'image': image,
    };
  }

  String get serviceTypeDisplayName {
    switch (serviceType.toLowerCase()) {
      case 'electrician':
        return 'Electrician';
      case 'plumber':
        return 'Plumber';
      case 'carpenter':
        return 'Carpenter';
      case 'painter':
        return 'Painter';
      case 'ac_repair':
        return 'AC Repair';
      case 'appliance_repair':
        return 'Appliance Repair';
      case 'cleaning':
        return 'Cleaning Service';
      default:
        return serviceType;
    }
  }

  IconData get serviceTypeIcon {
    switch (serviceType.toLowerCase()) {
      case 'electrician':
        return Icons.electrical_services;
      case 'plumber':
        return Icons.plumbing;
      case 'carpenter':
        return Icons.hardware;
      case 'painter':
        return Icons.format_paint;
      case 'ac_repair':
        return Icons.ac_unit;
      case 'appliance_repair':
        return Icons.build;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.handyman;
    }
  }
}

