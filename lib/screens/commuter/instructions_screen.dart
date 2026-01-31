import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  final List<String> instructions;

  const InstructionsScreen({Key? key, required this.instructions}) : super(key: key);

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
                child: Text('${index + 1}'),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              title: Text(instructions[index]),
            ),
          );
        },
      ),
    );
  }
}
