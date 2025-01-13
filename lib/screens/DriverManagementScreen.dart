import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({Key? key}) : super(key: key);

  @override
  _DriverManagementScreenState createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildRidesList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('rideOffers')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data!.docs;

        if (rides.isEmpty) {
          return Center(child: Text('No rides with status "$status".'));
        }

        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index].data() as Map<String, dynamic>;
            final rideId = rides[index].id;

            return Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${ride['pickupAddress']}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Dropoff: ${ride['dropoffAddress']}'),
                    Text('Date: ${ride['rideDate']}'),
                    Text('Time: ${ride['rideTime']}'),
                    Text('Seats Left: ${ride['seatsLeft']}'),
                    Text('Status: ${ride['status']}'),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () {
                          showPopupMenu(context, rideId, ride);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showPopupMenu(BuildContext context, String rideId, Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showRideDetailsDialog(context, ride);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Ride'),
              onTap: () {
                Navigator.pop(context);
                _showEditRideDialog(context, rideId, ride);
              },
            ),
            if (ride['status'] == 'Available') ...[
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancel Ride'),
                onTap: () {
                  Navigator.pop(context);
                  cancelRide(rideId);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Mark as Completed'),
                onTap: () {
                  Navigator.pop(context);
                  completeRide(rideId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> cancelRide(String rideId) async {
    try {
      await _firestore.collection('rideOffers').doc(rideId).update({
        'status': 'Cancelled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride cancelled successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel ride: $e')),
      );
    }
  }

  Future<void> completeRide(String rideId) async {
    try {
      await _firestore.collection('rideOffers').doc(rideId).update({
        'status': 'Completed',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride marked as completed!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete ride: $e')),
      );
    }
  }

  void _showRideDetailsDialog(BuildContext context, Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ride Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pickup: ${ride['pickupAddress']}'),
            Text('Dropoff: ${ride['dropoffAddress']}'),
            Text('Date: ${ride['rideDate']}'),
            Text('Time: ${ride['rideTime']}'),
            Text('Seats Left: ${ride['seatsLeft']}'),
            Text('Status: ${ride['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditRideDialog(BuildContext context, String rideId, Map<String, dynamic> ride) {
    TextEditingController seatsController =
    TextEditingController(text: ride['seatsLeft'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: seatsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Available Seats'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                int newSeats = int.parse(seatsController.text);
                await _firestore.collection('rideOffers').doc(rideId).update({
                  'seatsLeft': newSeats,
                  'status': newSeats == 0 ? 'Full' : 'Available',
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ride updated successfully!')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update ride: $e')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage My Rides'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            buildRidesList('Available'),
            buildRidesList('In Progress'),
            buildRidesList('Completed'),
            buildRidesList('Cancelled'),
          ],
        ),
      ),
    );
  }
}
