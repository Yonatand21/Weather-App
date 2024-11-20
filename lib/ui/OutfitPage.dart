import 'package:flutter/material.dart';

class OutfitPage extends StatelessWidget {
  const OutfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Recommendation'),
      ),
      body: Center(
        child: Text(
          'Here is your outfit recommendation!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}