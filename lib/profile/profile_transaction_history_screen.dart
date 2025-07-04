import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/Utils/SharedPrefrence.dart';
import 'package:reward_hub_customer/Utils/urls.dart';
import 'package:reward_hub_customer/provider/user_data_provider.dart';
import 'package:reward_hub_customer/store/model/customer_transaction_model.dart.dart';
import 'package:http/http.dart' as http;

class ProfileTransactionHistoryScreen extends StatefulWidget {
  @override
  State<ProfileTransactionHistoryScreen> createState() =>
      _ProfileTransactionHistoryScreenState();
}

class _ProfileTransactionHistoryScreenState
    extends State<ProfileTransactionHistoryScreen> {
  List<Transaction> transactions = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedFilter = 'Today';
  final List<String> _filterOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _updateDateRange('Today');
    fetchTransactions();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> fetchTransactions({bool loadMore = false}) async {
    if (loadMore) {
      _currentPage++;
      _isLoadingMore = true;
    } else {
      _currentPage = 1;
      _hasMoreData = true;
      transactions.clear();
    }

    try {
      if (!loadMore) {
        EasyLoading.show(
            dismissOnTap: false, maskType: EasyLoadingMaskType.black);
      }

      final token = Constants().token;
      final mobileNumber = SharedPrefrence().getCard();

      final newTransactions = await getCustomerTransactions(
        token,
        mobileNumber,
        pageNo: _currentPage,
      );

      // Check if we already have these transactions to prevent duplicates
      if (loadMore) {
        // For load more, only add transactions that don't already exist
        for (var transaction in newTransactions) {
          if (!transactions.any((t) => t.transDt == transaction.transDt)) {
            transactions.add(transaction);
          }
        }
      } else {
        // For initial load, just set the transactions
        transactions = newTransactions;
      }

      setState(() {
        _hasMoreData = newTransactions.length == 20;
      });
    } catch (error) {
      if (loadMore) {
        _currentPage--;
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
      if (!loadMore) {
        EasyLoading.dismiss();
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    await fetchTransactions(loadMore: true);
  }

  void _updateDateRange(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      switch (filter) {
        case 'Today':
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate = now;
          break;
        case 'Yesterday':
          _fromDate = DateTime(now.year, now.month, now.day - 1);
          _toDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          _fromDate = now.subtract(Duration(days: now.weekday - 1));
          _toDate = now;
          break;
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = now;
          break;
        case 'Last Month':
          final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
          _fromDate = firstDayLastMonth;
          _toDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 3 Months':
          _fromDate = DateTime(now.year, now.month - 3, now.day);
          _toDate = now;
          break;
        case 'Last 6 Months':
          _fromDate = DateTime(now.year, now.month - 6, now.day);
          _toDate = now;
          break;
        case 'Custom':
          _showDateRangePicker();
          return;
        default:
          _fromDate = null;
          _toDate = null;
      }
    });
    _currentPage = 1;
    _hasMoreData = true;
    fetchTransactions();
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(Duration(days: 30)),
              end: DateTime.now(),
            ),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _selectedFilter = 'Custom';
      });
      _currentPage = 1;
      _hasMoreData = true;
      fetchTransactions();
    }
  }

  Future<List<Transaction>> getCustomerTransactions(
    String token,
    String customerId, {
    int pageNo = 1,
  }) async {
    final url = Urls.getTransactions;
    final headers = {
      'Token': token,
      'customerId': SharedPrefrence().getCustomerId().toString(),
      'pageNo': pageNo.toString(),
      'pageSize': '20',
      'Content-Type': 'application/json',
    };
    if (_fromDate != null) {
      headers['fromDate'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
    }
    if (_toDate != null) {
      headers['toDate'] = DateFormat('yyyy-MM-dd').format(_toDate!);
    }
    final body = jsonEncode({'multiSelectArray': []});
    log('Headers: $headers');
    log('URL: $url');
    log('Body: $body');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      log('Response: ${response.body}, statusCode: ${response.statusCode}');
      if (response.statusCode == 200) {
        final model =
            CustomerTransactionModel.fromJson(json.decode(response.body));
        return model.data.transactions;
      } else {
        throw Exception(
            'Failed to load transactions. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print("Error getting transactions: $error");
      throw Exception('Failed to connect to the server: $error');
    }
  }

  Widget _buildLoader() {
    return _isLoadingMore
        ? Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Constants().appColor),
                strokeWidth: 2,
              ),
            ),
          )
        : SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate summary
    int totalTransactions = transactions.length;
    double totalCredited = transactions
        .where((t) => t.transType != 'Redemption')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0));
    double totalDebited = transactions
        .where((t) => t.transType == 'Redemption')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(44),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.blueGrey, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
          centerTitle: true,
          title: Text(
            'Transaction History',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
          actions: [SizedBox(width: 12)],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colorful, compact summary cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryCard(
                  label: 'Total',
                  value: totalTransactions.toString(),
                  icon: Icons.list_alt_rounded,
                  gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4A45B1)]),
                  iconBg: Colors.white,
                  valueColor: Colors.white,
                ),
                _SummaryCard(
                  label: 'Reward',
                  value: '+${totalCredited.toStringAsFixed(2)}',
                  icon: Icons.arrow_downward_rounded,
                  gradient: LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)]),
                  iconBg: Colors.white,
                  valueColor: Colors.white,
                ),
                _SummaryCard(
                  label: 'Redemption',
                  value: '-${totalDebited.toStringAsFixed(2)}',
                  icon: Icons.arrow_upward_rounded,
                  gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFE53935)]),
                  iconBg: Colors.white,
                  valueColor: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 10),
            // Compact filter area
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.06),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded, color: Colors.blue, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Filter:",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                      elevation: 12,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      underline: Container(),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateDateRange(newValue);
                        }
                      },
                      items: _filterOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedFilter.toLowerCase() == 'today' ||
                _selectedFilter.toLowerCase() == 'yesterday')
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  _fromDate != null
                      ? '${DateFormat('dd MMM yy').format(_fromDate!)}'
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  _fromDate != null && _toDate != null
                      ? '${DateFormat('dd MMM yy').format(_fromDate!)} - ${DateFormat('dd MMM yy').format(_toDate!)}'
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            SizedBox(height: 8),
            // Optimized transaction list
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No Transactions yet...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: transactions.length + (_hasMoreData ? 1 : 0),
                      separatorBuilder: (context, index) => SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        if (index >= transactions.length) {
                          return _buildLoader();
                        }
                        final transaction = transactions[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: transaction.transType == 'Reward'
                                    ? Color(0xFF00BFA5).withOpacity(0.1)
                                    : Color(0xFFFF6B6B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                transaction.transType == 'Reward'
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: transaction.transType == 'Reward'
                                    ? Color(0xFF00BFA5)
                                    : Color(0xFFFF6B6B),
                                size: 20,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.vendorName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        transaction.transDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${transaction.transType == 'Reward' ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: transaction.transType == 'Reward'
                                        ? Color(0xFF00BFA5)
                                        : Color(0xFFFF6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// More colorful, compact summary card
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Color iconBg;
  final Color valueColor;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.gradient,
      required this.iconBg,
      required this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(7),
              child: Icon(icon, color: gradient.colors.first, size: 20),
            ),
            SizedBox(height: 7),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: valueColor.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
