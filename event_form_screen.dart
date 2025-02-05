import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'seen.dart'; // Import the file for EventListScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Management',
      theme: ThemeData(
        cardColor: const Color(0xFF052c65),
        primaryColor: const Color(0xFF052c65),
      ),
      debugShowCheckedModeBanner: false,
      home: const EventFormScreen(),
    );
  }
}

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text;
    final description = _descriptionController.text;
    final startDate = _startDateController.text;
    final endDate = _endDateController.text;

    final event = {
      'title': title,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/event_management/public/api/insert_events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event),
      );

      if (response.statusCode == 200) {
        _titleController.clear();
        _descriptionController.clear();
        _startDateController.clear();
        _endDateController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!'), backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EventListScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create the event.'), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Event',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF052c65),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Title'),
                _buildCardTextField(
                  _titleController,
                  'Enter event title',
                  validator: (value) => value!.isEmpty ? 'Title is required' : null,
                ),
                _buildLabel('Description'),
                _buildCardTextField(
                  _descriptionController,
                  'Enter event description',
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Description is required' : null,
                ),
                _buildLabel('Start Date'),
                GestureDetector(
                  onTap: () => _selectDate(context, _startDateController),
                  child: AbsorbPointer(
                    child: _buildCardTextField(
                      _startDateController,
                      'Select start date',
                      validator: (value) => value!.isEmpty ? 'Start date is required' : null,
                    ),
                  ),
                ),
                _buildLabel('End Date'),
                GestureDetector(
                  onTap: () => _selectDate(context, _endDateController),
                  child: AbsorbPointer(
                    child: _buildCardTextField(
                      _endDateController,
                      'Select end date',
                      validator: (value) => value!.isEmpty ? 'End date is required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                          ),
                          onPressed: _submitForm,
                          child: const Text(
                            'Submit',
                            style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF052c65),
        ),
      ),
    );
  }

  Widget _buildCardTextField(
    TextEditingController controller,
    String hintText, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
