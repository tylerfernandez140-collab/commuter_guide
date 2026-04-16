import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import 'map_screen.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RouteModel route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(route.routeName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              context,
              icon: Icons.directions_bus,
              title: 'Vehicle Type',
              value: route.vehicleType.toUpperCase(),
            ),
            SizedBox(height: 12),
            // Show discounted fare if available
            if (route.discountedFare != null) ...[
              _buildInfoCard(
                context,
                icon: Icons.school,
                title: 'Discounted Fare',
                value: '₱${route.discountedFare!.toStringAsFixed(2)}',
              ),
              SizedBox(height: 12),
            ],
            // Show regular fare if available
            if (route.regularFare != null) ...[
              _buildInfoCard(
                context,
                icon: Icons.person,
                title: 'Regular Fare',
                value: '₱${route.regularFare!.toStringAsFixed(2)}',
              ),
              SizedBox(height: 12),
            ],
            // Show legacy fare if available and no new fares
            if (route.discountedFare == null && route.regularFare == null && route.fare != null) ...[
              _buildInfoCard(
                context,
                icon: Icons.payments,
                title: 'Fare',
                value: '₱${route.fare!.toStringAsFixed(2)}',
              ),
              SizedBox(height: 12),
            ],
            // Show no fare if none available
            if (route.discountedFare == null && route.regularFare == null && route.fare == null) ...[
              _buildInfoCard(
                context,
                icon: Icons.payments,
                title: 'Fare',
                value: 'N/A',
              ),
              SizedBox(height: 12),
            ],
            _buildInfoCard(
              context,
              icon: Icons.access_time,
              title: 'Estimated Time',
              value: '${route.estimatedTime} mins',
            ),
            SizedBox(height: 12),
             _buildInfoCard(
              context,
              icon: Icons.location_on,
              title: 'Route',
              value: '${route.startPoint} ➝ ${route.endPoint}',
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: Icon(Icons.map),
                label: Text('View on Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        routeCoordinates: route.coordinates,
                        routeName: route.routeName,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String value}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.teal,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
