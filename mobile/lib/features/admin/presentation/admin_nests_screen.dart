import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

class AdminNestsScreen extends StatefulWidget {
  const AdminNestsScreen({super.key});

  @override
  State<AdminNestsScreen> createState() => _AdminNestsScreenState();
}

class _AdminNestsScreenState extends State<AdminNestsScreen> {
  final AdminRepository _repo = AdminRepository();
  List<AdminNest> _nests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNests();
  }

  Future<void> _loadNests() async {
    setState(() => _isLoading = true);
    final nests = await _repo.getNests();
    setState(() {
      _nests = nests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('Nests & Eggs Configuration (${_nests.length})'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          : _nests.isEmpty
              ? const Center(child: Text('No nests configured', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nests.length,
                  itemBuilder: (context, index) {
                    final n = _nests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.egg_outlined, color: AppTheme.secondary),
                        ),
                        title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${n.description.isEmpty ? "Standard Service Nest" : n.description}\nAuthor: ${n.author}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
