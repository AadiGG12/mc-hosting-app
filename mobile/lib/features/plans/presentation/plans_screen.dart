import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'plans_provider.dart';
import '../data/plan_models.dart';
import '../data/cart_provider.dart';
import '../data/plans_websocket_service.dart';
import '../../../core/theme.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all';
  bool _showUpdateBanner = false;
  String _updateMessage = '';
  int _lastSeenSignal = 0;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All Plans', 'icon': '🌟'},
    {'id': 'minecraft', 'name': 'Minecraft', 'icon': '⛏️'},
    {'id': 'vps', 'name': 'VPS', 'icon': '🖥️'},
    {'id': 'web', 'name': 'Web Hosting', 'icon': '🌐'},
    {'id': 'discord', 'name': 'Discord Bots', 'icon': '🤖'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Called when [planUpdateSignalProvider] increments — plans changed.
  void _handleUpdateSignal(int signal) {
    if (signal == _lastSeenSignal) return;
    _lastSeenSignal = signal;

    const message = '📋 Plans updated — refreshing catalog!';

    setState(() {
      _showUpdateBanner = true;
      _updateMessage = message;
    });

    // Auto-hide the banner after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showUpdateBanner = false);
    });

    // Show floating toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: AppTheme.accentAqua,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch for real-time plan update signals (incrementing counter)
    final updateSignal = ref.watch(planUpdateSignalProvider);
    if (updateSignal != _lastSeenSignal) {
      // Use a post-frame callback so we don't call setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUpdateSignal(updateSignal);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'RenCloud',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentAquaLight.withOpacity(isDark ? 0.15 : 1.0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentAqua.withOpacity(0.4)),
              ),
              child: Text(
                'PLANS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? AppTheme.accentAqua : AppTheme.accentAqua),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Cart Button with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/home/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentAqua,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: plansAsync.when(
        data: (plans) {
          // Filter plans by search and category
          final query = _searchCtrl.text.toLowerCase().trim();
          var filtered = plans.where((p) {
            final matchesSearch = query.isEmpty ||
                p.name.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query);
            final matchesCategory = _selectedCategory == 'all' ||
                p.slug.contains(_selectedCategory) ||
                p.name.toLowerCase().contains(_selectedCategory);
            return matchesSearch && matchesCategory;
          }).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real-Time Update Banner (animated)
                if (_showUpdateBanner)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentAqua.withOpacity(0.2), AppTheme.primaryPurple.withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accentAqua.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAqua.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sync, color: AppTheme.accentAqua, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _updateMessage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                'Tap to refresh now',
                                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showUpdateBanner = false);
                            ref.refresh(plansProvider);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAqua,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Refresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hero Section
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Server Hosting Plans',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'High-performance Minecraft & cloud hosting',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search plans by name or specs...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCardBg : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${cat['icon']} ${cat['name']}'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat['id']!),
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryPurple : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            ),
                          ),
                          elevation: isSelected ? 3 : 0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Results Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} Plans Available',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Plan Cards Grid
                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppTheme.primaryPurple),
                        const SizedBox(height: 12),
                        const Text('No plans found matching your search.',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _selectedCategory = 'all');
                          },
                          child: const Text('Reset Filters', style: TextStyle(color: AppTheme.accentAqua)),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlanCard(plan: plan),
                  )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Error: $err', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(plansProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerStatefulWidget {
  final Plan plan;
  const _PlanCard({required this.plan});

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartItems = ref.watch(cartProvider);
    final inCart = cartItems.any((item) => item.plan.id == widget.plan.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final glowOpacity = widget.plan.isFeatured ? _glowAnimation.value : (_isPressed ? 0.4 : 0.1);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: widget.plan.isFeatured
                      ? [AppTheme.primaryPurple.withOpacity(glowOpacity), AppTheme.accentAqua.withOpacity(glowOpacity)]
                      : [(isDark ? AppTheme.borderDark : AppTheme.borderLight).withOpacity(0.8),
                         (isDark ? AppTheme.borderDark : AppTheme.borderLight).withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.plan.isFeatured
                        ? AppTheme.accentAqua.withOpacity(glowOpacity * 0.5)
                        : AppTheme.primaryPurple.withOpacity(_isPressed ? 0.2 : 0.05),
                    blurRadius: widget.plan.isFeatured ? 18 : 12,
                    spreadRadius: widget.plan.isFeatured ? 1.5 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.92) : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge + RAM Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAqua.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.accentAqua.withOpacity(0.35)),
                                ),
                                child: Text(
                                  '${widget.plan.ramMb}MB RAM',
                                  style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w800,
                                    color: AppTheme.accentAqua, letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${widget.plan.storageGb}GB NVMe',
                                  style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Plan Name
                          Text(
                            widget.plan.name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${widget.plan.priceMonthly.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryPurple,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Text(
                                '/mo',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          const SizedBox(height: 12),

                          // Specs Grid
                          _buildSpecRow(Icons.memory_rounded, 'RAM', '${widget.plan.ramMb} MB', isDark),
                          _buildSpecRow(Icons.sd_storage_rounded, 'Storage', '${widget.plan.storageGb} GB NVMe', isDark),
                          _buildSpecRow(Icons.speed_rounded, 'CPU', '${widget.plan.cpuPercent}%', isDark),
                          _buildSpecRow(Icons.people_rounded, 'Players', '${widget.plan.maxPlayers} Slots', isDark),
                          if (widget.plan.databaseLimit > 0)
                            _buildSpecRow(Icons.dns_rounded, 'Databases', '${widget.plan.databaseLimit} Included', isDark),
                          if (widget.plan.backupLimit > 0)
                            _buildSpecRow(Icons.backup_rounded, 'Backups', '${widget.plan.backupLimit} Snapshots', isDark),

                          const SizedBox(height: 12),

                          // Features List
                          ...widget.plan.features.take(3).map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppTheme.accentAqua),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(f, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                                ),
                              ],
                            ),
                          )),

                          const SizedBox(height: 14),

                          // Action Buttons
                          Row(
                            children: [
                              // Add to Cart Button
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).addToCart(widget.plan);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${widget.plan.name} added to cart!'),
                                          backgroundColor: AppTheme.accentAqua,
                                          duration: const Duration(seconds: 1),
                                          action: SnackBarAction(
                                            label: 'View Cart',
                                            textColor: Colors.white,
                                            onPressed: () => context.push('/home/cart'),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(inCart ? Icons.check_circle : Icons.add_shopping_cart, size: 16),
                                    label: Text(inCart ? 'In Cart' : 'Add to Cart',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: inCart ? AppTheme.accentAqua : AppTheme.primaryPurple,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Details Button
                              SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryPurple,
                                    side: const BorderSide(color: AppTheme.primaryPurple),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Featured Badge
                    if (widget.plan.isFeatured)
                      Positioned(
                        top: 0,
                        right: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.accentAqua, Color(0xFF0284C7)]),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentAqua.withOpacity(0.4),
                                blurRadius: 8, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome, size: 11, color: Colors.white),
                              SizedBox(width: 4),
                              Text('POPULAR', style: TextStyle(
                                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                              )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppTheme.primaryPurple),
          ),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
