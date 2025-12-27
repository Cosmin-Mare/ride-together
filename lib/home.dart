import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_together/confirm_ride_page.dart';
import 'package:ride_together/widgets/location_search_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  MapboxMap? mapboxMap;
  final TextEditingController locationController = TextEditingController();
  final FocusNode locationFocusNode = FocusNode();
  LocationSuggestion? selectedLocation;
  geolocator.Position? currentPosition;
  CircleAnnotationManager? circleAnnotationManager;
  CircleAnnotation? destinationMarker;
  bool isMapReady = false;
  late AnimationController _markerAnimationController;
  late Animation<double> _markerScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    
    _markerScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _markerAnimationController, 
        curve: Curves.elasticOut,
      ),
    );
    
    locationFocusNode.addListener(() {
      setState(() {});
    });
    
    print('Requesting location permission');
    Permission.locationWhenInUse.request().then((value) async {
      if(value.isGranted){
        final position = await _getCurrentPosition();
        if(position != null){
          print('Position: ${position.longitude}, ${position.latitude}');
          setState(() {
            currentPosition = position;
          });
          
          if (mapboxMap != null && isMapReady) {
            mapboxMap!.setCamera(
              CameraOptions(
                center: Point(
                  coordinates: Position(position.longitude, position.latitude),
                ),
                zoom: 15,
              ),
            );
            mapboxMap!.location.updateSettings(
              LocationComponentSettings(
                enabled: true,
                pulsingEnabled: true,
              ),
            );
          }
          setState(() {});
        }
      } else {
        print('Location permission denied');
      }
    });
  }

  Future<geolocator.Position?> _getCurrentPosition() async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) return null;
    }
    if (permission == geolocator.LocationPermission.deniedForever) return null;

    geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
      ),
    );

    return position;
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    print('Map created');
    this.mapboxMap = mapboxMap;

    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(
      enabled: false
    ));

    try {
      circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
      print('CircleAnnotationManager created successfully');
      setState(() {
        isMapReady = true;
      });
    } catch (e) {
      print('Error creating CircleAnnotationManager: $e');
    }
  }

  Future<void> _addDestinationMarker(double longitude, double latitude) async {
    print('Attempting to add marker at: $longitude, $latitude');
    print('CircleAnnotationManager is null: ${circleAnnotationManager == null}');
    print('isMapReady: $isMapReady');
    
    if (circleAnnotationManager == null) {
      print('CircleAnnotationManager is not ready yet, waiting...');
      await Future.delayed(Duration(milliseconds: 500));
      if (circleAnnotationManager == null) {
        print('CircleAnnotationManager still not ready');
        return;
      }
    }

    try {
      // Remove existing marker if any
      if (destinationMarker != null) {
        print('Removing existing marker');
        await circleAnnotationManager!.delete(destinationMarker!);
      }

      // Animate camera to the selected location first
      if (mapboxMap != null) {
        await mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(longitude, latitude),
            ),
            zoom: 15,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }

      // Reset and start marker animation
      _markerAnimationController.reset();
      _markerAnimationController.forward();

      print('Creating new circle marker...');
      // Create the outermost black stroke
      await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(longitude, latitude),
          ),
          circleRadius: 15.0,
          circleColor: Colors.black.value,
        ),
      );

      // Create the middle white stroke
      await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(longitude, latitude),
          ),
          circleRadius: 12.0,
          circleColor: Colors.white.value,
        ),
      );

      // Create the innermost black center
      destinationMarker = await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(longitude, latitude),
          ),
          circleRadius: 9.0,
          circleColor: Colors.black.value,
        ),
      );
      print('Destination marker added successfully: ${longitude}, ${latitude}');
    } catch (e) {
      print('Error adding marker: $e');
    }
  }

  void _onLocationSelected(LocationSuggestion location) {
    print('Location selected: ${location.name} at ${location.longitude}, ${location.latitude}');
    setState(() {
      selectedLocation = location;
      locationController.text = location.name;
    });

    _addDestinationMarker(location.longitude, location.latitude);
  }

  void _onRequestRide() {
    if (selectedLocation != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            ConfirmRidePage(location: selectedLocation!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    locationFocusNode.dispose();
    _markerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(0, 0),
              ),
              zoom: 2,
              bearing: 0,
              pitch: 0,
            ),
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: locationFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ]
                  : [],
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: LocationSearchBar(
                  controller: locationController,
                  currentPosition: currentPosition,
                  onLocationSelected: _onLocationSelected,
                  focusNode: locationFocusNode,
                  selectedLocation: selectedLocation,
                  onRequestRide: _onRequestRide,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}