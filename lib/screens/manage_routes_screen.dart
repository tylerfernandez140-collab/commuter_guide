import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';
import 'add_edit_route_screen.dart';

class ManageRoutesScreen extends StatefulWidget {
  @override
  _ManageRoutesScreenState createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RouteModel>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _refreshRoutes();
  }

  void _refreshRoutes() {
    setState(() {
      _routesFuture = _apiService.getRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Routes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditRouteScreen()),
          );
          _refreshRoutes();
        },
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<RouteModel>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No routes found'));
          }

          final routes = snapshot.data!;
          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                child: ListTile(
                  title: Text(route.routeName),
                  subtitle: Text('${route.startPoint} - ${route.endPoint}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditRouteScreen(route: route),
                            ),
                          );
                          _refreshRoutes();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _apiService.deleteRoute(route.id);
                          _refreshRoutes();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
