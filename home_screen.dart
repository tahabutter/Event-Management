import 'package:finalproject/my_request.dart';
import 'package:finalproject/seen.dart';
import 'package:flutter/material.dart';
import 'package:finalproject/My_Admin.dart'; // Import My_Admin.dart
import 'event_form_screen.dart';
//import 'event_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.red),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40.0,
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Baba Guru Nanak University\n',
                    style: TextStyle(
                      color: Color(0xFF052c65),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Nankana Shahib',
                    style: TextStyle(
                      color: Color(0xFF2b2f32),
                      fontSize: 8.0,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[200],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF052c65)),
              title: const Text(
                'Home',
                style: TextStyle(color: Color(0xFF052c65)),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Color(0xFF052c65)),
              title: const Text(
                'Event List',
                style: TextStyle(color: Color(0xFF052c65)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventListScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two cards per row
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildCard(context, Icons.event, 'Add Event', Colors.blue, const EventFormScreen()),
            _buildCard(context, Icons.request_page, 'My Request', Colors.green, const MyRequestScreen()),
            _buildCard(context, Icons.admin_panel_settings, 'My Admin', Colors.orange, const MyAdminScreen()), // Updated
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String text, Color color, Widget page) {
    return Card(
      color: color,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
