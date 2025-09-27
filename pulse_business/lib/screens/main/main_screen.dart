import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/deals_provider.dart';
import '../../utils/theme.dart';
import 'dashboard_tab.dart';
import 'create_deal_tab.dart';
import 'my_deals_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late TabController _tabController;

  final List<Widget> _pages = [
    const DashboardTab(),
    const CreateDealTab(),
    const MyDealsTab(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Create Deal',
    'My Deals',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      // Load business profile first
      await businessProvider.loadBusiness(authProvider.currentUser!.uid);
      
      // Then load deals if business exists
      if (businessProvider.currentBusiness != null) {
        await dealsProvider.loadDeals(businessProvider.currentBusiness!.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Business Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Help & Support'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _tabController.animateTo(index);
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create Deal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'My Deals',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              onPressed: () => _onTabTapped(1), // Navigate to Create Deal
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _tabController.animateTo(index);
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        _navigateToBusinessProfile();
        break;
      case 'analytics':
        _showAnalytics();
        break;
      case 'settings':
        _showSettings();
        break;
      case 'help':
        _showHelp();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _navigateToBusinessProfile() {
    // TODO: Navigate to business profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business profile feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAnalytics() {
    // TODO: Navigate to analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed analytics coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSettings() {
    // TODO: Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with Pulse Business?'),
            SizedBox(height: 16),
            Text('📧 Email: support@pulseapp.com'),
            Text('🌐 Website: www.pulseapp.com/help'),
            Text('📱 Phone: 1-800-PULSE-HELP'),
            SizedBox(height: 16),
            Text('Business Hours: Mon-Fri 9AM-6PM EST'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open email app or contact form
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildNotificationItem(
                icon: Icons.local_offer,
                title: 'Deal Performance Update',
                subtitle: 'Your "Coffee Special" deal has 5 new claims today!',
                time: '2 hours ago',
                isUnread: true,
              ),
              _buildNotificationItem(
                icon: Icons.schedule,
                title: 'Deal Expiring Soon',
                subtitle: 'Your "Lunch Combo" deal expires in 3 hours',
                time: '4 hours ago',
                isUnread: true,
              ),
              _buildNotificationItem(
                icon: Icons.star,
                title: 'New Review',
                subtitle: 'Someone left a 5-star review for your business!',
                time: '1 day ago',
                isUnread: false,
              ),
              _buildNotificationItem(
                icon: Icons.trending_up,
                title: 'Weekly Report Ready',
                subtitle: 'Your weekly performance report is available',
                time: '2 days ago',
                isUnread: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to full notifications screen
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isUnread 
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        child: Icon(
          icon,
          color: isUnread ? AppTheme.primaryColor : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      isThreeLine: true,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      trailing: isUnread 
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      final dealsProvider = Provider.of<DealsProvider>(context, listen: false);

      // Clear all data
      businessProvider.clearBusiness();
      dealsProvider.clearDeals();
      
      // Sign out
      await authProvider.signOut();

      // Navigation is handled by the router in main.dart
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}