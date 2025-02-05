import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestScreen extends StatefulWidget {
  final String eventId;

  const RequestScreen({super.key, required this.eventId});

  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  List<dynamic> _facilities = [];
  List<String> _selectedFacilities = [];
  List<dynamic> _fetchedFacilities = [];
  List<String> _customFacilities = [];
  bool _isLoading = true;
  bool _isFetchingFacilities = false;
  bool _isSubmitting = false;
  final TextEditingController _customFacilityController = TextEditingController();

  /// Fetch facilities for selection (from a separate API endpoint)
  Future<void> _fetchFacilities() async {
    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/event_management/public/api/facilities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _facilities = (data['data'] as List<dynamic>?)?.map((facility) {
            // Try both keys: 'facilities_name' and 'facility_name'
            final name = facility['facilities_name'] ??
                facility['facility_name'] ??
                'Unknown Facility';
            return {'name': name};
          }).toList() ?? [];
        });
      } else {
        _showError('Failed to fetch facilities.');
      }
    } catch (e) {
      _showError('An error occurred while fetching facilities.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch facilities already selected for this event
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

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          _fetchedFacilities = data['data'] as List<dynamic>? ?? [];
        });
      } else {
        // API returned an error status
        _showError(data['message'] ?? 'No facilities found for the given event_id.');
        setState(() {
          _fetchedFacilities = [];
        });
      }
    } catch (e) {
      _showError('An error occurred while fetching selected facilities.');
    } finally {
      setState(() {
        _isFetchingFacilities = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitRequest() async {
    final selectedFacilityNames = List<String>.from(_selectedFacilities);
    selectedFacilityNames.addAll(_customFacilities);

    if (selectedFacilityNames.isEmpty) {
      _showError('Please select at least one facility.');
      return;
    }

    final facilitiesNamesString = selectedFacilityNames.join(", ");

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/event_management/public/api/event_facilities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'event_id': widget.eventId,
          'facilities_name': facilitiesNamesString,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data successfully stored!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear selected and custom facilities
        setState(() {
          _customFacilities.clear();
          _selectedFacilities.clear();
          _customFacilityController.clear();
        });

        // Refresh the facilities data
        await _fetchSelectedFacilities();
        await _fetchFacilities();
      } else {
        _showError(responseData['message'] ?? 'Failed to submit request.');
      }
    } catch (e) {
      _showError('An error occurred while submitting the request.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _addCustomFacility() {
    final customFacility = _customFacilityController.text.trim();
    if (customFacility.isNotEmpty) {
      setState(() {
        _customFacilities.add(customFacility);
        _customFacilityController.clear();
      });
    } else {
      _showError('Please enter a facility name.');
    }
  }

  void _removeFacility(int index, bool isCustom) {
    setState(() {
      if (isCustom) {
        _customFacilities.removeAt(index);
      } else {
        _selectedFacilities.removeAt(index);
      }
    });
  }

  Future<void> _selectFacilities() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          items: _facilities.map((facility) {
            return MultiSelectItem<String>(facility['name'], facility['name']);
          }).toList(),
          initialValue: _selectedFacilities,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedFacilities = selected;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchFacilities();
    await _fetchSelectedFacilities();
  }

  @override
  void initState() {
    super.initState();
    // Fetch data only once when the screen loads
    _fetchFacilities();
    _fetchSelectedFacilities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF052c65),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _selectFacilities,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Select Facilities',
                                  hintText: 'Choose facilities',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _selectedFacilities.isEmpty
                                      ? 'Select facilities'
                                      : _selectedFacilities.where((e) => e.isNotEmpty).join(', '),
                                  style: TextStyle(color: Colors.black.withOpacity(0.7)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customFacilityController,
                                    decoration: InputDecoration(
                                      labelText: 'Other Facility',
                                      hintText: 'Enter a custom facility',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 237, 32, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _addCustomFacility,
                                  child: const Icon(Icons.add, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_customFacilities.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Custom Facilities:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _customFacilities.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: ListTile(
                                          title: Text(
                                            _customFacilities[index],
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _removeFacility(index, true),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 227, 25, 25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isSubmitting ? null : _submitRequest,
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          'Submit',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color.fromARGB(255, 6, 18, 126)),
                            const Text(
                              'All Facilities:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color.fromARGB(255, 10, 4, 124),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isFetchingFacilities)
                              const CircularProgressIndicator(color: Colors.white)
                            else if (_fetchedFacilities.isEmpty)
                              const Text(
                                'No facilities added to this event yet.',
                                style: TextStyle(color: Colors.black),
                              )
                            else
                              SizedBox(
                                height: 300,
                                child: ListView.builder(
                                  itemCount: _fetchedFacilities.length,
                                  itemBuilder: (context, index) {
                                    final facility = _fetchedFacilities[index];
                                    // Try both keys for facility name
                                    final facilityName = facility['facility_name'] ??
                                        facility['facilities_name'] ??
                                        'Unknown Facility';
                                    return Card(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        title: Text(
                                          facilityName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF052c65),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<MultiSelectItem<String>> items;
  final List<String> initialValue;

  const MultiSelectDialog({super.key, required this.items, required this.initialValue});

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> selectedValues;
  late List<MultiSelectItem<String>> filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedValues = List.from(widget.initialValue);
    filteredItems = List.from(widget.items);
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = widget.items
          .where((item) => item.label.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF052c65),
      title: const Text(
        'Select Facilities',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Search facilities',
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: _filterItems,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: filteredItems.map((item) {
                  return FilterChip(
                    selectedColor: Colors.red,
                    checkmarkColor: Colors.white,
                    label: Text(
                      item.label,
                      style: TextStyle(
                        color: selectedValues.contains(item.value) ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: selectedValues.contains(item.value),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedValues.add(item.value);
                        } else {
                          selectedValues.remove(item.value);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(selectedValues);
          },
          child: const Text(
            'Done',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class MultiSelectItem<T> {
  final T value;
  final String label;

  MultiSelectItem(this.value, this.label);
}
