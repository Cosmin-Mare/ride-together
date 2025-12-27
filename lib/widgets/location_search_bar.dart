import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:ride_together/confirm_ride_page.dart';

class LocationSuggestion {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? mapboxId;
  
  LocationSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.mapboxId,
  });
}

class LocationSearchBar extends StatefulWidget {
  const LocationSearchBar({
    super.key, 
    required this.controller, 
    this.currentPosition, 
    required this.onLocationSelected, 
    required this.focusNode,
    this.selectedLocation,
    this.onRequestRide,
  });
  
  final TextEditingController controller;
  final geolocator.Position? currentPosition;
  final Function(LocationSuggestion) onLocationSelected;
  final FocusNode focusNode;
  final LocationSuggestion? selectedLocation;
  final VoidCallback? onRequestRide;
  
  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> with SingleTickerProviderStateMixin {
  List<LocationSuggestion> searchSuggestions = [];
  Timer? _debounce;
  final searchAPI = SearchBoxAPI(limit: 3);
  bool _ignoreNextChange = false;
  String _lastSelectedText = '';
  LocationSuggestion? _lastSelectedLocation;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    widget.controller.addListener(() {
      _onSearchChanged(widget.controller.text);
    });
    
    widget.focusNode.addListener(() {
      if (!widget.focusNode.hasFocus) {
        if (_lastSelectedLocation != null && widget.controller.text != _lastSelectedText) {
          _revertToLastSelected();
        } else {
          setState(() {
            searchSuggestions = [];
          });
          _animationController.reverse();
        }
      }
    });
  }

  void _updateSuggestions(String query) async {
    print("Getting suggestions for $query");
    if (query.length < 3) {
      if (mounted) {
        setState(() {
          searchSuggestions = [];
          _isLoading = false;
        });
        _animationController.reverse();
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await searchAPI.getSuggestions(
        query,
        proximity: Proximity.LatLong(
          lat: widget.currentPosition?.latitude ?? 0, 
          long: widget.currentPosition?.longitude ?? 0
        ),
      );

      if (!mounted) return;

      if (result.success != null) {
        final suggestions = result.success!.suggestions;
        
        setState(() {
          searchSuggestions = suggestions.map((s) {
            return LocationSuggestion(
              name: s.name,
              address: s.fullAddress ?? '',
              latitude: 0.0,
              longitude: 0.0,
              mapboxId: s.mapboxId,
            );
          }).toList();
          _isLoading = false;
        });
        
        if (searchSuggestions.isNotEmpty) {
          _animationController.forward();
        }
      } else {
        print(result.failure);
        setState(() {
          searchSuggestions = [];
          _isLoading = false;
        });
        _animationController.reverse();
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          searchSuggestions = [];
          _isLoading = false;
        });
        _animationController.reverse();
      }
    }
  }

  Future<LocationSuggestion?> _retrieveLocationDetails(LocationSuggestion suggestion) async {
    if (suggestion.mapboxId == null) return null;
    
    try {
      final result = await searchAPI.getPlace(suggestion.mapboxId!);
      
      if (result.success != null && result.success!.features.isNotEmpty) {
        final feature = result.success!.features.first;
        final coords = feature.geometry?.coordinates;
        
        if (coords != null) {
          return LocationSuggestion(
            name: suggestion.name,
            address: suggestion.address,
            longitude: coords.long ?? 0.0,
            latitude: coords.lat ?? 0.0,
            mapboxId: suggestion.mapboxId,
          );
        }
      }
    } catch (e) {
      print('Error retrieving location details: $e');
    }
    return null;
  }

  Future<void> _selectLocation(LocationSuggestion suggestion) async {
    _ignoreNextChange = true;
    
    setState(() {
      searchSuggestions = [];
      _isLoading = true;
    });
    _animationController.reverse();
    
    final fullLocation = await _retrieveLocationDetails(suggestion);
    
    if (fullLocation != null) {
      _lastSelectedLocation = fullLocation;
      _lastSelectedText = fullLocation.name;
      
      widget.onLocationSelected(fullLocation);
      
      Future.delayed(Duration(milliseconds: 100), () {
        _ignoreNextChange = false;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      print('Could not retrieve location coordinates');
      _ignoreNextChange = false;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_ignoreNextChange) {
      _ignoreNextChange = false;
      return;
    }
    
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _updateSuggestions(query);
      }
    });
  }

  void _revertToLastSelected() {
    _ignoreNextChange = true;
    setState(() {
      searchSuggestions = [];
    });
    _animationController.reverse();
    
    if (_lastSelectedLocation != null) {
      widget.controller.text = _lastSelectedText;
    }
    
    Future.delayed(Duration(milliseconds: 100), () {
      _ignoreNextChange = false;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(() {
      _onSearchChanged(widget.controller.text);
    });
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showRequestButton = widget.selectedLocation != null && !widget.focusNode.hasFocus;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: widget.focusNode,
                textAlignVertical: TextAlignVertical.center,
                controller: widget.controller,
                cursorColor: Colors.black,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (searchSuggestions.isNotEmpty) {
                    _selectLocation(searchSuggestions[0]);
                  }
                  widget.focusNode.unfocus();
                },
                decoration: InputDecoration(
                  prefixIcon: _isLoading 
                    ? Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : Icon(Icons.location_on, color: Colors.grey.shade800),
                  hintText: 'Where to?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade800, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black, width: 4),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: showRequestButton ? 140 : 0,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: showRequestButton ? 1.0 : 0.0,
                child: showRequestButton
                  ? Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                        onPressed: widget.onRequestRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Request Ride',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              ),
            ),
          ],
        ),
        if (searchSuggestions.isNotEmpty)
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchSuggestions.length,
                    itemBuilder: (context, index) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final suggestion = searchSuggestions[index];
                            widget.focusNode.unfocus();
                            await _selectLocation(suggestion);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            leading: Icon(Icons.location_on, color: Colors.grey.shade700),
                            title: Text(
                              searchSuggestions[index].name,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              searchSuggestions[index].address,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}