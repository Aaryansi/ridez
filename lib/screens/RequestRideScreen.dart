import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  _RequestRideScreenState createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String pickup = '';
  String dropOff = '';
  String notes = '';
  GeoPoint? pickupLocation;

  final places = GoogleMapsPlaces(apiKey: "YOUR_API_KEY"); // Replace with your API key

  Future<void> _openAutocomplete(Function(String, GeoPoint) updateAddress) async {
    try {
      Prediction? prediction = await PlacesAutocomplete.show(
        context: context,
        apiKey: "YOUR_API_KEY", // Replace with your API key
        mode: Mode.overlay,
        language: "en",
        components: [Component(Component.country, "us")],
      );

      if (prediction == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No address selected. Please try again.")),
        );
        return;
      }

      PlacesDetailsResponse details = await places.getDetailsByPlaceId(prediction.placeId!);

      if (details.result.geometry?.location != null) {
        GeoPoint geoPoint = GeoPoint(
          details.result.geometry!.location.lat,
          details.result.geometry!.location.lng,
        );
        updateAddress(details.result.formattedAddress ?? "Unknown Address", geoPoint);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Address details not available. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  Future<void> submitRideRequest() async {
    if (_formKey.currentState!.validate() && pickupLocation != null) {
      try {
        await _firestore.collection('rideRequests').add({
          'pickup': pickup,
          'dropOff': dropOff,
          'notes': notes,
          'pickupLocation': pickupLocation,
          'userId': "exampleUserId123", // Replace with logged-in user ID
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride request submitted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pickup location must be selected.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request a Ride'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _openAutocomplete((address, geoPoint) {
                    setState(() {
                      pickup = address;
                      pickupLocation = geoPoint;
                    });
                  });
                },
                child: Text(
                  pickup.isEmpty ? "Select Pickup Location" : pickup,
                ),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Drop-off Location'),
                onChanged: (value) => dropOff = value,
                validator: (value) => value!.isEmpty ? 'Drop-off location is required' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Additional Notes (Optional)'),
                onChanged: (value) => notes = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitRideRequest,
                child: Text('Submit Ride Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
