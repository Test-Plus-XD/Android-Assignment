import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  final ValueChanged<bool> onLoginStateChanged;

  const AccountPage({required this.onLoginStateChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You are logged in.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onLoginStateChanged(false),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
