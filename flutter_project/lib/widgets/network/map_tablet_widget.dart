import 'package:dima_project/api_keys.dart';
import 'package:dima_project/classes/position_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MapTabletWidget extends StatefulWidget {
  final PositionModel? userPosition;
  final String? username;
  const MapTabletWidget({super.key, this.userPosition, this.username});
  
  @override
  State<MapTabletWidget> createState() => MapTabletState(); 
}

class MapTabletState extends State<MapTabletWidget> {
  LatLng? userPoint;
  PositionModel? userCurrentPosition;
  String? userCurrentAddress;

  LatLng? myPoint;
  Position? myCurrentPosition;
  String? myCurrentAddress;

  String? info;
  Icon? iconInfo;

  List<LatLng>? polylineCoordinates = [];
  List<Marker> markers = [];
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _setMyCurrentPosition(); // set my position when the widget is created
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    debugPrint('BUILD TABLET MAP');

    if (widget.userPosition != null) {
      if (userCurrentPosition == null || 
          // if userPosition has changed, set the new position
          userCurrentPosition!.latitude != widget.userPosition!.latitude || 
          userCurrentPosition!.longitude != widget.userPosition!.longitude) {
        _setUserPosition();
        userCurrentPosition = widget.userPosition;
        //debugPrint('CHANGE USER POSITION');
      }
    }


    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: LatLng(45.4640963, 9.1713256), // Milan
            zoom: 15.0,
            maxZoom: 18.0,
            minZoom: 5.0,
            //keepAlive: true,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: markers),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylineCoordinates ?? [],
                  color: Colors.green,
                  strokeWidth: 3.0,
                ),
              ],
            ),
          ],
        ),

        Positioned(
          right: 10,
          top: 150,
          child: Container(
            height: 380.0,
            width: 60.0,
            decoration: BoxDecoration(
              color: Colors.grey[600]!.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: widget.userPosition != null ? 
                    Icon(Icons.refresh_rounded, color: Colors.amber) 
                  : Icon(Icons.refresh_rounded),
                  onPressed: () async {
                    if (widget.userPosition != null) {
                      if (myCurrentPosition != null) {
                        _setMyCurrentPosition();
                      } 
                      setState(() {
                        polylineCoordinates = []; // remove previous route
                        mapController.move(userPoint!, 15.0);
                        info = userCurrentAddress;
                        iconInfo = Icon(Icons.location_on, color: Colors.red, size: 40.0);
                      });
                    } else {
                      null;
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.zoom_in, color: Colors.amber),
                  onPressed: () {
                    setState(() {
                      mapController.move(mapController.center, mapController.zoom + 1);
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.zoom_out, color: Colors.amber),
                  onPressed: () {
                    setState(() {
                      mapController.move(mapController.center, mapController.zoom - 1);
                    });
                  },
                ),
                IconButton(
                  icon: myCurrentPosition != null && widget.userPosition != null ? 
                    Icon(Icons.directions_car_rounded, color: Colors.amber) 
                  : Icon(Icons.directions_car_rounded),
                  onPressed: () async {
                    myCurrentPosition != null && widget.userPosition != null ? await _getRoute(myPoint!, userPoint!, 'car') : null;
                  },
                ),
                IconButton(
                  icon: myCurrentPosition != null && widget.userPosition != null ? 
                    Icon(Icons.directions_walk_rounded, color: Colors.amber)
                  : Icon(Icons.directions_walk_rounded),
                  onPressed: () async {
                    myCurrentPosition != null && widget.userPosition != null ? await _getRoute(myPoint!, userPoint!, 'foot') : null;
                  },
                ),
                IconButton(
                  icon: myCurrentPosition != null ? 
                    Icon(Icons.my_location_rounded ,color: Colors.amber)
                  : Icon(Icons.my_location_rounded),
                  onPressed: () async {
                    if (myCurrentPosition != null) {
                      setState(() {
                        mapController.move(myPoint!, 15.0);
                        info = myCurrentAddress;
                        iconInfo = Icon(Icons.location_on, color: Colors.blue, size: 40.0);
                      });
                    } else {
                      null;
                    }

                  },
                ),
              ],
            ),
          )
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 34.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Card(
                color: Color.fromARGB(255, 134, 97, 236).withOpacity(0.8),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.username != null ? widget.username! : 'Select a user',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                color: Color.fromARGB(255, 134, 97, 236).withOpacity(0.8),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      iconInfo ?? Icon(Icons.info_outline_rounded),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          info != null ? info! : 'No info',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }


  // Utility functions for location
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      }
      return false;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return false;
    }

    try {
      await _getMyCurrentPosition(); //set currentPosition
    } catch (e) {
      debugPrint(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error getting your position, please try again later.')));
      }
      return false;
    }

    return true;
  }

  _getMyCurrentPosition() async {
    // medium accuracy results in a faster response time at the cost of less accurate location data (no use of GPS)
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium).then((Position position) async {
      setState(() => myCurrentPosition = position);
    }).catchError((e) {});
  }

  _getMyCurrentAddress() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(myCurrentPosition!.latitude, myCurrentPosition!.longitude);
    setState(() {
      myCurrentAddress = '${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].postalCode}';
    });
  }

  _setMyCurrentPosition() async {
    if (await _handleLocationPermission()) {
      if (myCurrentPosition != null) {
        await _getMyCurrentAddress();
        setState(() {
          myPoint = LatLng(myCurrentPosition!.latitude, myCurrentPosition!.longitude);
          //myPoint = LatLng(45.462135, 9.207426); //TEST
          markers.removeWhere((element) => element.key == ValueKey('myPoint')); // remove previous marker
          markers.add(
            Marker(
              key: ValueKey('myPoint'),
              width: 80.0,
              height: 80.0,
              point: myPoint!,
              builder: (ctx) => Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40.0,
              ),
            ),
          );
        });
      }
    }
  }

  _setUserPosition() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(double.parse(widget.userPosition!.latitude), double.parse(widget.userPosition!.longitude));
    setState(() {
      info = '${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].postalCode}';
      iconInfo = Icon(Icons.location_on, color: Colors.red, size: 40.0);
      userCurrentAddress = info;

      userPoint = LatLng(double.parse(widget.userPosition!.latitude), double.parse(widget.userPosition!.longitude));

      markers.removeWhere((element) => element.key == ValueKey('userPoint')); // remove previous marker
      markers.add(
        Marker(
          key: ValueKey('userPoint'),
          width: 80.0,
          height: 80.0,
          point: userPoint!,
          builder: (ctx) => Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40.0,
          ),
        ),
      );
      mapController.move(userPoint!, 15.0);
    });
  }

  Future<bool> _getRoute(LatLng originPoint, LatLng destinationPoint, String vehicle) async {
    String apiKey = graphHopperKey;
    String apiUrl =
        'https://graphhopper.com/api/1/route?point=${originPoint.latitude},${originPoint.longitude}&point=${destinationPoint.latitude},${destinationPoint.longitude}&vehicle=$vehicle&key=$apiKey';

    http.Response response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      var decodedResponse = json.decode(response.body);
      var d = decodedResponse['paths'][0]['distance'];
      var points = decodedResponse['paths'][0]['points'];
      debugPrint('GET ROUTE: response code 200');

      setState(() {
        info = 'Distance: $d m';
        iconInfo = Icon(Icons.directions, color: Colors.green, size: 40.0);
        polylineCoordinates = decodePolyline(points);
      });
    } else {
      debugPrint('GET ROUTE: error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error getting route, please try again later.')));
      }
      return false;
    }
    return true;
  }


  // Algorithm to decode polyline points
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> decodedPolyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latDouble = lat / 1e5;
      double lngDouble = lng / 1e5;

      decodedPolyline.add(LatLng(latDouble, lngDouble));
    }

    return decodedPolyline;
  }

}