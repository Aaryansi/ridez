import 'package:flutter/material.dart';
import 'DriverManagementScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_google_places/flutter_google_places.dart'; // Commented for now
// import 'package:google_maps_webservice/places.dart'; // Commented for now

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  _OfferRideScreenState createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String pickupAddress = '';
  String dropoffAddress = '';
  String rideDate = ''; // To store the selected date
  String rideTime = ''; // To store the selected time
  int availableSeats = 1;
  String notes = '';

  // List of predefined locations for dropdowns
  final List<String> locations = [
    'Ashton Apartments',
    'Heritage Apartments',
    'Village Quarters',
    'Rose-Hulman',
  ];

  @override
  void initState() {
    super.initState();
    _checkForUpcomingRide(); // Check for upcoming rides on screen load
  }

  Future<void> _checkForUpcomingRide() async {
    try {
      // Get the current timestamp
      final now = DateTime.now();

      // Calculate the time range for the next 1 hour
      final oneHourLater = now.add(Duration(hours: 1));

      // Query Firestore for rides in the next hour
      final upcomingRides = await _firestore
          .collection('rideOffers')
          .where('status', isEqualTo: 'Available')
          .get();

      for (var ride in upcomingRides.docs) {
        final rideData = ride.data();
        final rideDateTime = DateTime.parse(
          '${rideData['rideDate']} ${rideData['rideTime']}', // Format: "YYYY-MM-DD HH:mm"
        );

        if (rideDateTime.isAfter(now) && rideDateTime.isBefore(oneHourLater)) {
          // Upcoming ride found
          _showUpcomingRidePopup(context, rideData);
          return;
        }
      }
    } catch (e) {
      print('Error checking for upcoming rides: $e');
    }
  }

  void _showUpcomingRidePopup(BuildContext context, Map<String, dynamic> rideData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upcoming Ride Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have an upcoming ride in the next hour:'),
            SizedBox(height: 10),
            Text('Pickup: ${rideData['pickupAddress']}'),
            Text('Dropoff: ${rideData['dropoffAddress']}'),
            Text('Time: ${rideData['rideTime']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DriverManagementScreen()),
              );
            },
            child: Text('Go to My Rides'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)), // Limit to one year
    );

    if (selectedDate != null) {
      setState(() {
        rideDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        rideTime = selectedTime.format(context);
      });
    }
  }

  Future<void> submitRideOffer() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Add ride offer to Firestore
        await _firestore.collection('rideOffers').add({
          'pickupAddress': pickupAddress,
          'dropoffAddress': dropoffAddress,
          'rideDate': rideDate,
          'rideTime': rideTime,
          'availableSeats': availableSeats,
          'seatsLeft': availableSeats, // Initialize seatsLeft
          'status': 'Available', // Initialize status
          'notes': notes,
          'requests': [], // Initialize requests as an empty list
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride offer submitted successfully!')),
        );

        // Navigate to the DriverManagementScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DriverManagementScreen()),
        );
      } catch (e) {
        // Handle Firestore errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit offer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offer a Ride'),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DriverManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pickup Address", style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: pickupAddress.isNotEmpty ? pickupAddress : null,
                hint: Text("Select Pickup Location"),
                items: locations
                    .map((location) => DropdownMenuItem(
                  value: location,
                  child: Text(location),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    pickupAddress = value!;
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Pickup location is required' : null,
              ),
              SizedBox(height: 10),
              Text("Drop-off Address", style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: dropoffAddress.isNotEmpty ? dropoffAddress : null,
                hint: Text("Select Drop-off Location"),
                items: locations
                    .map((location) => DropdownMenuItem(
                  value: location,
                  child: Text(location),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    dropoffAddress = value!;
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Drop-off location is required' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Ride Date'),
                controller: TextEditingController(text: rideDate),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) =>
                value!.isEmpty ? 'Please select a ride date' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Ride Time'),
                controller: TextEditingController(text: rideTime),
                readOnly: true,
                onTap: _selectTime,
                validator: (value) =>
                value!.isEmpty ? 'Please select a ride time' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Available Seats'),
                keyboardType: TextInputType.number,
                onChanged: (value) => availableSeats = int.tryParse(value) ?? 1,
                validator: (value) =>
                value!.isEmpty || int.tryParse(value) == null || int.tryParse(value)! <= 0
                    ? 'Valid number of seats is required'
                    : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Additional Notes'),
                onChanged: (value) => notes = value,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: submitRideOffer,
                  child: Text('Submit Ride Offer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
