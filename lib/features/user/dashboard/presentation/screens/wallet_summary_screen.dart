import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upi_pay/features/user/dashboard/data/mock/utility_cards.dart';
import 'package:upi_pay/features/user/dashboard/data/models/scheme.dart';
import 'package:upi_pay/features/user/dashboard/data/models/utility_card.dart';
import 'package:upi_pay/features/user/dashboard/presentation/providers/scheme_provider.dart';
import 'package:upi_pay/features/user/erupee-transaction/presentation/screens/erupee_screen.dart';

class WalletSummaryScreen extends ConsumerStatefulWidget {
  final int idx;
  const WalletSummaryScreen({super.key, required this.idx});

  @override
  ConsumerState<WalletSummaryScreen> createState() =>
      _WalletSummaryScreenState();
}

class _WalletSummaryScreenState extends ConsumerState<WalletSummaryScreen> {
  UtilityCard get utilityCard => utilityCards[widget.idx];

  SchemeModel? selectedScheme;
  double? selectedBalance;

  List<SchemeModel> schemesList = [];

  bool get isPersonalWallet => widget.idx == 1;
  bool get isSchemeWallet => widget.idx == 0;

  List<int> noteDenominations = [2000, 500, 200, 100, 50, 20, 10];

  List<int> calculateNotes(double balance) {
    List<int> notes = [];
    int amount = balance.round();
    for (int denom in noteDenominations) {
      while (amount >= denom) {
        notes.add(denom);
        amount -= denom;
      }
    }
    return notes;
  }

  @override
  void initState() {
    super.initState();
    if (schemesList.isEmpty) fetchSchemes();
  }

  Future<void> fetchSchemes() async {
    log('here');
    await ref.read(schemeNotifierProvider.notifier).fetchSchemes();
    final schemes = ref.read(schemeNotifierProvider);
    log(schemes.toString());
    if (schemes.isNotEmpty) {
      setState(() {
        schemesList = schemes;
      });
    }
  }

  Color getStatusColor(bool status) {
    switch (status) {
      case true:
        return Colors.green;
      case false:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceToShow =
        selectedScheme != null ? selectedScheme!.amount : utilityCard.remaining;
    final notes = balanceToShow != null ? calculateNotes(balanceToShow) : [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Wallet Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Wallet Card
          _buildWalletCard(context, balanceToShow),

          // Content Section
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  child:
                      isSchemeWallet
                          ? _buildSchemeWalletContent()
                          : _buildPersonalWalletContent(notes.cast<int>()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, double? balanceToShow) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isPersonalWallet
                  ? [Colors.indigo.shade800, Colors.indigo.shade500]
                  : [Colors.teal.shade800, Colors.teal.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                utilityCard.cardName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isPersonalWallet
                    ? Icons.account_balance_wallet
                    : Icons.card_giftcard,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            selectedScheme != null
                ? selectedScheme!.name
                : 'Available Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '₹${balanceToShow?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (isPersonalWallet)
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Last updated 2 hours ago',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSchemeWalletContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Schemes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Schemes Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: schemesList.length,
            itemBuilder: (context, index) {
              final scheme = schemesList[index];
              final isSelected = selectedScheme?.id == scheme.id;
              final statusColor = getStatusColor(scheme.eligible);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedScheme = scheme;
                    selectedBalance = scheme.amount;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.teal.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.teal.shade300
                              : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scheme.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? Colors.teal.shade700
                                        : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${scheme.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected
                                  ? Colors.teal.shade700
                                  : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Selected Scheme Details
          if (selectedScheme != null) ...[
            const Text(
              'Scheme Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Scheme description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedScheme!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(selectedScheme!.eligible),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedScheme!.eligible ? 'ELIGIBLE' : 'NOT ELIGIBLE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedScheme!.description,
                    style: TextStyle(color: Colors.teal.shade700),
                  ),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  // Eligibility criteria
                  Text(
                    'Eligibility Criteria',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Display eligibility criteria
                  _buildEligibilityCriteria(
                    selectedScheme!.eligibilityCriteria,
                  ),
                  
                  if (selectedScheme!.eligibilityCheck != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Your Eligibility Check',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEligibilityCheckResults(
                      selectedScheme!.eligibilityCheck!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Available Items
            const Text(
              'Available Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2, // For demo purpose; replace with actual data
              itemBuilder: (context, index) {
                final collections = [
                  {
                    'icon': Icons.rice_bowl,
                    'name': 'Rice',
                    'amount': 200,
                    'remaining': '5kg',
                  },
                  {
                    'icon': Icons.grass,
                    'name': 'Wheat',
                    'amount': 200,
                    'remaining': '10kg',
                  },
                ];
                final item = collections[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    title: Text(
                      item['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Remaining: ${item['remaining']}'),
                    trailing: Text(
                      '₹${item['amount']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibilityCriteria(EligibilityCriteria criteria) {
    final Map<String, dynamic> criteriaMap = {
      'Occupation': criteria.occupation,
      'Age Range': '${criteria.minAge} - ${criteria.maxAge} years',
      'Gender': criteria.gender,
      'State': criteria.state,
      'District': criteria.district,
      'City': criteria.city,
      'Caste': criteria.caste,
      'Annual Income': '≤ ₹${criteria.annualIncome}',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: criteriaMap.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(entry.value.toString()),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEligibilityCheckResults(EligibilityCheck check) {
    final checkResults = [
      {'name': 'Occupation', 'check': check.occupation},
      {'name': 'Gender', 'check': check.gender},
      {'name': 'Caste', 'check': check.caste},
      {'name': 'Annual Income', 'check': check.annualIncome},
      {'name': 'Age', 'check': check.age},
      {'name': 'State', 'check': check.state},
      {'name': 'District', 'check': check.district},
      {'name': 'City', 'check': check.city},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: checkResults.map((item) {
        final EligibilityCheckItem checkItem = item['check'] as EligibilityCheckItem;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '${item['name']}: ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text('${checkItem.actual}'),
                    const SizedBox(width: 8),
                    Icon(
                      checkItem.passed ? Icons.check_circle : Icons.cancel,
                      color: checkItem.passed ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonalWalletContent(List<int> notes) {
    // Group notes by denomination
    Map<int, int> noteCount = {};
    for (int note in notes) {
      noteCount[note] = (noteCount[note] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Notes visualization
          if (notes.isNotEmpty) ...[
            // Visual representation of notes
            SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < math.min(5, notes.length); i++)
                    Positioned(
                      left: 70 + (i * 10).toDouble(),
                      child: Transform.rotate(
                        angle: (i * 0.05) - 0.1,
                        child: Image.asset(
                          'assets/${notes[i]}-rupee.png',
                          height: 120,
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Note denomination breakdown
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: noteCount.length,
              itemBuilder: (context, index) {
                final denomination = noteCount.keys.elementAt(index);
                final count = noteCount[denomination] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹$denomination',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${count.toString()} note${count > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        '₹${(denomination * count).toString()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '₹${utilityCard.remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Empty state
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cash available',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Add Money Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoteCarouselScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Money',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}