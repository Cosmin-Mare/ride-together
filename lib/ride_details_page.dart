import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_together/bottom_panel.dart';
import 'package:ride_together/home.dart';
import 'package:ride_together/models.dart';
import 'package:ride_together/utils.dart';

class RideDetailsPage extends StatefulWidget {
  const RideDetailsPage({super.key, required this.ride, required this.isDriver});
  final Ride ride;
  final bool isDriver;

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  MapboxMap? mapboxMap;
  CircleAnnotationManager? circleAnnotationManager;
  CircleAnnotation? originMarker;
  PointAnnotationManager? pointAnnotationManager;
  PointAnnotation? driverMarker;
  PointAnnotationManager? destinationPointAnnotationManager;
  PointAnnotation? destinationMarker;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _rideStream;
  
  bool _initialCameraSet = false;

  @override
  void initState() {
    super.initState();
    _rideStream = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.ride.id)
        .snapshots();
    _listenToRideStatus(widget.ride);
  }

  Future<void> getRoute(Position from, Position to) async {
    const accessToken = String.fromEnvironment('ACCESS_TOKEN');
    final response = await http.get(Uri.parse('https://api.mapbox.com/directions/v5/mapbox/driving/${from.lng},${from.lat};${to.lng},${to.lat}?geometries=geojson&overview=full&access_token=$accessToken'));
    print("route");
    final geometry = json.decode(response.body)['routes'][0]['geometry'];

    final geoJson = {
      "type": "Feature",
      "geometry": geometry,
      "properties": {},
    };
    print(geoJson);

    await mapboxMap!.style.addSource(
      GeoJsonSource(
        id: 'route-source',
        data: jsonEncode(geoJson),
        lineMetrics: true
      ),
    );
    print((await mapboxMap!.style.getStyleSourceProperty('route-source', 'data')).value);
    await _addRouteLine();
  }

  Future<void> _addRouteLine() async {
    await mapboxMap!.style.addLayer(
    LineLayer(
      id: 'route-layer',
      sourceId: 'route-source',
      lineColor: Colors.black.value,
      lineWidth: 5.0,
      lineDasharray: [1.0, 2.0],
      lineCap: LineCap.ROUND,
    ),
  );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    destinationPointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    mapboxMap.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true));
    
    // Initial view focusing on the origin
    if (!_initialCameraSet) {
      mapboxMap.setCamera(CameraOptions(
        center: Point(coordinates: Position(widget.ride.origin.longitude, widget.ride.origin.latitude)),
        zoom: 14,
      ));
      _initialCameraSet = true;
    }
  }
  /// Calculates the view to fit both driver and origin, then animates there
  void _updateMarkersAndBounds(Driver? driver, CustomLocation origin, CustomLocation destination) async {
    if (circleAnnotationManager == null || mapboxMap == null) return;

    final originPos = Point(coordinates: Position(origin.longitude, origin.latitude));
    final destinationPos = Point(coordinates: Position(destination.longitude, destination.latitude));
    // 1. Manage Origin (Pickup) Marker
    originMarker ??= await circleAnnotationManager!.create(CircleAnnotationOptions(
      geometry: originPos, circleRadius: 10,
      circleColor: Colors.white.value,
      circleStrokeColor: Colors.black.value,
      circleStrokeWidth: 2,
    ));

    Uint8List iconBytes = await createFlutterIcon(
      icon: Icons.location_on,
      color: Colors.black,
      size: 100,
    );

    // 2. Manage Destination Marker
    destinationMarker ??= await destinationPointAnnotationManager!.create(PointAnnotationOptions(
      geometry: destinationPos,
      image: iconBytes,
    ));

    // 2. Manage Driver Marker
    if (driver != null) {
      final driverPos = Point(coordinates: Position(driver.longitude, driver.latitude));
      
      if (driverMarker == null) {
        Uint8List iconBytes = await createFlutterIcon(
          icon: Icons.directions_car,
          color: Colors.black,
          size: 50,
        );

        driverMarker = await pointAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: driverPos,
            image: iconBytes,
            iconSize: 1.5,
          ),
        );
      } else {
        driverMarker!.geometry = driverPos;
        pointAnnotationManager!.update(driverMarker!);
      }

      // 3. Adjust Camera to fit both markers
      final lineString = LineString(coordinates: [
        driverPos.coordinates,
        originPos.coordinates,
        destinationPos.coordinates,
      ]);
      print("getting route");
      await getRoute(driverPos.coordinates, originPos.coordinates);

      // FIX: Call .toJson() to pass a Map instead of the LineString object
      final cameraOptions = await mapboxMap!.cameraForGeometry(
        lineString.toJson(), 
        MbxEdgeInsets(
          top: 80,    
          left: 60,   
          bottom: 350, // Higher bottom padding for the UI panel
          right: 60,  
        ),
        null, 
        null,
      );

      mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
    }
  }

  void _checkRideStatus(Ride ride) {
    if(ride.status == RideStatus.cancelled) {
      print("Ride Cancelled");
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride Cancelled')),
        );
      });

    }
  }
  
  void _listenToRideStatus(Ride ride) {
    _rideStream.listen((snapshot) {
      if(snapshot.exists) {
        Map<String, dynamic> data = snapshot.data()!;
        data['id'] = snapshot.id;
        _checkRideStatus(Ride.fromJson(data));
      }
    });
  }
  @override
  void dispose() {
    _rideStream.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _rideStream,
        builder: (context, snapshot) {
          Ride currentRide = widget.ride;

          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic> data = snapshot.data!.data()!;
            data['id'] = snapshot.data!.id;

            try {
              currentRide = Ride.fromJson(data);
              // Run the update logic whenever Firestore data changes
              _updateMarkersAndBounds(currentRide.driver, currentRide.origin, currentRide.destination);
            } catch (e) {
              debugPrint("Error updating map: $e");
            }
          }

          return Stack(
            children: [
              MapWidget(
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(currentRide.origin.longitude, currentRide.origin.latitude)),
                  zoom: 14,
                ),
                onMapCreated: _onMapCreated,
              ),
              
              // Bottom UI Panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 100 * value),
                      child: Opacity(
                        opacity: (1 - value).clamp(0, 1),
                        child: BottomPanel(ride: currentRide, isDriver: widget.isDriver),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}