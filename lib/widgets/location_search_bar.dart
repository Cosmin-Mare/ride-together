import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'package:ride_together/models.dart';
import 'package:ride_together/ride_details_page.dart';

class LocationSearchBar extends StatefulWidget {
  const LocationSearchBar({
    super.key, 
    required this.controller, 
    this.currentPosition, 
    required this.onLocationSelected, 
    required this.focusNode,
    this.selectedLocation,
    this.onRequestRide,
    this.selectedLocationViaPin = false,
    required this.setSelectedLocationViaPin,
    required this.locationLoading,
  });
  
  final TextEditingController controller;
  final geolocator.Position? currentPosition;
  final Function(CustomLocation) onLocationSelected;
  final FocusNode focusNode;
  final CustomLocation? selectedLocation;
  final VoidCallback? onRequestRide;
  final bool selectedLocationViaPin;
  final Function(bool) setSelectedLocationViaPin;
  final bool locationLoading;
  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> with SingleTickerProviderStateMixin {
  List<String> searchSuggestions = [];
  List<String> placeIds = [];
  Timer? _debounce;
  bool _ignoreNextChange = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late String sessionToken;

  @override
  void initState() {
    super.initState();
    sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
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
      if(!widget.selectedLocationViaPin) {
        _onSearchChanged(widget.controller.text);
      }
    });
    
    widget.focusNode.addListener(() {
      if(widget.focusNode.hasFocus) {
        if(widget.selectedLocationViaPin) {
          widget.setSelectedLocationViaPin(false);
          widget.controller.text = "";
        }
      }
      if (!widget.focusNode.hasFocus) {
        setState(() {
          searchSuggestions = [];
        });
        _animationController.reverse();
      }
    });
  }


  void _updateSuggestions(String query) async {
    if(widget.selectedLocationViaPin) {
      return;
    }
    print(widget.selectedLocationViaPin);
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
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&key=${const String.fromEnvironment('GOOGLE_API_KEY')}'
        '&sessiontoken=$sessionToken'
        '&location=${widget.currentPosition?.latitude},${widget.currentPosition?.longitude}'
        '&radius=5000'
      );
      print(sessionToken);
      final result = await http.get(uri);
      if (!mounted) return;

      if (result.statusCode == 200) {
        final suggestions = json.decode(result.body)['predictions'];
        
        setState(() {
          searchSuggestions = suggestions.map<String>((s) {
            return s['description'] as String? ?? '';
          }).toList() as List<String>;

          placeIds = suggestions.map<String>((s) {
            return s['place_id'] as String? ?? '';
          }).toList() as List<String>;
          _isLoading = false;
        });
        
        if (searchSuggestions.isNotEmpty) {
          _animationController.forward();
        }
      } else {
        print("Error getting suggestions");
        print(result.statusCode);
        print(result.body);
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

  Future<void> _selectLocation(String placeId) async {
    _ignoreNextChange = true;
    
    setState(() {
      searchSuggestions = [];
      _isLoading = true;
    });
    _animationController.reverse();

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=geometry,name,formatted_address'
      '&key=${const String.fromEnvironment('GOOGLE_API_KEY')}',
    );
    final result = await http.get(uri);
    final data = json.decode(result.body);
    
    final location = CustomLocation(name: data['result']['name'], address: data['result']['formatted_address'], latitude: data['result']['geometry']['location']['lat'], longitude: data['result']['geometry']['location']['lng']);

    widget.onLocationSelected(location);
    _ignoreNextChange = false;
    setState(() {
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    if(widget.selectedLocationViaPin) {
      return;
    }
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
                cursorColor: widget.selectedLocationViaPin ? Colors.white : Colors.black,
                style: TextStyle(color: widget.selectedLocationViaPin ? Colors.white : Colors.black),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (searchSuggestions.isNotEmpty) {
                    _selectLocation(placeIds[0]);
                  }
                  widget.focusNode.unfocus();
                },
                decoration: InputDecoration(
                  fillColor: widget.selectedLocationViaPin ? Colors.black : Colors.white,
                  filled: true,
                  prefixIcon: _isLoading || widget.locationLoading
                    ? Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.selectedLocationViaPin ? Colors.white : Colors.black,
                          ),
                        ),
                      )
                    : Icon(widget.selectedLocationViaPin ? Icons.location_on_outlined : Icons.location_on, color: widget.selectedLocationViaPin ? Colors.white : Colors.grey.shade800),
                  hintText: 'Where to?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.selectedLocationViaPin ? Colors.white : Colors.grey.shade300, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.selectedLocationViaPin ? Colors.white : Colors.grey.shade800, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.selectedLocationViaPin ? Colors.white : Colors.black, width: 4),
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
                          backgroundColor: widget.locationLoading || _isLoading ? Colors.grey.shade300 : Colors.black,
                          foregroundColor: widget.locationLoading || _isLoading ? Colors.grey.shade800 : Colors.white,
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
                            widget.focusNode.unfocus();
                            await _selectLocation(placeIds[index]);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            leading: Icon(Icons.location_on, color: Colors.grey.shade700),
                            title: Text(
                              searchSuggestions[index],
                              style: TextStyle(fontWeight: FontWeight.w600),
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