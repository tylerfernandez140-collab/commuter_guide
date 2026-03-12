import 'package:flutter/material.dart';

class JeepIcon extends StatelessWidget {
  final double size;
  final Color color;

  const JeepIcon({
    super.key,
    this.size = 35.0,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'jeep_logo.png',
        width: size * 1.2,
        height: size * 1.2,
        fit: BoxFit.cover,
      ),
    );
  }
}

class JeepIconWhite extends StatelessWidget {
  final double size;

  const JeepIconWhite({
    super.key,
    this.size = 35.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'jeep_logo.png',
        width: size * 1.2,
        height: size * 1.2,
        fit: BoxFit.cover,
      ),
    );
  }
}
