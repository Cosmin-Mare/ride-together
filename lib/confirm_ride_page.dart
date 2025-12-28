import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_together/home.dart';
import 'package:ride_together/models.dart';
import 'package:ride_together/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmRidePage extends StatefulWidget {
  const ConfirmRidePage({super.key, required this.destination, required this.origin, this.isLocationViaPin = false, this.isOriginCurrentLocation = true});
  final CustomLocation destination;
  final CustomLocation origin;
  final bool isLocationViaPin;
  final bool isOriginCurrentLocation;

  @override
  State<ConfirmRidePage> createState() => _ConfirmRidePageState();
}

class _ConfirmRidePageState extends State<ConfirmRidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Ride'),

      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if(widget.isOriginCurrentLocation)
                    Text('Current Location', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  Text(widget.origin.name, style: TextStyle(fontSize: widget.isOriginCurrentLocation ? 24 : 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2,),
                  Text(widget.origin.address, style: TextStyle(fontSize: widget.isOriginCurrentLocation ? 20 : 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2,),
                ],
              ),
            ),
            SizedBox(height: 20),
            Icon(Icons.arrow_downward, size: 48, color: Colors.black),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if(widget.isLocationViaPin)
                    Text('Selected Via Pin', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  Text(widget.destination.name, style: TextStyle(fontSize: widget.isLocationViaPin ? 24 : 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  Text(widget.destination.address, style: TextStyle(fontSize: widget.isLocationViaPin ? 20 : 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                ],
              ),
            ),
            SizedBox(height: 60),
            CustomButton(text: 'Confirm Ride', onPressed: () {
              _handleConfirmRide();
            }, size: Size(40, 30), fontSize: 40, icon: Icon(Icons.arrow_forward, size: 40, color: Colors.white)),
          ]
        ),
      ),
    );
  }

  void _handleConfirmRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book a ride.')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create the data object with Latitude and Longitude
      final rideData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? '',
        'origin': {
          'name': widget.origin.name,
          'address': widget.origin.address,
          // Using GeoPoint for Firestore native location support
          'position': GeoPoint(widget.origin.latitude, widget.origin.longitude), 
          'isCurrentLocation': widget.isOriginCurrentLocation,
        },
        'destination': {
          'name': widget.destination.name,
          'address': widget.destination.address,
          // Using GeoPoint for Firestore native location support
          'position': GeoPoint(widget.destination.latitude, widget.destination.longitude),
          'isViaPin': widget.isLocationViaPin,
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profilePicture': user.photoURL,
      };

      await FirebaseFirestore.instance.collection('rides').add(rideData);

      if (!mounted) return; // Check if widget is still in tree
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride Confirmed Successfully!')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm ride: $e')),
      );
    }
  }
}