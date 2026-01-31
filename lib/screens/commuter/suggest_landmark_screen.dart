import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class SuggestLandmarkScreen extends StatefulWidget {
  const SuggestLandmarkScreen({Key? key}) : super(key: key);

  @override
  _SuggestLandmarkScreenState createState() => _SuggestLandmarkScreenState();
}

class _SuggestLandmarkScreenState extends State<SuggestLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<ApiService>(context, listen: false).submitSuggestion(
        _nameController.text,
        double.parse(_latController.text),
        double.parse(_lngController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _latController.clear();
        _lngController.clear();
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildInputFields(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          const Icon(
            Icons.add_location_alt_outlined,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Suggest a Landmark',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve the map by adding missing locations.',
            style: TextStyle(fontSize: 16, color: Colors.teal.shade50),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Your suggestion will be reviewed by an admin before appearing on the map.',
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Landmark Name',
                hintText: 'e.g., Central Station',
                prefixIcon: const Icon(Icons.place, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: const Icon(
                        Icons.my_location,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: const Icon(
                        Icons.my_location,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send),
                  SizedBox(width: 12),
                  Text(
                    'SUBMIT SUGGESTION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
