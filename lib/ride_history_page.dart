import 'package:flutter/material.dart';
import 'package:ride_together/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ride_together/rides_history_list.dart';
class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<Ride> ridesRequested = [];
  List<Ride> ridesAccepted = [];
  final PageController _pageController = PageController();
  @override
  void initState() {
    super.initState();
    getRidesRequested();
    getRidesAccepted();
  }
  void getRidesRequested() {
    FirebaseFirestore.instance.collection('rides').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).get().then((value) {
      setState(() {
        ridesRequested = value.docs.map((doc) => Ride.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList();
      });
    });
  }

  void getRidesAccepted() {
    print(FirebaseAuth.instance.currentUser?.uid);
    FirebaseFirestore.instance.collection('rides').where('driver.userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).get().then((value) {
      setState(() {
        ridesAccepted = value.docs.map((doc) => Ride.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
      Stack(
        children: [
          PageView(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            children: [
              RidesHistoryList(rides: ridesRequested, title: 'Rides Requested'),
              RidesHistoryList(rides: ridesAccepted, title: 'Rides Accepted'),
            ],
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: IconButton(onPressed: () {
                    _pageController.previousPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
                  }, icon: Icon(Icons.arrow_back, size: 40, color: Colors.black)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.black, width: 4),
                  ),  
                  padding: const EdgeInsets.all(16),
                  child: IconButton(onPressed: () {
                      _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }, icon: Icon(Icons.arrow_forward, size: 40, color: Colors.black)),
                  ),
              ],
            ),
          )
        ],
      ),
      
    );
  }
}