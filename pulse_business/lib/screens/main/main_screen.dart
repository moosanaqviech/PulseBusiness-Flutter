// lib/screens/main/main_screen.dart - COMPLETE VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulse_business/screens/deal_creation/enhanced_deal_creation_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/deals_provider.dart';
import '../../utils/deep_link_handler.dart';
import '../../utils/theme.dart';
import 'dashboard_tab.dart';
import 'create_deal_tab.dart';
//import 'enhanced_create_deal_tab.dart';
import 'my_deals_tab.dart';
import '../qr_scanner/qr_scanner_tab.dart';
import 'settings_tab.dart';
import 'smart_templates_tab.dart'; // NEW

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
    const EnhancedDealCreationScreen(),    // ENHANCED - templates integration
    const QRScannerScreen(),               // EXISTING - Your scanner tab
    const MyDealsTab(),               // EXISTING
    const SettingsTab(),           // EXISTING
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
     DeepLinkHandler.initialize(context);
    
    // Check if business needs to complete profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBusinessProfile();
    });
  }

  void _checkBusinessProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
    
    // If user doesn't have business profile, redirect to setup
    if (authProvider.isAuthenticated && 
        !authProvider.currentUser!.hasBusinessProfile) {
      Navigator.pushReplacementNamed(context, '/business-setup');
    } else if (businessProvider.currentBusiness == null) {
    // Load business data if not already loaded
    businessProvider.loadBusiness(authProvider.currentUser!.uid).then((_) {
      // Load deals after business is loaded
      if (businessProvider.currentBusiness?.id != null) {
        dealsProvider.loadDeals(businessProvider.currentBusiness!.id!);
      }
    });
  } else {
    // Business already loaded, just load deals
    if (businessProvider.currentBusiness?.id != null) {
      dealsProvider.loadDeals(businessProvider.currentBusiness!.id!);
    }
  }
  }

  @override
  void dispose() {
    _pageController.dispose();
    DeepLinkHandler.dispose();
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
      //floatingActionButton: _buildFloatingActionButton(),
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
      
     
      
      case 2: // Scanner tab
        return [
          IconButton(
            onPressed: _showScannerHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Scanner Help',
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