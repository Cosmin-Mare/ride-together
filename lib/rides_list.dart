import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ride_together/models.dart';
import 'package:ride_together/ride_details_page.dart';
import 'package:ride_together/widgets/custom_button.dart';

class RidesList extends StatefulWidget {
  const RidesList({super.key, required this.rides});
  final List<Ride> rides;

  @override
  State<RidesList> createState() => _RidesListState();
}

class _RidesListState extends State<RidesList> {
  // Controller to handle the horizontal transitions
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print("Rides: ${widget.rides.map((ride) => ride.userName).toList()}");
  }

  void _acceptRide(Ride ride) async {
    final position = await Geolocator.getCurrentPosition();
    FirebaseFirestore.instance.collection('rides').doc(ride.id).update({
      'status': 'inProgress',
      'driver': {
        'name': FirebaseAuth.instance.currentUser?.displayName ?? '',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'profilePicture': FirebaseAuth.instance.currentUser?.photoURL,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return 
      Stack(
        children: [
          Scaffold(
            body: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal, // Swipes left and right like Tinder
              itemCount: widget.rides.length,
              itemBuilder: (context, index) {
                final ride = widget.rides[index];
                    return Container(
                    // Use the full screen dimensions
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    color: Colors.grey[50], // Light background for card feel
                    child: Stack(
                      children: [
                        // 1. MAIN CONTENT (Centered)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("${ride.userName} wants to go from:", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),),
                              const SizedBox(height: 30),
                              
                              // Ride Route
                              Text(
                                ride.origin.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              
                              // Addresses
                              Text(
                                ride.origin.address,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 10),
                              Icon(Icons.arrow_downward, size: 48, color: Colors.black),
                              const SizedBox(height: 10),
                              Text(
                                ride.destination.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(ride.destination.address, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]),),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: CustomButton(
                                  text: "Accept Ride",
                                  onPressed: () => _acceptRide(ride),
                                  fontSize: 26,
                                  icon: const Icon(Icons.arrow_forward, size: 40, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ),
                  );
              },
            ),
          ),
          Positioned(
              bottom: 40,
              right: 10,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    backgroundColor: Colors.black,
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ),
        Positioned(
            bottom: 40,
            left: 10,
            child: Column(
              children: [
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ],
            ),
          ), 
        ]
      );
  }
}