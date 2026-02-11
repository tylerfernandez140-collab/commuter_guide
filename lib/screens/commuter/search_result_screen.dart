import 'package:flutter/material.dart';
import 'instructions_screen.dart';
import 'map_screen.dart';

class SearchResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final String destination;

  const SearchResultScreen({
    Key? key,
    required this.result,
    required this.destination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routeName = result['route_name'];
    final vehicleType = result['vehicle_type'];
    final fare = result['fare'];
    final eta = result['estimated_time'];
    final instructions = List<String>.from(result['instructions'] ?? []);
    final coordinates = result['coordinates'] ?? [];
    final landmarks = result['landmarks'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Search Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          routeName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(label: Text(vehicleType.toString().toUpperCase())),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.payments, color: Colors.green),
                        Text(
                          'Fare: ₱$fare',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.access_time, color: Colors.orange),
                        Text(
                          ' ETA: $eta mins',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('View Instructions'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        InstructionsScreen(instructions: instructions),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('View Map'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MapScreen(
                      routeName: routeName,
                      routeCoordinates: coordinates,
                      landmarks: landmarks,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
