import 'package:flutter/material.dart';

class PlanFormScreen extends StatelessWidget {
  final String? planId;
  const PlanFormScreen({super.key, this.planId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(planId == null ? 'Create Plan' : 'Edit Plan')),
      body: const Center(child: Text('Form goes here')),
    );
  }
}
