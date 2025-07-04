// ignore_for_file: avoid_print, unused_element, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/store/StoreDetailScreen.dart';
import 'package:reward_hub_customer/store/model/categories_m.dart';
import 'package:reward_hub_customer/wallet/store_categories.dart';
import '../Utils/toast_widget.dart';
import '../Utils/urls.dart';
import 'model/category_model.dart';
import 'model/filter_model.dart' as filter;
import 'model/search_town_model.dart';
import 'model/store_model.dart';
import 'model/vendor_model.dart';
import 'package:shimmer/shimmer.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StoreScreenState();
  }
}

class StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  var isSelectCategories = true;
  var isSelectStrores = false;
  List<CategoryModel> categoriesList = [];
  List<StoreModel> storesList = [];
  List<StoreModel> filteredStoresList = [];
  List<StoreModel> masterStoreList = [];
  List<Vendor> vendors = [];
  dynamic? selectedDistrictId;
  dynamic? selectedTownId;
  dynamic? selectedPlaceId;
  dynamic? selectedDistrictName;
  dynamic? selectedTownName;
  dynamic? selectedPlaceName;

  // Place filter variables
  List<PlaceModel> places = [];
  String? selectedPlaceIdFilter;
  String? selectedPlaceNameFilter;
  bool _isPlaceFilterActive = false;

  var pageNo = 1;
  var pageCount = 20;
  var filterpageNo = 1;
  var filterpageCount = 20;

  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  late final TabController _tabController;
  final TextEditingController _textEditingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  late final FocusNode _searchFocusNode;
  late Future<List<CategoriesM>> categoriesFuture;
  late filter.FilterVendorModel filterVendorModel = filter.FilterVendorModel();

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    categoriesFuture = fetchDataCategories();
    getStoreList(context);
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
    _scrollController.addListener(_scrollListenerForFilterStore);
    _tabController.addListener(() {
      onTabChanged();
    });
    _loadPlacesData();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreItems();
      }
    }
  }

  void _scrollListenerForFilterStore() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData && selectedPlaceIdFilter == null) {
        _loadfilterMoreItems();
      }
    }
  }

  void _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      pageNo++;
      final response =
          await getStoreList(context, pageNo: pageNo, pageCount: pageCount);

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            if (data['isSuccess'] == true) {
              List<StoreModel> newStores = parseStores(data['data']);

              // Filter out duplicates before adding new stores
              List<StoreModel> uniqueNewStores = newStores.where((newStore) {
                return !storesList
                    .any((existingStore) => existingStore.id == newStore.id);
              }).toList();

              if (uniqueNewStores.isNotEmpty) {
                storesList.addAll(uniqueNewStores);
                filteredStoresList = storesList;
                masterStoreList = storesList;
              }

              // Only set _hasMoreData to false if we received fewer items than requested
              // or if we received no new unique items
              _hasMoreData = newStores.length >= pageCount;
            } else {
              _hasMoreData = false;
            }
          } else {
            _hasMoreData = false;
          }
        });
      }
    } catch (error) {
      print('Error loading more items: $error');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadfilterMoreItems() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      filterpageNo++;
      final response = await getApprovedVendorsByfilter(
        Constants().token,
        filterpageNo,
        filterpageCount,
        _searchQuery,
      );

      if (mounted) {
        setState(() {
          if (response.data != null && response.data!.isNotEmpty) {
            filterVendorModel.data?.addAll(response.data!);
            _hasMoreData = response.data!.length >= filterpageCount;
          } else {
            _hasMoreData = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (error) {
      print('Error loading more items: $error');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<http.Response> getStoreList(BuildContext context,
      {bool reset = false,
      int pageNo = 1,
      int pageCount = 20,
      String? placeid = null}) async {
    try {
      if (reset) {
        storesList.clear();
        filteredStoresList.clear();
        masterStoreList.clear();
      }
      if (pageNo == 1) {
        setState(() {
          _isLoading = true;
        });
      }

      final Map<String, String> headers = {
        'Token': Constants().token,
        'pageNo': pageNo.toString(),
        'pageSize': pageCount.toString(),
        if (placeid != null) 'placeid': placeid.toString()
      };

      final response = await http.get(Uri.parse(Urls.stores), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        log("Response:----------->>> ${response.body}");

        if (data['isSuccess'] == true) {
          List<StoreModel> stores = parseStores(data['data']);
          if (mounted) {
            setState(() {
              if (pageNo == 1) {
                storesList = stores;
                filteredStoresList = stores;
                masterStoreList = stores;
              } else {
                storesList.addAll(stores);
                filteredStoresList = storesList;
                masterStoreList = storesList;
              }
              _hasMoreData = stores.length >= pageCount;
              _isLoading = false;
            });
          }
        } else {
          showErrorToast("No vendors found.");
        }
      } else {
        showErrorToast("No Stores...");
      }
      return response;
    } catch (error) {
      showErrorToast("No stores");
      log("an error occure:>>>> $error");
      return http.Response('Error', 500);
    } finally {
      if (mounted) {
        if (pageNo == 1) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Build method - Place filter active: $_isPlaceFilterActive, Tab index: ${_tabController.index}');
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "CATEGORIES & STORE",
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
              letterSpacing: 0.5),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isPlaceFilterActive &&
                  _tabController.index == 1
              ? 136
                  .h // TabBar (48) + Search bar (60) + Filter indicator (40) - 12 for padding
              : 96.h),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Constants().appColor.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
                child: TabBar(
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: Constants().appColor,
                      width: 3.0,
                    ),
                    insets: EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  unselectedLabelColor: Colors.grey[400],
                  labelColor: Constants().appColor,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Categories'),
                    Tab(text: 'Store'),
                  ],
                ),
              ),
              Container(
                height: 60.h,
                color: Colors.white,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: _searchFocusNode.hasFocus
                                ? Colors.white
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _searchFocusNode.hasFocus
                                  ? Constants().appColor
                                  : Colors.grey[300]!,
                              width: _searchFocusNode.hasFocus ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _searchFocusNode.hasFocus
                                    ? Constants().appColor.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            onFieldSubmitted: (value) {
                              if (value.isNotEmpty) {
                                onSearchTextChanged(value);
                              }
                              _searchFocusNode.unfocus();
                            },
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            onChanged: onSearchTextChanged,
                            controller: _textEditingController,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Color(0xFF2C2C2C),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search stores or categories...',
                              hintStyle: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: _searchFocusNode.hasFocus
                                      ? Constants().appColor
                                      : Colors.grey[400],
                                  size: 22.sp,
                                ),
                              ),
                              suffixIcon: _textEditingController.text.isNotEmpty
                                  ? Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: GestureDetector(
                                        onTap: () {
                                          _textEditingController.clear();
                                          onSearchTextChanged("");
                                          _searchFocusNode.unfocus();
                                          filterVendorModel.data = [];
                                          setState(() {});
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Colors.grey[600],
                                            size: 18.sp,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      // Filter button - only show on Store tab
                      if (_tabController.index == 1) ...[
                        SizedBox(width: 8.w),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: 48.h,
                          width: 48.w,
                          decoration: BoxDecoration(
                            color: _isPlaceFilterActive
                                ? Constants().appColor
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isPlaceFilterActive
                                  ? Constants().appColor
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isPlaceFilterActive
                                    ? Constants().appColor.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _showPlaceFilterBottomSheet(),
                              child: Icon(
                                Icons.tune_rounded,
                                color: _isPlaceFilterActive
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Place filter indicator - moved here from body
              if (_isPlaceFilterActive && _tabController.index == 1)
                Container(
                  width: double.infinity,
                  height: 40.h,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Constants().appColor.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: Constants().appColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16.sp,
                        color: Constants().appColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Filtered by: ${selectedPlaceNameFilter ?? ""}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Constants().appColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: _clearPlaceFilter,
                        child: Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: Constants().appColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: <Widget>[
          categoryList(),
          storeList(),
        ],
      ),
    );
  }

  Widget categoryList() {
    return FutureBuilder<List<CategoriesM>>(
        future: categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Constants().appColor),
                strokeWidth: 2.5,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No data available'),
            );
          } else {
            final filteredCategories = snapshot.data!
                .where((category) => category.vendorClassificationName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

            if (filteredCategories.isEmpty && _searchQuery.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No matching categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try different search terms',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                CategoriesM category = filteredCategories[index];
                return _buildCategoryCard(context, category);
              },
            );
          }
        });
  }

  Widget _buildCategoryCard(BuildContext context, CategoriesM category) {
    return GestureDetector(
      onTap: () {
        String selectedVendorClassificationId =
            category.vendorClassificationId.toString();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoreCategories(
              selectedVendorClassificationId: selectedVendorClassificationId,
              fromCategories: true,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: category.vendorClassificationImageUrl ?? "",
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Constants().appColor),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  "assets/images/shadow.png",
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Text(
                      category.vendorClassificationName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 100.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget storeList() {
    List<filter.Vendor> filteredVendors = filterVendorModel.data ?? [];

    if (_isLoading) {
      return GridView.builder(
        padding: EdgeInsets.all(12.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmerLoading(),
      );
    }

    if (_searchQuery.isNotEmpty && filteredVendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try different keywords or filters',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final bool isSearchMode = _searchQuery.isNotEmpty;
    final int itemCount =
        isSearchMode ? filteredVendors.length : storesList.length;
    final bool showLoadingMore =
        !isSearchMode && _hasMoreData && !_isLoadingMore;

    if (itemCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No stores available',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: itemCount + (showLoadingMore ? 1 : 0),
      itemBuilder: (BuildContext ctx, index) {
        if (index >= itemCount) {
          return _buildShimmerLoading();
        }

        if (isSearchMode) {
          if (index >= filteredVendors.length) {
            return _buildShimmerLoading();
          }
        } else {
          if (index >= storesList.length) {
            return _buildShimmerLoading();
          }
        }

        final String storeName = isSearchMode
            ? filteredVendors[index].vendorBusinessName ?? "Unknown Store"
            : storesList[index].name ?? "Unknown Store";
        final String imageUrl = isSearchMode
            ? filteredVendors[index].vendorBusinessPicUrl1 ?? ""
            : storesList[index].imageURL1 ?? "";
        final bool hasValidImage = imageUrl != "null" && imageUrl.isNotEmpty;

        return AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: 1.0,
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                if (isSearchMode && index < filteredVendors.length) {
                  final storeModel =
                      convertVendorToStoreModel(filterVendorModel.data![index]);
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: StoreDetailScreen(storeModel),
                    ),
                  );
                } else if (!isSearchMode && index < storesList.length) {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: StoreDetailScreen(storesList[index]),
                    ),
                  );
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: hasValidImage
                          ? CachedNetworkImage(
                              key: ValueKey(imageUrl),
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _buildShimmerLoading(),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported_rounded,
                                size: 35,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(
                              Icons.image_not_supported_rounded,
                              size: 35,
                              color: Colors.grey[400],
                            ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                storeName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      isSearchMode
                                          ? (filterVendorModel.data != null &&
                                                  index <
                                                      filterVendorModel
                                                          .data!.length
                                              ? filterVendorModel.data![index]
                                                      .vendorClassificationName ??
                                                  "Store"
                                              : "Store")
                                          : (index < storesList.length
                                              ? storesList[index]
                                                      .classificationName ??
                                                  "Store"
                                              : "Store"),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<filter.FilterVendorModel> getApprovedVendorsByfilter(
    String token,
    int pageNo,
    int pageCount,
    String filterText,
  ) async {
    final String apiUrl = Urls.stores;

    final Map<String, String> headers = {
      'Token': token,
      "pageNo": pageNo.toString(),
      "pageSize": pageCount.toString(),
      'fltrText': filterText,
    };
    late http.Response response;
    try {
      response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return filter.FilterVendorModel.fromJson(jsonResponse);
      } else {
        throw Exception('API call failed with status code ${response.body}');
      }
    } catch (error, stackTrace) {
      print('Error: $error');
      print('Stack trace: $stackTrace');
      print('Response body: ${response.body}');
      throw Exception('Error: $error');
    }
  }

  List<StoreModel> parseStores(List<dynamic> vendors) {
    return vendors.map<StoreModel>((obj) {
      return StoreModel(
        int.tryParse(obj['VendorId']?.toString() ?? '0') ?? 0,
        obj['VendorBusinessName']?.toString() ?? '',
        obj['VendorRegisteredMobileNumber']?.toString() ?? '',
        int.tryParse(obj['VendorClassificationID']?.toString() ?? '0') ?? 0,
        obj['VendorClassificationName']?.toString() ?? '',
        obj['VendorCategories']?.toString() ?? '',
        obj['VendorAddressL1']?.toString() ?? '',
        obj['VendorAddressL2']?.toString() ?? '',
        obj['VendorPinCode']?.toString() ?? '',
        obj['VendorGpslocation']?.toString() ?? '',
        obj['VendorBusinessPicUrl1']?.toString() ?? '',
        obj['VendorBusinessPicUrl2']?.toString() ?? '',
        obj['VendorBusinessPicUrl3']?.toString() ?? '',
        obj['VendorBusinessPicUrl4']?.toString() ?? '',
        obj['VendorBusinessPicUrl5']?.toString() ?? '',
        obj['VendorBusinessPicUrl6']?.toString() ?? '',
        int.tryParse(obj['VendorCountryId']?.toString() ?? '0') ?? 0,
        obj['VendorCountryName']?.toString() ?? '',
        int.tryParse(obj['VendorStateId']?.toString() ?? '0') ?? 0,
        obj['VendorStateName']?.toString() ?? '',
        int.tryParse(obj['VendorDistrictId']?.toString() ?? '0') ?? 0,
        obj['VendorDistrictName']?.toString() ?? '',
        int.tryParse(obj['VendorTownId']?.toString() ?? '0') ?? 0,
        obj['VendorTownName']?.toString() ?? '',
        int.tryParse(obj['VendorPlaceId']?.toString() ?? '0') ?? 0,
        obj['VendorPlaceName']?.toString() ?? '',
        obj['VendorBusinessDescription']?.toString() ?? '',
        obj['VendorRegisteredMobileNumber']?.toString() ?? '',
        obj['LandMark']?.toString() ?? '',
      );
    }).toList();
  }

  void showErrorToast(String message) {
    ToastWidget().showToastError(message);
  }

  void handleCategoryTap(String vendorClassificationId) {
    int classificationId = int.tryParse(vendorClassificationId) ?? 0;
    if (classificationId > 0) {
      List<StoreModel> filteredStores = masterStoreList
          .where(
              (store) => store.classificationID == classificationId.toString())
          .toList();

      if (filteredStores.isNotEmpty) {
        storesList = filteredStores;
      } else {
        // Handle the case where no stores match the selected category.
      }
    } else {
      storesList = masterStoreList;
    }
    _textEditingController.clear();
    onSearchTextChanged("");
    setState(() {});
  }

  // Load places data from API
  Future<void> _loadPlacesData() async {
    print('Loading places data...');
    try {
      final String token = Constants().token;
      final response = await http.get(
        Uri.parse(Urls.getPlaceData),
        headers: {'Token': token},
      );

      if (response.statusCode == 200) {
        final PlaceResponse placeResponse =
            placeResponseFromJson(response.body);
        if (placeResponse.isSuccess) {
          setState(() {
            places = placeResponse.data;
            places.sort((a, b) => a.placeName.compareTo(b.placeName));
          });
          print('Loaded ${places.length} places successfully');
        } else {
          print('Failed to load places: ${placeResponse.message}');
        }
      } else {
        print('Failed to load places: HTTP ${response.statusCode}');
      }
    } catch (error) {
      print('Error loading places: $error');
    }
  }

  // Show place filter bottom sheet
  void _showPlaceFilterBottomSheet() {
    final TextEditingController searchController = TextEditingController();
    List<PlaceModel> filteredPlaces = List.from(places);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20.h,
                ),
                // Header section with back button
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.grey[700],
                          size: 24.sp,
                        ),
                        padding: EdgeInsets.all(8.w),
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Select Location',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (_isPlaceFilterActive)
                        TextButton(
                          onPressed: _clearPlaceFilter,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Constants().appColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Search bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setModalState(() {
                        if (value.isEmpty) {
                          filteredPlaces = List.from(places);
                        } else {
                          filteredPlaces = places.where((place) {
                            return place.placeName
                                    .toLowerCase()
                                    .contains(value.toLowerCase()) ||
                                place.townName
                                    .toLowerCase()
                                    .contains(value.toLowerCase());
                          }).toList();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Constants().appColor,
                        size: 22.sp,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  filteredPlaces = List.from(places);
                                });
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.grey[600],
                                size: 20.sp,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h,
                      ),
                    ),
                  ),
                ),

                // Results info
                if (searchController.text.isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Text(
                      '${filteredPlaces.length} location${filteredPlaces.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Places list
                Expanded(
                  child: filteredPlaces.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (places.isEmpty) ...[
                                SizedBox(
                                  width: 24.w,
                                  height: 24.h,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Constants().appColor),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Loading locations...',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48.sp,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No locations found',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          itemCount: filteredPlaces.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 8.h),
                          itemBuilder: (context, index) {
                            final place = filteredPlaces[index];
                            final isSelected = selectedPlaceIdFilter ==
                                place.placeId.toString();

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _applyPlaceFilter(place.placeId.toString(),
                                      place.placeName);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 16.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Constants().appColor.withOpacity(0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: Constants()
                                                .appColor
                                                .withOpacity(0.2),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Constants()
                                                  .appColor
                                                  .withOpacity(0.15)
                                              : Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          color: Constants().appColor,
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.placeName,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Constants().appColor
                                                    : Colors.grey[900],
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              place.townName,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 20.w,
                                          height: 20.h,
                                          decoration: BoxDecoration(
                                            color: Constants().appColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14.sp,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Apply place filter
  void _applyPlaceFilter(String placeId, String placeName) {
    print('Applying place filter: $placeName (ID: $placeId)');
    print('Current tab index: ${_tabController.index}');
    print('Is place filter active: $_isPlaceFilterActive');

    setState(() {
      selectedPlaceIdFilter = placeId;
      selectedPlaceNameFilter = placeName;
      _isPlaceFilterActive = true;
      getStoreList(context, placeid: placeId);
      // Filter stores by place - only on Store tab
      // if (_tabController.index == 1) {
      //   print('Filtering stores for Store tab');
      //   print('Master store list length: ${masterStoreList.length}');

      //   if (_searchQuery.isNotEmpty) {
      //     // If there's a search query, filter the search results by place
      //     print('Filtering search results by place');
      //     filterVendorModel.data = filterVendorModel.data?.where((vendor) {
      //       return vendor.vendorplaceName?.toString() == placeName;
      //     }).toList();
      //     print(
      //         'Filtered search results length: ${filterVendorModel.data?.length ?? 0}');
      //   } else {
      //     // Filter master store list by place
      //     print('Filtering master store list by place');
      //     filteredStoresList = masterStoreList.where((store) {
      //       bool matches = store.placeName == placeName ||
      //           store.placeID.toString() == placeId;
      //       print(
      //           'Store: ${store.name}, Place: ${store.placeName}, PlaceID: ${store.placeID}, Matches: $matches');
      //       return matches;
      //     }).toList();
      //     // storesList = filteredStoresList;
      //     print('Filtered stores length: ${filteredStoresList.length}');
      //   }
      // }
    });
    print('Place filter applied successfully');
  }

  // Clear place filter
  void _clearPlaceFilter() {
    setState(() {
      selectedPlaceIdFilter = null;
      selectedPlaceNameFilter = null;
      _isPlaceFilterActive = false;
      getStoreList(context);
      // Reset store list - only on Store tab
      if (_tabController.index == 1) {
        if (_searchQuery.isNotEmpty) {
          // Reload search results without place filter
          _performSearch();
        } else {
          // Reset to master store list
          storesList = masterStoreList;
          filteredStoresList = masterStoreList;
        }
      }
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadAllStores() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await getStoreList(context, reset: true);
    } catch (error) {
      print('Error loading stores: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<CategoriesM>> getVendorClassifications() async {
    final String token = Constants().token;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Token': token,
    };

    try {
      final response = await http.get(
        Uri.parse(Urls.categories),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<CategoriesM> categoriesList =
            data.map((e) => CategoriesM.fromJson(e)).toList();
        return categoriesList;
      } else {
        throw Exception('Failed to load vendor classifications');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Widget filterStoreList() {
    return ListView.builder(
      itemCount: filterVendorModel.data?.length ?? 0,
      itemBuilder: (context, index) {
        filter.Vendor vendor = filterVendorModel.data![index];
        return ListTile(
          title: Text(vendor.vendorBusinessName),
        );
      },
    );
  }

  void onTabChanged() {
    _searchFocusNode.unfocus();
    _textEditingController.clear();
    onSearchTextChanged("");

    if (_tabController.index == 0) {
      // Categories tab - place filter not shown but keep state
      filterVendorModel.data = [];
      if (mounted) {
        setState(() {});
      }
    } else if (_tabController.index == 1) {
      // Store tab - apply place filter if it was active
      loadAllStores().then((_) {
        if (_isPlaceFilterActive &&
            selectedPlaceIdFilter != null &&
            selectedPlaceNameFilter != null) {
          _applyPlaceFilter(selectedPlaceIdFilter!, selectedPlaceNameFilter!);
        }
      });
    }
    // Force UI update to show/hide filter button
    if (mounted) {
      setState(() {});
    }
  }

  void onSearchTextChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
      if (_searchQuery.isEmpty) {
        // If no search query, apply place filter if active on Store tab
        if (_isPlaceFilterActive && _tabController.index == 1) {
          filteredStoresList = masterStoreList.where((store) {
            return store.placeName == selectedPlaceNameFilter ||
                store.placeID.toString() == selectedPlaceIdFilter;
          }).toList();
          storesList = filteredStoresList;
        } else {
          storesList = masterStoreList;
        }
        filterVendorModel.data = [];
      } else {
        if (_tabController.index == 0) {
          storesList = masterStoreList
              .where((store) =>
                  store.name.toLowerCase().contains(_searchQuery) ||
                  store.classificationName.toLowerCase().contains(_searchQuery))
              .toList();
        } else {
          _performSearch();
        }
      }
    });
  }

  Future<void> _performSearch() async {
    try {
      filterVendorModel = await getApprovedVendorsByfilter(
        Constants().token,
        1,
        100, // Load all results at once
        _searchQuery,
      );

      // Apply place filter to search results if active on Store tab
      if (_isPlaceFilterActive &&
          _tabController.index == 1 &&
          filterVendorModel.data != null) {
        filterVendorModel.data = filterVendorModel.data!.where((vendor) {
          return vendor.vendorplaceName?.toString() == selectedPlaceNameFilter;
        }).toList();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      print('Search error: $error');
    }
  }

  Future<List<CategoriesM>> fetchDataCategories() async {
    try {
      List<CategoriesM> categoriesList1 = await getVendorClassifications();
      return categoriesList1;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  StoreModel convertVendorToStoreModel(filter.Vendor vendor) {
    return StoreModel(
        vendor.vendorId,
        vendor.vendorBusinessName,
        vendor.vendorRegisteredMobileNumber.toString(),
        vendor.vendorClassificationId,
        vendor.vendorClassificationName,
        vendor.vendorCategories,
        vendor.vendorAddressL1,
        vendor.vendorAddressL2,
        vendor.vendorPinCode.toString(),
        vendor.vendorGpsLocation,
        vendor.vendorBusinessPicUrl1,
        vendor.vendorBusinessPicUrl2?.toString() ?? "",
        vendor.vendorBusinessPicUrl3?.toString() ?? "",
        vendor.vendorBusinessPicUrl4?.toString() ?? "",
        vendor.vendorBusinessPicUrl5?.toString() ?? "",
        "", // imageURL6 is not present in Vendor model
        0, // countryID not present
        "", // countryName not present
        0, // stateID not present
        "", // stateName not present
        0, // districtID not present
        vendor.vendordistrictName?.toString() ?? "",
        0, // townID not present
        vendor.vendorTownName?.toString() ?? "",
        0, // placeID not present
        vendor.vendorplaceName?.toString() ?? "",
        vendor.vendorBusinessDescription,
        vendor.vendorRegisteredMobileNumber.toString(),
        vendor.landMark);
  }
}
