import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/landmark.dart';
import '../services/api_service.dart';

class ManageLandmarksScreen extends StatefulWidget {
  const ManageLandmarksScreen({Key? key}) : super(key: key);

  @override
  _ManageLandmarksScreenState createState() => _ManageLandmarksScreenState();
}

class _ManageLandmarksScreenState extends State<ManageLandmarksScreen> {
  late Future<List<Landmark>> _landmarksFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshLandmarks();
  }

  void _refreshLandmarks() {
    setState(() {
      _landmarksFuture = Provider.of<ApiService>(
        context,
        listen: false,
      ).getLandmarks();
    });
  }

  Future<void> _deleteLandmark(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this landmark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<ApiService>(
          context,
          listen: false,
        ).deleteLandmark(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Landmark deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshLandmarks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditDialog([Landmark? landmark]) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _LandmarkDialog(landmark: landmark, onSave: _refreshLandmarks),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Landmark>>(
                    future: _landmarksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshLandmarks,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final landmark = snapshot.data![index];
                          return _buildLandmarkCard(landmark);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        label: const Text('Add Landmark'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Manage Landmarks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              'Add, edit, or remove map locations.',
              style: TextStyle(fontSize: 16, color: Colors.teal.shade50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No landmarks yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add one.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkCard(Landmark landmark) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(landmark.type),
            color: Colors.teal,
            size: 28,
          ),
        ),
        title: Text(
          landmark.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(landmark.type, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.near_me, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Near: ${landmark.nearRoute}',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddEditDialog(landmark),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteLandmark(landmark.id),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'terminal':
        return Icons.directions_bus;
      case 'mall':
        return Icons.shopping_bag;
      case 'school':
        return Icons.school;
      case 'hospital':
        return Icons.local_hospital;
      case 'park':
        return Icons.park;
      default:
        return Icons.place;
    }
  }
}

class _LandmarkDialog extends StatefulWidget {
  final Landmark? landmark;
  final VoidCallback onSave;

  const _LandmarkDialog({Key? key, this.landmark, required this.onSave})
    : super(key: key);

  @override
  __LandmarkDialogState createState() => __LandmarkDialogState();
}

class __LandmarkDialogState extends State<_LandmarkDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _nearRouteController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.landmark?.name ?? '');
    _typeController = TextEditingController(text: widget.landmark?.type ?? '');
    _nearRouteController = TextEditingController(
      text: widget.landmark?.nearRoute ?? '',
    );
    _latController = TextEditingController(
      text: widget.landmark?.latitude.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: widget.landmark?.longitude.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _nearRouteController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newLandmark = Landmark(
        id: widget.landmark?.id ?? '',
        name: _nameController.text,
        type: _typeController.text,
        nearRoute: _nearRouteController.text,
        latitude: double.parse(_latController.text),
        longitude: double.parse(_lngController.text),
      );

      final api = Provider.of<ApiService>(context, listen: false);
      if (widget.landmark == null) {
        await api.createLandmark(newLandmark);
      } else {
        await api.updateLandmark(widget.landmark!.id, newLandmark);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.landmark == null
                  ? 'Landmark created successfully'
                  : 'Landmark updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.landmark == null ? 'Add Landmark' : 'Edit Landmark'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (e.g., Mall)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _nearRouteController,
                decoration: const InputDecoration(labelText: 'Near Route'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
