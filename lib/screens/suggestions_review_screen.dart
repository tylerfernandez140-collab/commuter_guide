import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/suggestion.dart';
import '../services/api_service.dart';

class SuggestionsReviewScreen extends StatefulWidget {
  const SuggestionsReviewScreen({Key? key}) : super(key: key);

  @override
  _SuggestionsReviewScreenState createState() =>
      _SuggestionsReviewScreenState();
}

class _SuggestionsReviewScreenState extends State<SuggestionsReviewScreen> {
  late Future<List<Suggestion>> _suggestionsFuture;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    setState(() {
      _suggestionsFuture = Provider.of<ApiService>(
        context,
        listen: false,
      ).getSuggestions();
    });
  }

  Future<void> _handleAction(String id, bool approve) async {
    setState(() => _isLoadingAction = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      if (approve) {
        await api.approveSuggestion(id);
      } else {
        await api.rejectSuggestion(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Suggestion approved!' : 'Suggestion rejected.',
            ),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );
        _refreshSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                FutureBuilder<List<Suggestion>>(
                  future: _suggestionsFuture,
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
                              onPressed: _refreshSuggestions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final suggestions = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return _buildSuggestionCard(suggestions[index]);
                      },
                    );
                  },
                ),
                if (_isLoadingAction)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
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
                'Review Suggestions',
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
              'Approve or reject community contributions.',
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
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending suggestions to review.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Suggestion suggestion) {
    final isPending = suggestion.status == 'pending';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_location,
                color: Colors.blue,
                size: 28,
              ),
            ),
            title: Text(
              suggestion.landmarkName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'By: ${suggestion.submittedBy}',
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.map, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${suggestion.latitude.toStringAsFixed(5)}, ${suggestion.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _buildStatusBadge(suggestion.status),
          ),
          if (isPending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleAction(suggestion.id, false),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAction(suggestion.id, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
