import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_together/confirm_ride_page.dart';
import 'package:ride_together/models.dart';
import 'package:ride_together/utils.dart';
import 'package:ride_together/widgets/location_search_bar.dart';

class RequestRidePage extends StatefulWidget {
  const RequestRidePage({super.key});

  @override
  State<RequestRidePage> createState() => _RequestRidePageState();
}

// Added AutomaticKeepAliveClientMixin here
class _RequestRidePageState extends State<RequestRidePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // This keeps the state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  MapboxMap? mapboxMap;
  final TextEditingController locationController = TextEditingController();
  final FocusNode locationFocusNode = FocusNode();

  CustomLocation? selectedLocation;
  CustomLocation? originLocation;
  geolocator.Position? currentPosition;

  bool selectedLocationViaPin = false;
  bool _isProgrammaticMove = false;
  bool isMapReady = false;
  Timer? _debounceTimer;
  bool locationLoading = false;

  @override
  void initState() {
    super.initState();
    locationFocusNode.addListener(() {
      setState(() {});
    });
    _initLocation();
  }

  void setSelectedLocationViaPin(bool value) {
    setState(() {
      selectedLocationViaPin = value;
    });
  }

  Future<void> _initLocation() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      final position = await getCurrentPosition();
      if (position != null) {
        setState(() {
          currentPosition = position;
        });
        _getOriginLocation();

        if (mapboxMap != null) {
          _isProgrammaticMove = true;
          mapboxMap!.setCamera(
            CameraOptions(
              center: Point(
                  coordinates: Position(position.longitude, position.latitude)),
              zoom: 15,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            _isProgrammaticMove = false;
          });
        }
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    setState(() => isMapReady = true);
  }

  void _onCameraChanged(CameraChangedEventData event) {
    if (_isProgrammaticMove ||
        locationFocusNode.hasFocus ||
        selectedLocation == null) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    setState(() {
      locationLoading = true;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (mapboxMap == null || _isProgrammaticMove || locationFocusNode.hasFocus)
        return;

      final cameraState = await mapboxMap!.getCameraState();
      final lng = cameraState.center.coordinates.lng.toDouble();
      final lat = cameraState.center.coordinates.lat.toDouble();

      _reverseGeocode(lng, lat);
    });
  }
  Future<void> _reverseGeocode(double lng, double lat) async {
    const googleApiKey = String.fromEnvironment('GOOGLE_API_KEY'); // or store securely
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey');
    try {
      setState(() => locationLoading = true);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        print(results);

        if (results.isNotEmpty) {
          final firstResult = results.first;
          final formattedAddress = firstResult['formatted_address'] as String? ?? "";
          final placeName = firstResult['address_components']?[0]?['long_name'] ?? "Dropped Pin";

          setState(() {
            locationLoading = false;
            selectedLocation = CustomLocation(
              name: placeName,
              address: formattedAddress,
              longitude: lng,
              latitude: lat,
            );
            selectedLocationViaPin = true;
            locationController.text = "Selected Via Pin";
          });
        } else {
          setState(() => locationLoading = false);
        }
      } else {
        debugPrint('Geocoding API error: ${response.statusCode}');
        setState(() => locationLoading = false);
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
      setState(() => locationLoading = false);
    }
  }


  void _onLocationSelected(CustomLocation location) {
    _debounceTimer?.cancel();
    locationFocusNode.unfocus();

    setState(() {
      selectedLocation = location;
      locationController.text = location.name;
      selectedLocationViaPin = false;
      _isProgrammaticMove = true;
    });

    mapboxMap?.flyTo(
      CameraOptions(
        center:
            Point(coordinates: Position(location.longitude, location.latitude)),
        zoom: 15,
      ),
      MapAnimationOptions(duration: 1000),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _isProgrammaticMove = false);
      }
    });
  }

  Future<void> _getOriginLocation() async {
    if (currentPosition == null) return;

    const googleApiKey = String.fromEnvironment('GOOGLE_API_KEY'); // or inject securely
    final lat = currentPosition!.latitude;
    final lng = currentPosition!.longitude;
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        print(results);
        if (results.isNotEmpty) {
          final firstResult = results.first;
          final formattedAddress = firstResult['formatted_address'] as String? ?? "";
          final placeName = firstResult['address_components']?[0]?['long_name'] ?? 'Current Location';

          originLocation = CustomLocation(
            name: placeName,
            address: formattedAddress,
            longitude: lng,
            latitude: lat,
          );
        }
      } else {
        debugPrint('Geocoding API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error getting origin: $e");
    }
  }
  void _onRequestRide() {
    if (selectedLocation != null && originLocation != null && !locationLoading) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmRidePage(
            destination: selectedLocation!,
            origin: originLocation!,
            isLocationViaPin: selectedLocationViaPin,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    locationFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Required by AutomaticKeepAliveClientMixin
    super.build(context);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Stack(
      children: [
        MapWidget(
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(0, 0)),
            zoom: 2,
          ),
          onMapCreated: _onMapCreated,
          onCameraChangeListener: _onCameraChanged,
        ),
        if (selectedLocation != null)
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 35 + (bottomInset / 2)),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.location_on, size: 45, color: Colors.white),
                    Icon(Icons.location_on_outlined,
                        size: 45, color: Colors.black),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: bottomInset,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: LocationSearchBar(
                selectedLocationViaPin: selectedLocationViaPin,
                setSelectedLocationViaPin: setSelectedLocationViaPin,
                controller: locationController,
                currentPosition: currentPosition,
                onLocationSelected: _onLocationSelected,
                focusNode: locationFocusNode,
                selectedLocation: selectedLocation,
                onRequestRide: _onRequestRide,
                locationLoading: locationLoading,
              ),
            ),
          ),
        ),
      ],
    );
  }
}