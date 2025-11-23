import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class StripeSuccessScreen extends StatefulWidget {
  const StripeSuccessScreen({Key? key}) : super(key: key);

  @override
  State<StripeSuccessScreen> createState() => _StripeSuccessScreenState();
}

class _StripeSuccessScreenState extends State<StripeSuccessScreen> {
  bool _isChecking = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkStripeStatus();
  }

  Future<void> _checkStripeStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Wait a moment for Stripe webhook to process
      await Future.delayed(const Duration(seconds: 2));

      // Check if Stripe account is verified
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(userId)
          .get();

      final data = doc.data();
      final stripeAccountId = data?['stripeAccountId'] as String?;
      final stripeVerified = data?['stripeVerified'] as bool? ?? false;

      setState(() {
        _isVerified = stripeVerified && stripeAccountId != null;
        _isChecking = false;
      });

      // Auto-navigate back to dashboard after a moment if verified
      if (_isVerified) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/main');
        }
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Setup'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/main'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isChecking) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Verifying your payment setup...',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ] else if (_isVerified) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 50,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Setup Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can now receive payments from customers.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Redirecting to dashboard...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ] else ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pending,
                    size: 50,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Setup In Progress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your payment setup is being processed. This may take upto 48 hours.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/main'),
                  child: const Text('Return to Dashboard'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _checkStripeStatus,
                  child: const Text('Check Status Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}