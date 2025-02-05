import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'event_detail_screen.dart';

class MyAdminScreen extends StatefulWidget {
  const MyAdminScreen({super.key});

  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<MyAdminScreen> {
  List<dynamic> _events = [];
  bool _isLoading = true;

  Future<void> _fetchEvents() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://devtechtop.com/event_management/public/api/select_events'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('data') && data['data'] is List) {
          List<Map<String, dynamic>> eventsList =
              List<Map<String, dynamic>>.from(data['data']);
          eventsList.sort((a, b) => int.tryParse(b['id'].toString())!
              .compareTo(int.tryParse(a['id'].toString())!));

          setState(() {
            _events = eventsList;
          });
        } else {
          setState(() {
            _events = [];
          });
        }
      } else {
        setState(() {
          _events = [];
        });
      }
    } catch (e) {
      setState(() {
        _events = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Admin',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Color(0xFF052c65),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // White back icon
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF052c65)))
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'No events available.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['title'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF052c65),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                event['description'] ??
                                    'No description available.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Icon(Icons.date_range,
                                      color: Color(0xFF052c65), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Start: ${event['start_date']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF052c65),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.date_range,
                                      color: Color(0xFF052c65), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'End: ${event['end_date']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF052c65),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.orange, // Orange color
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailScreen(
                                          startDate: event['start_date'],
                                          endDate: event['end_date'],
                                          eventId: event['id']
                                              .toString(), // Pass eventId
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  // ElevatedButton(
                                  //   style: ElevatedButton.styleFrom(
                                  //     backgroundColor:
                                  //         Color.fromARGB(255, 225, 9, 9),
                                  //     shape: RoundedRectangleBorder(
                                  //       borderRadius: BorderRadius.circular(8),
                                  //     ),
                                  //   ),
                                  //   onPressed: () {},
                                  //   child: const Text(
                                  //     'Add Facuilites',
                                  //     style: TextStyle(color: Colors.white),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
