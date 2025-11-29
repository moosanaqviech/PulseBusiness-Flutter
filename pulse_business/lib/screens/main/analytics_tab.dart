// Enhanced Analytics Tab - Best of Both Worlds
// File: pulse_business/lib/screens/main/analytics_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/deals_provider.dart';
import '../../utils/theme.dart';
import '../../models/deal.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
  
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Consumer<DealsProvider>(
          builder: (context, dealsProvider, child) {
            if (dealsProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final deals = _filterDealsByPeriod(dealsProvider.allDeals, _selectedPeriod);
            
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildEnhancedQuickStats(deals),
                  const SizedBox(height: 20),
                  _buildViewsAndClaimsChart(), // NEW: Combined views + claims
                  const SizedBox(height: 20),
                  _buildRevenueBreakdown(deals), // From current version
                  const SizedBox(height: 20),
                  _buildTopPerformingDeals(deals), // Enhanced version
                  const SizedBox(height: 20),
                  _buildCustomerInsights(deals), // Enhanced insights
                  const SizedBox(height: 20),
                  _buildQuickActions(), // From current version
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Business Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
       
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedQuickStats(List<Deal> deals) {
    final totalRevenue = deals.fold(0.0, (sum, deal) => sum + (deal.claimCount * deal.dealPrice));
    final totalViews = deals.fold(0, (sum, deal) => sum + deal.viewCount);
    final totalClaims = deals.fold(0, (sum, deal) => sum + deal.claimCount);
    final activeDeals = deals.where((deal) => deal.isActive && !deal.isExpired && !deal.isSoldOut).length;
    final conversionRate = totalViews > 0 ? (totalClaims / totalViews) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // First row - Main metrics
        Row(
          children: [
            Expanded(child: _buildStatCard('Revenue', '\$${totalRevenue.toStringAsFixed(2)}', Colors.green, Icons.attach_money, _getGrowthText(totalRevenue))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Views', _formatNumber(totalViews), Colors.blue, Icons.visibility, _getViewsGrowthText(totalViews))),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - Performance metrics
        Row(
          children: [
            Expanded(child: _buildStatCard('Claims', _formatNumber(totalClaims), Colors.orange, Icons.shopping_cart, '$totalClaims sales')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Conversion', '${conversionRate.toStringAsFixed(1)}%', Colors.purple, Icons.trending_up, _getConversionText(conversionRate))),
          ],
        ),
        const SizedBox(height: 12),
        // Third row - Deal insights
        Row(
          children: [
            Expanded(child: _buildStatCard('Active Deals', '$activeDeals', Colors.teal, Icons.local_offer, '${deals.length} total')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Avg Deal Price', '\$${_calculateAvgDealPrice(deals)}', Colors.indigo, Icons.price_change, 'Market rate')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Combined Views and Claims Chart
  Widget _buildViewsAndClaimsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Views vs Claims Trend ($_selectedPeriod)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Legend
                
              ],
            ),
            const SizedBox(height: 12),
            Row(
                  children: [
                    _buildLegendItem('Views', Colors.blue),
                    const SizedBox(width: 12),
                    _buildLegendItem('Claims', Colors.green),
                  ],
                ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _getViewsAndClaimsData(_selectedPeriod),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                
                final data = snapshot.data;
                if (data == null || (data['views']!.every((d) => d['count'] == 0) && data['claims']!.every((d) => d['count'] == 0))) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No activity yet'),
                          Text('Chart will show views and claims as customers interact with your deals',
                               textAlign: TextAlign.center,
                               style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                
                return Container(
                  height: 200,
                  child: _buildDualBarChart(data['views']!, data['claims']!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDualBarChart(List<Map<String, dynamic>> viewsData, List<Map<String, dynamic>> claimsData) {
    final maxViews = viewsData.isNotEmpty 
        ? viewsData.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b)
        : 1;
    final maxClaims = claimsData.isNotEmpty 
        ? claimsData.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b)
        : 1;
    final maxValue = maxViews > maxClaims ? maxViews : maxClaims;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(viewsData.length, (index) {
                final views = viewsData[index]['count'] as int;
                final claims = claimsData[index]['count'] as int;
                final viewHeight = maxValue > 0 ? (views / maxValue * 120) : 0.0;
                final claimHeight = maxValue > 0 ? (claims / maxValue * 120) : 0.0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Counts on top
                        if (views > 0 || claims > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (views > 0) Text('$views', style: TextStyle(fontSize: 8, color: Colors.blue.shade700)),
                              if (views > 0 && claims > 0) const Text('/', style: TextStyle(fontSize: 8)),
                              if (claims > 0) Text('$claims', style: TextStyle(fontSize: 8, color: Colors.green.shade700)),
                            ],
                          ),
                        const SizedBox(height: 4),
                        // Bars
                        Row(
                          children: [
                            // Views bar
                            Expanded(
                              child: Container(
                                height: viewHeight > 0 ? viewHeight : 2,
                                margin: const EdgeInsets.only(right: 1),
                                decoration: BoxDecoration(
                                  color: views > 0 ? Colors.blue : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            // Claims bar
                            Expanded(
                              child: Container(
                                height: claimHeight > 0 ? claimHeight : 2,
                                margin: const EdgeInsets.only(left: 1),
                                decoration: BoxDecoration(
                                  color: claims > 0 ? Colors.green : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date label
                        Text(
                          viewsData[index]['label'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(List<Deal> deals) {
    final categoryRevenue = _calculateCategoryRevenue(deals);
    final totalRevenue = categoryRevenue.values.fold(0.0, (a, b) => a + b);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Revenue by Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'Total: \$${totalRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (categoryRevenue.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No revenue data yet'),
                ),
              )
            else
              ...categoryRevenue.entries.map((entry) {
                final percentage = totalRevenue > 0 ? (entry.value / totalRevenue * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 50,
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformingDeals(List<Deal> deals) {
    final sortedByRevenue = List<Deal>.from(deals)
      ..sort((a, b) => (b.claimCount * b.dealPrice).compareTo(a.claimCount * a.dealPrice));
    
    final topDeals = sortedByRevenue.where((deal) => 
      deal.claimCount > 0 || deal.viewCount > 0
    ).take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Top Performing Deals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topDeals.isEmpty)
              const Center(
                child: Text(
                  'No deal activity yet.\nCreate deals and track their performance here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...topDeals.asMap().entries.map((entry) {
                final index = entry.key;
                final deal = entry.value;
                return _buildEnhancedDealCard(deal, index + 1);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDealCard(Deal deal, int rank) {
    final revenue = deal.claimCount * deal.dealPrice;
    final conversionRate = deal.viewCount > 0 ? (deal.claimCount / deal.viewCount) * 100 : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank == 1 ? Colors.amber : 
                       rank == 2 ? Colors.grey[400] : 
                       rank == 3 ? Colors.brown[300] :
                       Colors.blue[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Deal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text('${deal.viewCount}', style: TextStyle(fontSize: 12, color: Colors.blue[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.shopping_cart, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text('${deal.claimCount}', style: TextStyle(fontSize: 12, color: Colors.green[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.trending_up, size: 14, color: Colors.purple[600]),
                    const SizedBox(width: 4),
                    Text('${conversionRate.toStringAsFixed(1)}%', 
                         style: TextStyle(fontSize: 12, color: Colors.purple[600])),
                  ],
                ),
              ],
            ),
          ),
          // Revenue
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${revenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
              Text(
                'revenue',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInsights(List<Deal> deals) {
    final insights = _calculateEnhancedInsights(deals);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Business Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Best Conversion',
                    '${insights['bestConversion']?.toStringAsFixed(1)}%',
                    'Highest performing deal',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    'Avg Order Value',
                    '\$${insights['avgOrderValue']?.toStringAsFixed(2)}',
                    'Customer spending avg',
                    Icons.attach_money,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Views per Deal',
                    '${insights['viewsPerDeal']?.toStringAsFixed(0)}',
                    'Average interest level',
                    Icons.visibility,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    'Active Rate',
                    '${insights['activeRate']?.toStringAsFixed(0)}%',
                    'Deals currently active',
                    Icons.local_offer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Create Deal',
                    Icons.add_circle,
                    Colors.green,
                    () => _navigateToCreateDeal(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Reports',
                    Icons.bar_chart,
                    Colors.blue,
                    () => _showDetailedReports(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Export Data',
                    Icons.download,
                    Colors.purple,
                    () => _exportData(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  List<Deal> _filterDealsByPeriod(List<Deal> deals, String period) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        return deals;
    }
    
    return deals.where((deal) => 
        deal.createdAt.isAfter(startDate) || 
        deal.createdAt.isAtSameMomentAs(startDate)
    ).toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getViewsAndClaimsData(String period) async {
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
    final deals = _filterDealsByPeriod(dealsProvider.allDeals, period);
    
    final views = <Map<String, dynamic>>[];
    final claims = <Map<String, dynamic>>[];
  
  // Generate time slots
  final timeSlots = _generateTimeSlots(period);
  
  // Initialize all slots with 0
  for (final slot in timeSlots) {
      views.add({'label': slot['label']!, 'count': 0});
      claims.add({'label': slot['label']!, 'count': 0});
  }
  
    // Only show actual totals in the most recent time slot if there's data
    final totalViews = deals.fold(0, (sum, deal) => sum + deal.viewCount);
    final totalClaims = deals.fold(0, (sum, deal) => sum + deal.claimCount);
    
    if (totalViews > 0 || totalClaims > 0) {
      // Put all real data in the most recent time slot
      final lastIndex = timeSlots.length - 1;
      if (lastIndex >= 0) {
        views[lastIndex]['count'] = totalViews;
        claims[lastIndex]['count'] = totalClaims;
    }
  }
  
    return {'views': views, 'claims': claims};
}

  List<Map<String, String>> _generateTimeSlots(String period) {
  final now = DateTime.now();
    final List<Map<String, String>> slots = [];
  
  switch (period) {
    case 'Today':
      for (int i = 5; i >= 0; i--) {
          final time = now.subtract(Duration(hours: i * 4));
          final label = '${time.hour.toString().padLeft(2, '0')}:00';
          slots.add({'label': label});
      }
      break;
      
    case 'This Week':
      for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
          slots.add({'label': label});
      }
      break;
      
    case 'This Month':
        for (int i = 3; i >= 0; i--) {
          final label = 'Week ${4 - i}';
          slots.add({'label': label});
      }
      break;
  }
  
  return slots;
}

  Map<String, double> _calculateCategoryRevenue(List<Deal> deals) {
    final Map<String, double> categoryRevenue = {};
    
    for (final deal in deals) {
      final revenue = deal.claimCount * deal.dealPrice;
      categoryRevenue[deal.category] = (categoryRevenue[deal.category] ?? 0) + revenue;
    }
    
    return categoryRevenue;
  }

  Map<String, double> _calculateEnhancedInsights(List<Deal> deals) {
    if (deals.isEmpty) {
      return {
        'bestConversion': 0.0,
        'avgOrderValue': 0.0,
        'viewsPerDeal': 0.0,
        'activeRate': 0.0,
      };
    }

    // Best conversion rate
    double bestConversion = 0.0;
    for (final deal in deals) {
      if (deal.viewCount > 0) {
        final conversion = (deal.claimCount / deal.viewCount) * 100;
        if (conversion > bestConversion) {
          bestConversion = conversion;
        }
      }
    }

    // Average order value
    final totalClaims = deals.fold(0, (sum, deal) => sum + deal.claimCount);
    final totalRevenue = deals.fold(0.0, (sum, deal) => sum + (deal.claimCount * deal.dealPrice));
    final avgOrderValue = totalClaims > 0 ? totalRevenue / totalClaims : 0.0;

    // Views per deal
    final totalViews = deals.fold(0, (sum, deal) => sum + deal.viewCount);
    final viewsPerDeal = totalViews / deals.length;

    // Active rate
    final activeDeals = deals.where((deal) => deal.isActive && !deal.isExpired && !deal.isSoldOut).length;
    final activeRate = (activeDeals / deals.length) * 100;

    return {
      'bestConversion': bestConversion,
      'avgOrderValue': avgOrderValue,
      'viewsPerDeal': viewsPerDeal,
      'activeRate': activeRate,
    };
  }

  Color _getCategoryColor(String category) {
    const Map<String, Color> categoryColors = {
      'restaurant': Colors.orange,
      'cafe': Colors.brown,
      'retail': Colors.purple,
      'service': Colors.blue,
      'entertainment': Colors.pink,
      'fitness': Colors.green,
      'food': Colors.red,
      'shopping': Colors.indigo,
      'beauty': Colors.purple,
      'automotive': Colors.blueGrey,
    };
    return categoryColors[category.toLowerCase()] ?? Colors.grey;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _calculateAvgDealPrice(List<Deal> deals) {
    if (deals.isEmpty) return '0.00';
    final avgPrice = deals.fold(0.0, (sum, deal) => sum + deal.dealPrice) / deals.length;
    return avgPrice.toStringAsFixed(2);
  }

  String _getGrowthText(double revenue) {
    // In a real app, you'd compare with previous period
    if (revenue > 100) return 'Strong';
    if (revenue > 50) return 'Good';
    if (revenue > 0) return 'Started';
    return 'No sales';
  }

  String _getViewsGrowthText(int views) {
    if (views > 100) return 'High';
    if (views > 50) return 'Growing';
    if (views > 0) return 'Some';
    return 'None';
  }

  String _getConversionText(double conversionRate) {
    if (conversionRate > 20) return 'Excellent';
    if (conversionRate > 10) return 'Good';
    if (conversionRate > 5) return 'Average';
    if (conversionRate > 0) return 'Low';
    return 'None';
  }

  Future<void> _refreshData() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);

    if (businessProvider.currentBusiness != null) {
      await dealsProvider.loadDeals(businessProvider.currentBusiness!.id!);
    }
  }

  void _navigateToCreateDeal() {
    DefaultTabController.of(context)?.animateTo(1);
  }

  void _showDetailedReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Reports'),
        content: const Text('Advanced analytics and reporting features are coming soon! This will include:\n\n• Customer demographics\n• Peak hours analysis\n• Seasonal trends\n• Competitor insights\n• Revenue forecasting'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: const Text('Choose the data format you want to export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon! Will support CSV, PDF, and Excel formats.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Export'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent activity:'),
            const SizedBox(height: 8),
            Text('• No new notifications', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            const Text('Coming soon:'),
            Text('• Deal performance alerts\n• Low stock warnings\n• Revenue milestones\n• Customer feedback', 
                 style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}