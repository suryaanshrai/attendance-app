import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';

class UserGridItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserGridItem({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: user.image != null
                  ? Image.memory(
                      base64Decode(user.image!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 50),
                    )
                  : const Icon(Icons.person, size: 50),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                user.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
