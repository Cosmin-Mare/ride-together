import 'package:flutter/material.dart';
import 'package:ride_together/widgets/location_search_bar.dart';

class ConfirmRidePage extends StatefulWidget {
  const ConfirmRidePage({super.key, required this.location});
  final LocationSuggestion location;

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
      body: Column(
        children: [
          Text(widget.location.name),
          Text(widget.location.address),
        ],
      ),
    );
  }
}