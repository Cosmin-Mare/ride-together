import 'package:flutter/material.dart';
import 'package:ride_together/models.dart';

class RidesHistoryList extends StatelessWidget {
  const RidesHistoryList({super.key, required this.rides, required this.title});
  final List<Ride> rides;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: rides.isEmpty ? Center(child: Text('No rides found')) : ListView.builder(
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: Column(
                children: [
                  if(title != 'Rides Requested')
                    Text(ride.userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("From:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(ride.origin.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text(ride.origin.address, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text("To:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(ride.destination.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text(ride.destination.address, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ride.status == RideStatus.completed ? const Color.fromARGB(255, 0, 119, 4) : const Color.fromARGB(255, 255, 51, 37),
                      border: Border.all(color: Colors.black, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(ride.status.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}