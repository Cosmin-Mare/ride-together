import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ride_together/login.dart';
import 'package:ride_together/models.dart';
import 'package:ride_together/request_ride_page.dart';
import 'package:ride_together/available_rides_page.dart';
import 'package:ride_together/ride_details_page.dart';
import 'package:ride_together/ride_history_page.dart';
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  Ride? rideRequested = null;
  Ride? rideAccepted = null;

  @override
  void initState() {
    super.initState();
    setRideRequested();
    setRideAccepted();
  }

  void setRideRequested(){
    print("Setting Ride Requested");
    FirebaseFirestore.instance.collection('rides').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).where('status', whereNotIn: ['completed', 'cancelled']).get().then((value) {
      setState(() {
        if(value.docs.isNotEmpty){
          rideRequested = Ride.fromJson({
            ...value.docs[0].data(),
            'id': value.docs[0].id,
          });
        } else {
          rideRequested = null;
        }
      });
    });
  }
  void setRideAccepted(){
    FirebaseFirestore.instance.collection('drivers').get().then((value) {
      for (var doc in value.docs) {
        print(doc.data());
      }
    });
    FirebaseFirestore.instance.collection('rides').where('driver.userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).where('status', whereNotIn: ['completed', 'cancelled']).get().then((value) {
      print("docs");
      print(value.docs);
      setState(() {
        if(value.docs.isNotEmpty){
          rideAccepted = Ride.fromJson({
            ...value.docs[0].data(),
            'id': value.docs[0].id,
          });
          print("Ride Accepted: $rideAccepted");  
        } else {
          rideAccepted = null;
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ride Together', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: () {
              GoogleSignIn.instance.signOut();
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
            }, icon: Icon(Icons.logout)),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_taxi), text: rideRequested != null ? "Ride Requested" : "Request Ride"),
              Tab(icon: Icon(Icons.people), text: rideAccepted != null ? "Accepted Ride" : "Friends Waiting"),
              Tab(icon: Icon(Icons.history), text: "Ride History"),
            ],
          ),
        ),
        // TabBarView works perfectly with AutomaticKeepAliveClientMixin
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            rideRequested != null ? RideDetailsPage(ride: rideRequested!, isDriver: false) : RequestRidePage(), 
            rideAccepted != null ? RideDetailsPage(ride: rideAccepted!, isDriver: true) : AvailableRidesPage(),
            RideHistoryPage(),
          ],
        ),
      ),
    );
  }
}