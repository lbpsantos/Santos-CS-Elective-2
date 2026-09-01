import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home Screen'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/details'),
              child: const Text('Go to Product Details'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/cart'),
              child: const Text('Go to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
