import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ride_together/home.dart';
import 'package:ride_together/models.dart';

class BottomPanel extends StatelessWidget {
  const BottomPanel({super.key, required this.ride, required this.isDriver});
  final bool isDriver;
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30), 
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 20, 
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300], 
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked, color: Colors.black, size: 24),
                  Container(width: 2, height: 25, color: Colors.black),
                  const Icon(Icons.place, color: Colors.black, size: 24),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isDriver ? "Your Location" : ride.origin.name, 
                        style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                    const SizedBox(height: 30),
                    Text(isDriver ? ride.origin.name : ride.destination.name, 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ride.status == RideStatus.pending ? Colors.black : Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ride.status.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: ride.driver != null 
                ? Container(
                    key: const ValueKey('driver_active'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: isDriver ? ride.profilePicture != null ? NetworkImage(ride.profilePicture!) : null : ride.driver?.profilePicture != null 
                              ? NetworkImage(ride.driver!.profilePicture!) 
                              : null,
                          child: isDriver ? ride.profilePicture == null ? const Icon(Icons.person) : null : ride.driver?.profilePicture == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isDriver ? ride.userName : ride.driver?.name ?? '', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(isDriver ? "${ride.userName} is waiting for you" : "Your driver is arriving", 
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ) 
                : Container(
                    key: const ValueKey('searching'),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50], 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 20),
                        Text("Finding your driver...", 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 25),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              FirebaseFirestore.instance.collection('rides').doc(ride.id).update({
                'status': RideStatus.cancelled.name,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ride Cancelled Successfully!')),
              );
            },
            child: Text("Cancel Ride", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}