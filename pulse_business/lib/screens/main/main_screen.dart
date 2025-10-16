// lib/screens/main/main_screen.dart - COMPLETE VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../utils/theme.dart';
import '../qr_scanner/qr_scanner_tab.dart';
import 'smart_templates_tab.dart';
import 'enhanced_create_deal_tab.dart';
import 'my_deals_tab.dart';
import '../settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Updated tab titles to include Smart Templates and Scanner
  final List<String> _titles = [
    'Smart Templates',  // NEW - replaces 'Dashboard'
    'Create Deal',
    'Scanner',          // EXISTING - QR Scanner
    'My Deals',
    'Settings',
  ];

  // Updated tab widgets
  final List<Widget> _tabs = [
    const SmartTemplatesTab(),        // NEW - replaces DashboardTab
    const EnhancedCreateDealTab(),    // ENHANCED - templates integration
    const QRScannerScreen(),               // EXISTING - Your scanner tab
    const MyDealsTab(),               // EXISTING
    const SettingsScreen(),           // EXISTING
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Check if business needs to complete profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBusinessProfile();
    });
  }

  void _checkBusinessProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    
    // If user doesn't have business profile, redirect to setup
    if (authProvider.isAuthenticated && 
        !authProvider.currentUser!.hasBusinessProfile) {
      Navigator.pushReplacementNamed(context, '/business-setup');
    } else if (businessProvider.currentBusiness == null) {
      // Load business data if not already loaded
      businessProvider.loadBusiness(authProvider.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        automaticallyImplyLeading: false,
        backgroundColor: _getAppBarColor(),
        foregroundColor: _getAppBarTextColor(),
        elevation: _currentIndex == 0 ? 0 : 1, // No elevation for Smart Templates tab
        actions: _buildAppBarActions(),
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, businessProvider, child) {
          if (businessProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your business...'),
                ],
              ),
            );
          }

          if (businessProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    businessProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      businessProvider.loadBusiness(authProvider.currentUser!.uid);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (businessProvider.currentBusiness == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_center,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Business profile not found'),
                  SizedBox(height: 8),
                  Text('Please complete your business setup'),
                ],
              ),
            );
          }

          return PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _tabs,
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Color _getAppBarColor() {
    switch (_currentIndex) {
      case 0: // Smart Templates
        return AppTheme.primaryColor;
      case 1: // Create Deal
        return Colors.green;
      case 2: // Scanner
        return Colors.purple;
      case 3: // My Deals
        return Colors.blue;
      case 4: // Settings
        return Colors.grey.shade800;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getAppBarTextColor() {
    return Colors.white;
  }

  List<Widget> _buildAppBarActions() {
    switch (_currentIndex) {
      case 0: // Smart Templates tab
        return [
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
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Template Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Template Help'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ];
      
      case 1: // Create Deal tab
        return [
          IconButton(
            onPressed: _showCreateDealHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ];
      
      case 2: // Scanner tab
        return [
          IconButton(
            onPressed: _showScannerHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Scanner Help',
          ),
        ];
      
      case 3: // My Deals tab
        return [
          IconButton(
            onPressed: _showDealFilters,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Deals',
          ),
          IconButton(
            onPressed: _showDealSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search Deals',
          ),
        ];
      
      default:
        return [
          IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
        ];
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome),
          label: 'Templates',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'My Deals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show quick create FAB on templates and my deals tabs
    if (_currentIndex == 0 || _currentIndex == 3) {
      return FloatingActionButton(
        onPressed: _quickCreateDeal,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Quick Create Deal',
      );
    }
    return null;
  }

  // Action handlers
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'analytics':
        Navigator.pushNamed(context, '/template-analytics');
        break;
      case 'help':
        _showTemplateHelp();
        break;
      case 'profile':
        Navigator.pushNamed(context, '/business-profile');
        break;
      case 'settings':
        setState(() {
          _currentIndex = 4;  // Updated index for settings tab
          _pageController.animateToPage(4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        });
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showTemplateHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Templates Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart Templates help you create high-performing deals:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('🎯 AI Recommendations - Get personalized suggestions based on your business data'),
              SizedBox(height: 8),
              Text('⚡ Quick Creation - Create professional deals in under 60 seconds'),
              SizedBox(height: 8),
              Text('📊 Performance Tracking - See which templates work best for you'),
              SizedBox(height: 8),
              Text('🔧 Smart Customization - Templates adapt to your business category'),
              SizedBox(height: 12),
              Text(
                'Tips for Success:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Start with recommended templates for best results'),
              SizedBox(height: 4),
              Text('• Customize prices to match your business model'),
              SizedBox(height: 4),
              Text('• Use seasonal templates during relevant periods'),
              SizedBox(height: 4),
              Text('• Check analytics to optimize future deals'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showCreateDealHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Deal Help'),
        content: const Text(
          'Choose between Smart Templates for proven performance or Custom Creation for full control. '
          'Templates typically perform 31% better than custom deals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showDealFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Deals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Deals'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle),
              title: const Text('Active Deals'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle),
              title: const Text('Paused Deals'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Expiring Soon'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDealSearch() {
    showSearch(
      context: context,
      delegate: DealSearchDelegate(),
    );
  }

  void _quickCreateDeal() {
    // Navigate to create deal tab with template selection
    setState(() {
      _currentIndex = 1;
      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    });
  }

  void _showScannerHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner Help'),
        content: const Text(
          'Use the scanner to verify deal redemptions by scanning customer QR codes. '
          'This helps track which deals have been claimed and used.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Simple search delegate for deals
class DealSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(
      child: Text('Search functionality coming soon!'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Start typing to search your deals...'),
    );
  }
}