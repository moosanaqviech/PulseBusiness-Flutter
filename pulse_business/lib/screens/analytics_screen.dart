// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/deals_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last 30 Days'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => _periods.map((period) => 
              PopupMenuItem(value: period, child: Text(period))
            ).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Deals'),
            Tab(text: 'Revenue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDealsTab(),
          _buildRevenueTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<DealsProvider>(
      builder: (context, dealsProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodHeader(),
              const SizedBox(height: 16),
              _buildMetricsGrid(dealsProvider),
              const SizedBox(height: 24),
              _buildChartSection(),
              const SizedBox(height: 24),
              _buildTopPerformingDeals(dealsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDealsTab() {
    return Consumer<DealsProvider>(
      builder: (context, dealsProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodHeader(),
              const SizedBox(height: 16),
              _buildDealMetrics(dealsProvider),
              const SizedBox(height: 24),
              _buildDealPerformanceList(dealsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 16),
          _buildRevenueMetrics(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildRevenueBreakdown(),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              _selectedPeriod,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              _getDateRange(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(DealsProvider dealsProvider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2, // ✅ FIXED: Reduced from 1.5 to 1.2 for more height
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Views',
          NumberFormat.compact().format(dealsProvider.totalViews),
          Icons.visibility,
          Colors.blue,
          '+12%',
        ),
        _buildMetricCard(
          'Total Claims',
          NumberFormat.compact().format(dealsProvider.totalClaims),
          Icons.shopping_cart,
          Colors.green,
          '+8%',
        ),
        _buildMetricCard(
          'Active Deals',
          '${dealsProvider.totalActiveDeals}',
          Icons.local_offer,
          Colors.orange,
          '+2',
        ),
        _buildMetricCard(
          'Revenue',
          '\$${_calculateRevenue(dealsProvider)}',
          Icons.attach_money,
          Colors.purple,
          '+15%',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String change) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12), // ✅ FIXED: Reduced padding from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ FIXED: Added proper alignment
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18), // ✅ FIXED: Reduced icon size from 20 to 18
                const Spacer(),
                Text(
                  change,
                  style: TextStyle(
                    color: change.startsWith('+') ? Colors.green : Colors.red,
                    fontSize: 11, // ✅ FIXED: Reduced font size from 12 to 11
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // ✅ FIXED: Reduced spacing from 8 to 4
            Text(
              value,
              style: const TextStyle(
                fontSize: 20, // ✅ FIXED: Reduced font size from 24 to 20
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11, // ✅ FIXED: Reduced font size from 12 to 11
              ),
              maxLines: 1, // ✅ FIXED: Added maxLines to prevent overflow
              overflow: TextOverflow.ellipsis, // ✅ FIXED: Added ellipsis for long text
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Views vs Claims',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Chart visualization coming soon'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformingDeals(DealsProvider dealsProvider) {
    final deals = dealsProvider.allDeals.take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performing Deals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...deals.map((deal) => _buildDealListItem(deal)).toList(),
            if (deals.isEmpty) 
              const Center(
                child: Text(
                  'No deals available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealMetrics(DealsProvider dealsProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactMetricCard(
            'Avg. Views',
            '${(dealsProvider.totalViews / (dealsProvider.allDeals.length > 0 ? dealsProvider.allDeals.length : 1)).round()}',
            Icons.trending_up,
            Colors.blue,
            '+5%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCompactMetricCard(
            'Conversion',
            '${_calculateConversionRate(dealsProvider)}%',
            Icons.percent,
            Colors.green,
            '+2%',
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetricCard(String title, String value, IconData icon, Color color, String change) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const Spacer(),
                Text(
                  change,
                  style: TextStyle(
                    color: change.startsWith('+') ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealPerformanceList(DealsProvider dealsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deal Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...dealsProvider.allDeals.map((deal) => _buildDetailedDealItem(deal)).toList(),
            if (dealsProvider.allDeals.isEmpty)
              const Center(
                child: Text(
                  'No deals available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetrics() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2, // ✅ FIXED: Same adjustment as main metrics
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard('Total Revenue', '\$1,250', Icons.attach_money, Colors.green, '+15%'),
        _buildMetricCard('Avg. Order', '\$25.50', Icons.receipt, Colors.blue, '+3%'),
        _buildMetricCard('Transactions', '49', Icons.payment, Colors.orange, '+7'),
        _buildMetricCard('Profit Margin', '23%', Icons.trending_up, Colors.purple, '+2%'),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Revenue chart coming soon'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRevenueItem('Deal Sales', '\$1,050', '84%', Colors.green),
            _buildRevenueItem('Service Fees', '\$150', '12%', Colors.blue),
            _buildRevenueItem('Other', '\$50', '4%', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String category, String amount, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Text(category),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            percentage,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDealListItem(deal) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(deal.title),
      subtitle: Text('${deal.viewCount} views • ${deal.claimCount} claims'),
      trailing: Text(
        '\$${(deal.claimCount * deal.dealPrice).toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailedDealItem(deal) {
    final conversionRate = deal.viewCount > 0 ? (deal.claimCount / deal.viewCount * 100) : 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deal.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMiniMetric('Views', '${deal.viewCount}', Colors.blue),
                _buildMiniMetric('Claims', '${deal.claimCount}', Colors.green),
                _buildMiniMetric('Conv.', '${conversionRate.toStringAsFixed(1)}%', Colors.orange),
                _buildMiniMetric('Revenue', '\$${(deal.claimCount * deal.dealPrice).toStringAsFixed(0)}', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateFormat('MMM d, y').format(now);
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(now)}';
      case 'This Month':
        return DateFormat('MMMM y').format(now);
      default:
        return DateFormat('MMM d, y').format(now);
    }
  }

  String _calculateRevenue(DealsProvider dealsProvider) {
    double total = 0;
    for (final deal in dealsProvider.allDeals) {
      total += deal.claimCount * deal.dealPrice;
    }
    return total.toStringAsFixed(0);
  }

  double _calculateConversionRate(DealsProvider dealsProvider) {
    if (dealsProvider.totalViews == 0) return 0;
    return (dealsProvider.totalClaims / dealsProvider.totalViews * 100);
  }
}