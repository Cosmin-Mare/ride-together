import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus {
  pending,
  inProgress,
  arrivedAtOrigin,
  departedFromOrigin,
  arrivedAtDestination,
  completed,
  cancelled,
}

class Driver {
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
        name: json['name'] ?? 'Driver',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        profilePicture: json['profilePicture']);
  }
  final String name;
  final double latitude;
  final double longitude;
  final String? profilePicture;

  Driver({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'profilePicture': profilePicture,
    };
  }
}

class CustomLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  CustomLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Ride {
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      origin: CustomLocation(
          name: json['origin']['name'],
          address: json['origin']['address'],
          latitude: (json['origin']['latitude'] ?? json['origin']['position']?.latitude).toDouble(),
          longitude: (json['origin']['longitude'] ?? json['origin']['position']?.longitude).toDouble()),
      destination: CustomLocation(
          name: json['destination']['name'],
          address: json['destination']['address'],
          latitude: (json['destination']['latitude'] ?? json['destination']['position']?.latitude).toDouble(),
          longitude: (json['destination']['longitude'] ?? json['destination']['position']?.longitude).toDouble()),
      status: RideStatus.values.byName(json['status']),
      driver: json['driver'] != null
          ? Driver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      userId: json['userId'],
      userName: json['userName'],
      id: json['id'],
    );
  }
  final CustomLocation origin;
  final CustomLocation destination;
  final RideStatus status;
  final Driver? driver;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String userName;
  final String id;

  Ride({
    required this.origin,
    required this.destination,
    required this.status,
    this.driver,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.userName,
    required this.id,
  });
}
