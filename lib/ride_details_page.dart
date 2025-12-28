import 'package:flutter/material.dart';
import 'package:ride_together/widgets/location_search_bar.dart';

enum RideStatus {
  pending,
  accepted,
  completed,
  cancelled,
}

class Driver {
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(name: json['name'], location: CustomLocation(name: json['location']['name'], address: json['location']['address'], latitude: json['location']['latitude'], longitude: json['location']['longitude']), profilePicture: json['profilePicture']);
  }
  final String name;
  final CustomLocation location;
  final String? profilePicture;

  Driver({required this.name, required this.location, this.profilePicture});
  
  toJson() {
    return {
      'name': name,
      'location': location.toJson(),
      'profilePicture': profilePicture,
    };
  }
}

class Ride {
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      origin: CustomLocation(name: json['origin']['name'], address: json['origin']['address'], latitude: json['origin']['position'].latitude, longitude: json['origin']['position'].longitude),
      destination: CustomLocation(name: json['destination']['name'], address: json['destination']['address'], latitude: json['destination']['position'].latitude, longitude: json['destination']['position'].longitude),
      status: RideStatus.values.byName(json['status']),
      driver: json['driver'] != null ? Driver.fromJson(json['driver'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'].toDate(),
      updatedAt: json['updatedAt'].toDate(),
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
  Ride({required this.origin, required this.destination, required this.status, this.driver, required this.createdAt, required this.updatedAt, required this.userId, required this.userName, required this.id});

  toJson() {
    return {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'status': status.name,
      'driver': driver?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'userName': userName,
      'id': id,
    };
  }
}

class RideDetailsPage extends StatefulWidget {
  const RideDetailsPage({super.key, required this.ride});
  final Ride ride;

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${widget.ride.origin.name}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              Text('${widget.ride.origin.address}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal), textAlign: TextAlign.center,),
              Icon(Icons.arrow_downward, size: 48, color: Colors.black),
              Text('${widget.ride.destination.name}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              Text('${widget.ride.destination.address}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal), textAlign: TextAlign.center,),
              SizedBox(height: 20),
              Text('Ride ${widget.ride.status.name}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.normal), textAlign: TextAlign.center,),
              SizedBox(height: 20),
              Text('${widget.ride.driver != null ? '${widget.ride.driver?.name} will pick you up' : 'Nobody has accepted the ride yet'}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.normal), textAlign: TextAlign.center,),
            ],
          ),
        )
    );
  }
}