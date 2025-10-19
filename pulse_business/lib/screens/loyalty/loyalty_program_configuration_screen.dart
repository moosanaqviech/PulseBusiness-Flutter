// lib/screens/loyalty/loyalty_program_configuration_screen.dart - COMPLETE VERSION

/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loyalty_program_template.dart';
import '../../models/business.dart';
import '../../providers/business_provider.dart';
import '../../utils/theme.dart';

class LoyaltyProgramConfigurationScreen extends StatefulWidget {
  final LoyaltyProgram? existingProgram; // For editing existing programs
  
  const LoyaltyProgramConfigurationScreen({
    super.key,
    this.existingProgram,
  });

  @override
  State<LoyaltyProgramConfigurationScreen> createState() => _LoyaltyProgramConfigurationScreenState();
}

class _LoyaltyProgramConfigurationScreenState extends State<LoyaltyProgramConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isCreating = false;
  
  // Form controllers
  final _programNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsPerDollarController = TextEditingController();
  final _minimumPurchaseController = TextEditingController();
  final _welcomeBonusController = TextEditingController();
  final _birthdayBonusController = TextEditingController();
  final _pointExpiryController = TextEditingController();
  
  // Form data
  String? _selectedDoublePointsDay = 'none';
  List<LoyaltyReward> _rewards = [];
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _programNameController.dispose();
    _descriptionController.dispose();
    _pointsPerDollarController.dispose();
    _minimumPurchaseController.dispose();
    _welcomeBonusController.dispose();
    _birthdayBonusController.dispose();
    _pointExpiryController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (widget.existingProgram != null) {
      // Editing existing program
      final program = widget.existingProgram!;
      _programNameController.text = program.programName;
      _descriptionController.text = program.description ?? '';
      _pointsPerDollarController.text = program.pointsPerDollar.toString();
      _minimumPurchaseController.text = program.minimumPurchase.toStringAsFixed(2);
      _welcomeBonusController.text = program.welcomeBonus.toString();
      _birthdayBonusController.text = (program.birthdayBonus ?? 0).toString();
      _pointExpiryController.text = (program.pointExpiryMonths ?? 12).toString();
      _selectedDoublePointsDay = program.doublePointsDay ?? 'none';
      _rewards = List.from(program.rewards);
    } else {
      // New program with defaults
      _initializeWithDefaults();
    }
  }
  
  void _initializeWithDefaults() {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business != null) {
      _programNameController.text = '${business.name} Rewards';
      _pointsPerDollarController.text = '1';
      _minimumPurchaseController.text = '5.00';
      _welcomeBonusController.text = '50';
      _birthdayBonusController.text = '100';
      _pointExpiryController.text = '12';
      
      // Add default rewards based on business type
      _rewards = _getDefaultRewards(business);
    }
  }
  
  List<LoyaltyReward> _getDefaultRewards(Business business) {
    switch (business.category.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return [
          const LoyaltyReward(
            id: 'free_drink',
            name: 'Free Drink',
            description: 'Any soft drink or water',
            pointsCost: 25,
            rewardType: 'free_item',
            value: 2.50,
          ),
          const LoyaltyReward(
            id: 'free_appetizer',
            name: 'Free Appetizer',
            description: 'Choose from selected appetizers',
            pointsCost: 75,
            rewardType: 'free_item',
            value: 8.00,
          ),
          const LoyaltyReward(
            id: 'discount_10',
            name: '\$10 Off Next Order',
            description: 'Save \$10 on orders over \$25',
            pointsCost: 100,
            rewardType: 'discount',
            value: 10.00,
            restrictions: 'Minimum order \$25',
          ),
        ];
      
      case 'coffee':
      case 'cafe':
        return [
          const LoyaltyReward(
            id: 'free_coffee',
            name: 'Free Coffee',
            description: 'Any regular size coffee drink',
            pointsCost: 50,
            rewardType: 'free_item',
            value: 4.50,
          ),
          const LoyaltyReward(
            id: 'free_pastry',
            name: 'Free Pastry',
            description: 'Any pastry or baked good',
            pointsCost: 75,
            rewardType: 'free_item',
            value: 3.50,
          ),
        ];
      
      default:
        return [
          const LoyaltyReward(
            id: 'discount_5',
            name: '\$5 Off Purchase',
            description: 'Save \$5 on your next purchase',
            pointsCost: 50,
            rewardType: 'discount',
            value: 5.00,
          ),
          const LoyaltyReward(
            id: 'discount_10',
            name: '\$10 Off Purchase',
            description: 'Save \$10 on your next purchase',
            pointsCost: 100,
            rewardType: 'discount',
            value: 10.00,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProgram != null ? 'Edit Loyalty Program' : 'Create Loyalty Program',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildBasicSettingsPage(),
                _buildRewardsSetupPage(),
                _buildPreviewPage(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Setup', Icons.settings),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Rewards', Icons.card_giftcard),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Preview', Icons.preview),
        ],
      ),
    );
  }
  
  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentPage == step;
    final isCompleted = _currentPage > step;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? Colors.green 
                : isActive 
                    ? Colors.purple
                    : Colors.grey.shade300,
          ),
          child: Icon(
            icon,
            color: isCompleted || isActive ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.purple : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildProgressLine(int step) {
    final isCompleted = _currentPage > step;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildBasicSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎁 Loyalty Program Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the basic settings for your loyalty program',
              style: TextStyle(color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            
            // Program Details Section
            _buildSectionHeader('Program Details'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _programNameController,
              label: 'Program Name',
              hint: 'Mario\'s VIP Club',
              icon: Icons.star,
              validator: (value) => value?.isEmpty == true ? 'Program name is required' : null,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _descriptionController,
              label: 'Program Description (Optional)',
              hint: 'Earn points with every purchase and unlock exclusive rewards!',
              icon: Icons.description,
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Earning Structure Section
            _buildSectionHeader('Earning Structure'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _pointsPerDollarController,
                    label: 'Points per \$1',
                    icon: Icons.monetization_on,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final number = int.tryParse(value!);
                      if (number == null || number <= 0) return 'Must be positive';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCurrencyField(
                    controller: _minimumPurchaseController,
                    label: 'Min. Purchase',
                    icon: Icons.shopping_cart,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final number = double.tryParse(value!);
                      if (number == null || number < 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bonus Points Section
            _buildSectionHeader('Bonus Points'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _welcomeBonusController,
                    label: 'Welcome Bonus',
                    icon: Icons.card_giftcard,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final number = int.tryParse(value!);
                      if (number == null || number < 0) return 'Must be positive';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    controller: _birthdayBonusController,
                    label: 'Birthday Bonus',
                    icon: Icons.cake,
                    validator: (value) {
                      if (value?.isEmpty == true) return null; // Optional field
                      final number = int.tryParse(value!);
                      if (number == null || number < 0) return 'Must be positive';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Program Rules Section
            _buildSectionHeader('Program Rules'),
            const SizedBox(height: 16),
            
            _buildDropdownField(
              value: _selectedDoublePointsDay,
              label: 'Double Points Day',
              icon: Icons.calendar_today,
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No double points day')),
                DropdownMenuItem(value: 'monday', child: Text('Monday')),
                DropdownMenuItem(value: 'tuesday', child: Text('Tuesday')),
                DropdownMenuItem(value: 'wednesday', child: Text('Wednesday')),
                DropdownMenuItem(value: 'thursday', child: Text('Thursday')),
                DropdownMenuItem(value: 'friday', child: Text('Friday')),
                DropdownMenuItem(value: 'saturday', child: Text('Saturday')),
                DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
              ],
              onChanged: (value) => setState(() => _selectedDoublePointsDay = value),
            ),
            
            const SizedBox(height: 16),
            
            _buildNumberField(
              controller: _pointExpiryController,
              label: 'Points Expire After (Months)',
              hint: '0 = Never expire',
              icon: Icons.schedule,
              validator: (value) {
                if (value?.isEmpty == true) return null; // Optional
                final number = int.tryParse(value!);
                if (number == null || number < 0) return 'Must be positive or 0';
                return null;
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏅 Rewards Setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Create rewards that customers can redeem with their points',
            style: TextStyle(color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          
          // Rewards List
          if (_rewards.isEmpty)
            _buildEmptyRewardsState()
          else
            _buildRewardsList(),
          
          const SizedBox(height: 16),
          
          // Add Reward Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddRewardDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Reward'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Reward Tips
          _buildRewardTips(),
        ],
      ),
    );
  }

  Widget _buildRewardsList() {
    return Column(
      children: _rewards.asMap().entries.map((entry) {
        final index = entry.key;
        final reward = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildRewardCard(reward, index),
        );
      }).toList(),
    );
  }

  Widget _buildRewardCard(LoyaltyReward reward, int index) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    reward.rewardType == 'discount' ? Icons.local_offer : Icons.card_giftcard,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        reward.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showEditRewardDialog(reward, index);
                    } else if (action == 'delete') {
                      _deleteReward(index);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reward.pointsCost} points',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${reward.value.toStringAsFixed(2)} value',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (reward.restrictions != null) ...[
              const SizedBox(height: 8),
              Text(
                'Restrictions: ${reward.restrictions}',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRewardsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No rewards yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first reward to give customers something to work towards',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reward Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Start with small rewards (25-50 points) to encourage early engagement\n'
            '• Offer a mix of free items and discounts\n'
            '• Make your highest reward achievable but valuable (100-200 points)\n'
            '• Consider seasonal or limited-time rewards',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
            ),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPage() {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) {
      return const Center(child: Text('Business information not available'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👀 Program Preview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your loyalty program will appear to customers',
            style: TextStyle(color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          
          // Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade50, Colors.purple.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.purple, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _programNameController.text.isNotEmpty 
                            ? _programNameController.text 
                            : 'Your Loyalty Program',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _descriptionController.text,
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontSize: 16,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Program Benefits
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildBenefitRow(
                        Icons.monetization_on,
                        'Earn ${_pointsPerDollarController.text.isNotEmpty ? _pointsPerDollarController.text : '1'} point${int.tryParse(_pointsPerDollarController.text) != 1 ? 's' : ''} per \$1 spent',
                      ),
                      
                      if (_minimumPurchaseController.text.isNotEmpty && 
                          double.tryParse(_minimumPurchaseController.text) != null &&
                          double.parse(_minimumPurchaseController.text) > 0)
                        _buildBenefitRow(
                          Icons.shopping_cart,
                          'Minimum purchase: \$${_minimumPurchaseController.text}',
                        ),
                      
                      if (_welcomeBonusController.text.isNotEmpty && 
                          int.tryParse(_welcomeBonusController.text) != null &&
                          int.parse(_welcomeBonusController.text) > 0)
                        _buildBenefitRow(
                          Icons.card_giftcard,
                          'Welcome bonus: ${_welcomeBonusController.text} points',
                        ),
                      
                      if (_birthdayBonusController.text.isNotEmpty && 
                          int.tryParse(_birthdayBonusController.text) != null &&
                          int.parse(_birthdayBonusController.text) > 0)
                        _buildBenefitRow(
                          Icons.cake,
                          'Birthday bonus: ${_birthdayBonusController.text} points',
                        ),
                      
                      if (_selectedDoublePointsDay != null && _selectedDoublePointsDay != 'none')
                        _buildBenefitRow(
                          Icons.calendar_today,
                          'Double points every ${_selectedDoublePointsDay!.toUpperCase()}',
                        ),
                    ],
                  ),
                ),
                
                // Available Rewards
                if (_rewards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available rewards:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        
                        ..._rewards.take(3).map((reward) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                reward.rewardType == 'discount' 
                                    ? Icons.local_offer 
                                    : Icons.card_giftcard,
                                color: Colors.purple,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${reward.name} (${reward.pointsCost} points)',
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                        
                        if (_rewards.length > 3)
                          Text(
                            '+ ${_rewards.length - 3} more reward${_rewards.length - 3 > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Join Button (Preview)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // Disabled in preview
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Join Program',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Program Summary
          _buildProgramSummary(),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Summary',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          _buildSummaryRow('Total Rewards', '${_rewards.length}'),
          _buildSummaryRow('Point Value', '1 point = \${(1.0 / double.tryParse(_pointsPerDollarController.text.isNotEmpty ? _pointsPerDollarController.text : '1')!).toStringAsFixed(2)}'),
          _buildSummaryRow('Lowest Reward', _rewards.isEmpty ? 'None' : '${_rewards.map((r) => r.pointsCost).reduce((a, b) => a < b ? a : b)} points'),
          _buildSummaryRow('Highest Reward', _rewards.isEmpty ? 'None' : '${_rewards.map((r) => r.pointsCost).reduce((a, b) => a > b ? a : b)} points'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper methods for building form fields
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.purple,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: '\
                ,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousPage,
                child: const Text(
                  'Back',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isCreating ? null : _getNextButtonAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: _isCreating 
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  VoidCallback? _getNextButtonAction() {
    if (_isCreating) return null;
    
    switch (_currentPage) {
      case 0: // Basic settings
        return _validateBasicSettingsAndContinue;
      case 1: // Rewards setup
        return _goToPreview;
      case 2: // Preview
        return _createLoyaltyProgram;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Continue to Rewards';
      case 1:
        return 'Preview Program';
      case 2:
        return widget.existingProgram != null ? 'Update Program' : 'Create Program';
      default:
        return 'Next';
    }
  }

  void _validateBasicSettingsAndContinue() {
    if (_formKey.currentState?.validate() == true) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreview() {
    if (_rewards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one reward before continuing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showAddRewardDialog() {
    _showRewardDialog();
  }

  void _showEditRewardDialog(LoyaltyReward reward, int index) {
    _showRewardDialog(reward: reward, index: index);
  }

  void _showRewardDialog({LoyaltyReward? reward, int? index}) {
    final nameController = TextEditingController(text: reward?.name ?? '');
    final descriptionController = TextEditingController(text: reward?.description ?? '');
    final pointsController = TextEditingController(text: reward?.pointsCost.toString() ?? '');
    final valueController = TextEditingController(text: reward?.value.toStringAsFixed(2) ?? '');
    final restrictionsController = TextEditingController(text: reward?.restrictions ?? '');
    String selectedType = reward?.rewardType ?? 'free_item';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          reward != null ? 'Edit Reward' : 'Add New Reward',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Name',
                    hintText: 'Free Coffee',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Any regular size coffee drink',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: selectedType,
                  onChanged: (value) => setDialogState(() => selectedType = value!),
                  decoration: const InputDecoration(
                    labelText: 'Reward Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'free_item', child: Text('Free Item')),
                    DropdownMenuItem(value: 'discount', child: Text('Discount')),
                    DropdownMenuItem(value: 'service', child: Text('Free Service')),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Points Cost',
                          hintText: '50',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          hintText: '5.00',
                          prefixText: '\
                ,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: restrictionsController,
                  decoration: const InputDecoration(
                    labelText: 'Restrictions (Optional)',
                    hintText: 'Minimum order \$25',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final points = int.tryParse(pointsController.text);
              final value = double.tryParse(valueController.text);
              
              if (name.isEmpty || description.isEmpty || points == null || value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final newReward = LoyaltyReward(
                id: reward?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                description: description,
                pointsCost: points,
                rewardType: selectedType,
                value: value,
                restrictions: restrictionsController.text.trim().isNotEmpty 
                    ? restrictionsController.text.trim() 
                    : null,
              );
              
              setState(() {
                if (index != null) {
                  _rewards[index] = newReward;
                } else {
                  _rewards.add(newReward);
                }
              });
              
              Navigator.of(context).pop();
            },
            child: Text(reward != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteReward(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward'),
        content: Text(
          'Are you sure you want to delete "${_rewards[index].name}"?',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rewards.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _createLoyaltyProgram() async {
    if (!_formKey.currentState!.validate()) {
      _currentPage = 0;
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (_rewards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one reward'),
          backgroundColor: Colors.orange,
        ),
      );
      _currentPage = 1;
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      final business = businessProvider.currentBusiness;

      if (business == null) {
        throw Exception('Business information not available');
      }

      final loyaltyProgram = LoyaltyProgram(
        id: widget.existingProgram?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        businessId: business.id!,
        programName: _programNameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        pointsPerDollar: int.parse(_pointsPerDollarController.text),
        minimumPurchase: double.parse(_minimumPurchaseController.text),
        welcomeBonus: int.parse(_welcomeBonusController.text),
        birthdayBonus: _birthdayBonusController.text.isNotEmpty 
            ? int.parse(_birthdayBonusController.text) 
            : null,
        doublePointsDay: _selectedDoublePointsDay != 'none' 
            ? _selectedDoublePointsDay 
            : null,
        pointExpiryMonths: _pointExpiryController.text.isNotEmpty 
            ? int.parse(_pointExpiryController.text) 
            : null,
        rewards: _rewards,
        createdAt: widget.existingProgram?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Save to database
      // await loyaltyProgramService.saveLoyaltyProgram(loyaltyProgram);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingProgram != null 
                  ? 'Loyalty program updated successfully!' 
                  : 'Loyalty program created successfully!',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(loyaltyProgram);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating loyalty program: $e',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}*/