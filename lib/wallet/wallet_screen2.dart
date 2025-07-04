import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:reward_hub_customer/Utils/SharedPrefrence.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/Utils/permission_function.dart';
import 'package:reward_hub_customer/Utils/toast_widget.dart';
import 'package:reward_hub_customer/Utils/urls.dart';
import 'package:reward_hub_customer/profile/profile_screen.dart';
import 'package:reward_hub_customer/provider/user_data_provider.dart';
import 'package:reward_hub_customer/store/model/category_model.dart';
import 'package:reward_hub_customer/store/model/customer_transaction_model.dart.dart';
import 'package:reward_hub_customer/store/model/store_model.dart';
import 'package:reward_hub_customer/store/model/user_model.dart';
import 'package:reward_hub_customer/wallet/api_serviece.dart';
import 'package:reward_hub_customer/wallet/store_categories.dart';

class WalletScreen2 extends StatefulWidget {
  const WalletScreen2({super.key});

  @override
  State<WalletScreen2> createState() => _WalletScreen2State();
}

class _WalletScreen2State extends State<WalletScreen2>
    with TickerProviderStateMixin {
  var recentTransactionList = [];
  List<CategoryModel> categoriesList = [];
  List<StoreModel> storesList = [];
  List<StoreModel> masterStoreList = [];

  bool isImageClicked = false;
  late AnimationController _controller;

  UserModel? userModel;
  String balance = "";
  DateTime? currentBackPressTime;

  List<Transaction> transactions = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedFilter = 'Today';
  final List<String> _filterOptions = [
    // 'All',
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'Custom'
  ];
  bool _showInfoPopup = false;

  @override
  void initState() {
    super.initState();
    requestAllPermissions();
    getCategoryList(context);
    _updateDateRange('Today');
    fetchTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserDetails();
    });
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _scrollController.addListener(_scrollListener);

    Provider.of<UserData>(context, listen: false)
        .setUserProfilePhotoData(SharedPrefrence().getUserProfilePhoto());
  }

  @override
  void dispose() {
    _controller.dispose();
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

  Future<void> fetchUserDetails() async {
    try {
      final UserModel? user = await UserApiService().getUserDetails(
          Constants().token, SharedPrefrence().getUserPhone().toString());
      SharedPrefrence().setCustomerId(user!.customerID.toString());

      if (user != null) {
        SharedPrefrence().setCustomerId(user.customerID.toString());
        setState(() {
          balance = user.walletbalance.toString();
          userModel = user;
        });

        Provider.of<UserData>(context, listen: false).updateUserModel(user);
      }
    } catch (e) {
      print("Error fetching user details: ${e.toString()}");
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

  // Add this new method to handle date range changes
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
        default: // 'All'
          _fromDate = null;
          _toDate = null;
      }
    });

    // Reset pagination and reload transactions
    _currentPage = 1;
    _hasMoreData = true;
    fetchTransactions();
  }

  // Add this method to show date picker for custom range
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

      // Reset pagination and reload transactions
      _currentPage = 1;
      _hasMoreData = true;
      fetchTransactions();
    }
  }

  Future<List<Transaction>> getCustomerTransactions(
    String token,
    String customerId, {
    int pageNo = 1,
    // DateTime? fromDate,
    // DateTime? toDate,
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

    final body = jsonEncode({
      'multiSelectArray': [],
    });

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
        // Changed from transactionModelFromJson to parse single object
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
    final String? cardRenewalDate = userModel?.cardRenewalDate != null
        ? DateFormat('MM/yyyy').format(userModel!.cardRenewalDate)
        : null;

    final num? walletBalance = userModel?.walletbalance;
    final num? minRedemptionAmount = userModel?.minRedemptionAmount;
    final num v1 = (walletBalance ?? 0) - (minRedemptionAmount ?? 0);
    num v2 = v1 * 0.2;
    num v3 = (v1 - v2) <= 0 ? 0 : (v1 - v2);
    final formattedAmount = NumberFormat('#,##0.00').format(v3);

    return WillPopScope(
      onWillPop: () async {
        if (currentBackPressTime == null ||
            DateTime.now().difference(currentBackPressTime!) >
                Duration(seconds: 1)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          currentBackPressTime = DateTime.now();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Constants().bgGrayColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 0,
                      child: SizedBox(
                        height: 40.h,
                        width: 40.w,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          "DASHBOARD",
                          style: TextStyle(
                            color: Color(0xFF2C2C2C),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 0,
                      child: Padding(
                        padding: EdgeInsets.only(right: 16.w, top: 10.h),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProfileScreen()));
                          },
                          child: Consumer<UserData>(
                            builder: (context, userData, _) {
                              String profilePhotoPath =
                                  SharedPrefrence().getUserProfilePhoto();
                              File profilePhotoFile = File(profilePhotoPath);
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: profilePhotoFile.existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(25)),
                                        child: Image.file(
                                          profilePhotoFile,
                                          height: 40.h,
                                          width: 40.w,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        height: 40.h,
                                        width: 40.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[200],
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: Constants().appColor,
                                          size: 24,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              FlipCard(
                key: cardKey,
                direction: FlipDirection.VERTICAL,
                front: Stack(
                  children: [
                    Container(
                      height: 220.h,
                      width: 340.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Constants().appColor.withOpacity(0.15),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage("assets/images/card_front.png"),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 28.0.w, top: 66.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 5.w),
                                  child: Consumer<UserData>(
                                    builder: (context, userData, _) {
                                      return SizedBox(
                                        width: 160.w,
                                        child: Text(
                                          "${SharedPrefrence().getUsername()}",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                          softWrap: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Padding(
                                  padding: EdgeInsets.only(left: 5.w),
                                  child: Text(
                                    SharedPrefrence().getCard(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Consumer<UserData>(
                                  builder: (context, userData, _) {
                                    final balance =
                                        userData.userModel?.walletbalance ??
                                            0.0;
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 5.w),
                                        Text(
                                          "Total Rewards",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          NumberFormat('#,##0.00')
                                              .format(balance),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showInfoPopup = true;
                                            });
                                          },
                                          child: Icon(Icons.info_outline,
                                              color: Colors.white, size: 18),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 30.w,
                            bottom: 120.0.h,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Expiry Date",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  cardRenewalDate ?? "",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showInfoPopup)
                            Positioned.fill(
                              child: AnimatedOpacity(
                                opacity: 1.0,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                          "assets/images/card_front.png"),
                                      fit: BoxFit.fill,
                                      colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.85),
                                          BlendMode.darken),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: IconButton(
                                          icon: Icon(Icons.close,
                                              color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              _showInfoPopup = false;
                                            });
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 48),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: Consumer<UserData>(
                                                  builder:
                                                      (context, userData, _) {
                                                    final balance = userData
                                                            .userModel
                                                            ?.walletbalance ??
                                                        0.0;
                                                    final possibleRedemption =
                                                        balance > 200
                                                            ? balance * 0.8
                                                            : 0.0;
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                                'Current Balance:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15.sp,
                                                                    color: Colors
                                                                        .white)),
                                                            Text(
                                                                '₹${NumberFormat('#,##0.00').format(balance)}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16.sp,
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          ],
                                                        ),
                                                        SizedBox(height: 10),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                                'Possible Redemption:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15.sp,
                                                                    color: Colors
                                                                        .white)),
                                                            Text(
                                                                '₹${NumberFormat('#,##0.00').format(possibleRedemption)}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16.sp,
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          ],
                                                        ),
                                                        SizedBox(height: 10),
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              EdgeInsets.all(
                                                                  10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.orange
                                                                .withOpacity(
                                                                    0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                  color: Colors
                                                                      .orange,
                                                                  size: 20),
                                                              SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  'Minimum redemption balance: ₹${NumberFormat('#,##0.00').format(userData.userModel?.minRedemptionAmount ?? 0)}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                              .orange[
                                                                          200],
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_showInfoPopup)
                      Positioned(
                        bottom: 42.h,
                        right: 40.w,
                        child: GestureDetector(
                          onTap: () {
                            cardKey.currentState!.toggleCard();
                          },
                          child: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              padding: EdgeInsets.all(4),
                              data: SharedPrefrence().getCard(),
                              version: QrVersions.auto,
                              size: 70,
                              gapless: false,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                back: Container(
                  height: 220.h,
                  width: 340.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage("assets/images/Group.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      height: 160.h,
                      width: 160.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: SharedPrefrence().getCard(),
                        version: QrVersions.auto,
                        size: 150.h,
                        gapless: false,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Constants().appColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding:
                          EdgeInsets.only(top: 30.0.h, right: 20.w, left: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Store Categories",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Color(0xFF2C2C2C),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            height: 100.h,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: categoriesList.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    String selectedVendorClassificationId =
                                        categoriesList[index].id;
                                    Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => StoreCategories(
                                            selectedVendorClassificationId:
                                                selectedVendorClassificationId)));
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: 8.w,
                                      right: 8.w,
                                    ),
                                    height: 70.h,
                                    width: 110.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Constants()
                                              .appColor
                                              .withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                      image: categoriesList[index].imageUrl ==
                                              "null"
                                          ? const DecorationImage(
                                              image: AssetImage(
                                                  "assets/images/shadow.png"),
                                              fit: BoxFit.cover,
                                            )
                                          : DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                categoriesList[index].imageUrl,
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Text(
                                            categoriesList[index]
                                                .name
                                                .toString(),
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Text(
                                "Recent Transactions",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: Constants().appColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedFilter,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: Constants().appColor),
                                  elevation: 16,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Color(0xFF2C2C2C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  underline: Container(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _updateDateRange(newValue);
                                    }
                                  },
                                  items: _filterOptions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w),
                                        child: Text(value),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedFilter.toLowerCase() == 'today' ||
                              _selectedFilter.toLowerCase() == 'yesterday')
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                '${DateFormat('dd MMM yy').format(_fromDate!)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C2C2C).withOpacity(0.6),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                _fromDate != null && _toDate != null
                                    ? '${DateFormat('dd MMM yy').format(_fromDate!)} - ${DateFormat('dd MMM yy').format(_toDate!)}'
                                    : '',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C2C2C).withOpacity(0.6),
                                ),
                              ),
                            ),
                          SizedBox(height: 16.h),
                          transactions.isEmpty
                              ? Container(
                                  height: 200.h,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'No Transactions yet...',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: transactions.length +
                                      (_hasMoreData ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= transactions.length) {
                                      return _buildLoader();
                                    }

                                    final transaction = transactions[index];
                                    Color valueColor =
                                        transaction.transType == 'Redemption'
                                            ? Colors.red
                                            : Colors.green;

                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Constants()
                                                .appColor
                                                .withOpacity(0.03),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16.w, vertical: 8.h),
                                        leading: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: valueColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            transaction.transType ==
                                                    'Redemption'
                                                ? Icons.remove_circle_outline
                                                : Icons.add_circle_outline,
                                            color: valueColor,
                                            size: 20,
                                          ),
                                        ),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction.transType,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              transaction.vendorName,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF2C2C2C)
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            transaction.transDate,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF2C2C2C)
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        trailing: Text(
                                          transaction.amount.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: valueColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getCategoryList(BuildContext context) async {
    try {
      EasyLoading.show(
          dismissOnTap: false, maskType: EasyLoadingMaskType.black);
      final request = http.MultipartRequest("GET", Uri.parse(Urls.categories));

      request.headers.addAll({
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Token': Constants().token
      });

      var response = await request.send();
      var responsed = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        categoriesList.clear();
        List<dynamic> value = json.decode(responsed.body);

        EasyLoading.dismiss();
        for (int i = 0; i < value.length; i++) {
          var obj = value[i];
          categoriesList.add(CategoryModel(
              obj['vendorClassificationId'].toString(),
              obj['vendorClassificationName'].toString(),
              obj['vendorClassificationImageURL'].toString()));
        }
        if (mounted) {
          setState(() {});
        }
      } else {
        Map<String, dynamic> value = json.decode(responsed.body);
        EasyLoading.dismiss();
        ToastWidget().showToastError(value['message'].toString());
      }
    } catch (e, stackTrace) {
      print("Error getting categories: ${e.toString()}");
      print(stackTrace.toString());
    }
  }
}
