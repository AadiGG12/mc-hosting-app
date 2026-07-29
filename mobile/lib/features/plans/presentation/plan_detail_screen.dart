import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'plans_provider.dart';

class PlanDetailScreen extends ConsumerWidget {
  final String slug;
  const PlanDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(slug)),
      body: planAsync.when(
        data: (plan) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text('₹${plan.priceMonthly}/mo', style: const TextStyle(fontSize: 24, color: Colors.green)),
              const SizedBox(height: 16),
              Text(plan.description),
              const SizedBox(height: 16),
              ...plan.features.map((f) => Row(children: [const Icon(Icons.check, color: Colors.green), SizedBox(width: 8), Text(f)])).toList(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger payment service
                  },
                  child: const Text('Purchase'),
                ),
              )
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}
