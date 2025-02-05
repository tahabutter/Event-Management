import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EventDetailScreen extends StatefulWidget {
  final String startDate;
  final String endDate;
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.eventId,
  });

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with TickerProviderStateMixin {
  bool _isFetchingFacilities = false;
  List _fetchedFacilities = [];
  late AnimationController _fadeInController;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fetchSelectedFacilities();
  }

  /// Fetch Facilities from API
  Future<void> _fetchSelectedFacilities() async {
    setState(() {
      _isFetchingFacilities = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/event_management/public/api/select_facilities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'event_id': widget.eventId}),
      );

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null) {
          setState(() {
            _fetchedFacilities = List<Map<String, dynamic>>.from(data['data']);
            _fadeInController.forward();
          });
        } else {
          _showError('No facilities data found.');
        }
      } else {
        _showError('Failed to fetch selected facilities.');
      }
    } catch (e) {
      _showError('An error occurred while fetching selected facilities: $e');
    } finally {
      setState(() {
        _isFetchingFacilities = false;
      });
    }
  }

  /// Delete Facility by facility_id
  Future<void> _onCancel(String? facilityId) async {
    if (facilityId == null || facilityId.isEmpty || facilityId == "null") {
      _showError('Facility ID is missing.');
      return;
    }

    final requestBody = json.encode({
      'event_id': widget.eventId,
      'facility_id': facilityId,
    });

    print("Sending DELETE request: $requestBody");

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/event_management/public/api/delete_request'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _fetchedFacilities.removeWhere((facility) => facility['facility_id'] == facilityId);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Facility canceled and deleted'),
          backgroundColor: Colors.green,
        ));
      } else {
        _showError('Failed to delete the facility: ${response.body}');
      }
    } catch (e) {
      _showError('An error occurred while deleting the facility: $e');
    }
  }

  /// Show Error Message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF052c65),
        elevation: 6,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF052c65), Color(0xFF00509d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Date: ${widget.startDate}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'End Date: ${widget.endDate}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            _isFetchingFacilities
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _fetchedFacilities.isEmpty
                        ? const Center(
                            child: Text(
                              'No facilities added.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeInController,
                            child: ListView.builder(
                              itemCount: _fetchedFacilities.length,
                              itemBuilder: (context, index) {
                                final facility = _fetchedFacilities[index];
                                final facilityId = facility['facility_id']?.toString() ?? 'N/A';
                                final facilityName = facility['facility_name'] ?? 'No Name'; // Corrected key

                                return Card(
                                  elevation: 5,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16.0),
                                    title: Text(
                                      "$facilityName",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => _onCancel(facilityId),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
