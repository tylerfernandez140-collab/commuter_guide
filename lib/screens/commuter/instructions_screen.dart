import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  final List<String> instructions;

  const InstructionsScreen({super.key, required this.instructions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: instructions.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                child: Text('${index + 1}'),
              ),
              title: Text(instructions[index]),
            ),
          );
        },
      ),
    );
  }
}
