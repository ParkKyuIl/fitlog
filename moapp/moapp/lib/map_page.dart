import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Location _location = Location();

  LatLng _initialPosition =
      LatLng(37.77483, -122.41942); // Default to San Francisco
  bool _isMapCreated = false;
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    _currentLocation = await _location.getLocation();
    setState(() {
      _initialPosition =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _isMapCreated = true;
    _location.onLocationChanged.listen((locationData) {
      _currentLocation = locationData;
      if (_isMapCreated) {
        _controller!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locationData.latitude!, locationData.longitude!),
            zoom: 15.0,
          ),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Example'),
      ),
      body: _initialPosition.latitude != 37.77483 &&
              _initialPosition.longitude != -122.41942
          ? GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
