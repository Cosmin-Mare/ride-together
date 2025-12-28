import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ride_together/models.dart';
import 'package:ride_together/rides_list.dart';

class AvailableRidesPage extends StatefulWidget {
  const AvailableRidesPage({super.key});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  List<Ride> availableRides = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    getAvailableRides();
  }
  void getAvailableRides() {
    FirebaseFirestore.instance.collection('rides').where('status', isEqualTo: 'pending').get().then((value) {
      setState(() {
        availableRides = value.docs.map((doc) => 
          Ride.fromJson({
            ...doc.data(),
            'id': doc.id,
          })
        ).toList();

        isLoading = false;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? Center(child: CircularProgressIndicator()) : 
      RidesList(rides: availableRides),
    );
  }
}