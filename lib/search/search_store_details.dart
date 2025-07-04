import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/Utils/urls.dart';
import 'package:reward_hub_customer/search/store_details.dart';
import 'package:reward_hub_customer/store/model/search_vendor_details.dart';

class SearchStoreDetailsScreen extends StatefulWidget {
  final String placeId;

  SearchStoreDetailsScreen({
    Key? key,
    required this.placeId,
  }) : super(key: key);

  @override
  State<SearchStoreDetailsScreen> createState() =>
      _SearchStoreDetailsScreenState();
}

TextEditingController _textEditingController = TextEditingController();
FocusNode _searchFocusNode = FocusNode();

class _SearchStoreDetailsScreenState extends State<SearchStoreDetailsScreen> {
  List<Vendor> stores = [];
  List<Vendor> filteredStorees = [];
  ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int pageNo = 1; // Track the current page number for all stores
  int pageSize = 20; // Number of items to load per page
  int filterpageNo = 1; // Track the page number for filtered results
  int filterpageCount = 20; // Number of filtered items per page
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    cleartextFeild();
    _scrollController.addListener(_scrollListener);
    print("Place ID:>>>${widget.placeId}");
    resetPageNo();
    loadStoresData();
  }

  Future<void> loadStoresData() async {
    try {
      EasyLoading.show(
        dismissOnTap: false,
        status: 'Please Wait...',
        maskType: EasyLoadingMaskType.black,
      );

      final result = await getApprovedVendors(
        token: Constants().token,
        pageNo: pageNo,
        pagecount: pageSize,
        placeId: int.parse(widget.placeId),
      );

      setState(() {
        stores.addAll(result.vendors);
        filteredStorees = stores; // Initialize filtered list with all stores
        pageNo++; // Increment the page number for the next load
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<PlaceSearchByVendorDetailsModel> getApprovedVendors({
    required String token,
    required int pageNo,
    required int pagecount,
    required int placeId,
  }) async {
    final String apiUrl = Urls.getApprovedVendorsByPlace;

    final Map<String, String> headers = {
      'Token': token,
      'pageno': pageNo.toString(),
      'pagecount': pagecount.toString(),
      'PlaceID': placeId.toString(),
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PlaceSearchByVendorDetailsModel.fromJson(data);
      } else {
        throw Exception('Failed to fetch data from API');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error occurred while making the API call');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_searchQuery.isEmpty) {
        // Load more stores if no search query
        loadStoresData();
      } else {
        // Load more filtered results
        _loadfilterMoreItems();
      }
    }
  }

  Future<PlaceSearchByVendorDetailsModel> getFilteredVendors({
    required String token,
    required int pageNo,
    required int pagecount,
    required String filterText,
    required int placeId,
  }) async {
    final String apiUrl = Urls.getFilteredApprovedSearchByPlaceId;

    final Map<String, String> headers = {
      'Token': token,
      'strPageNo': pageNo.toString(),
      'strPageCount': pagecount.toString(),
      'fltrText': filterText,
      'placeId': placeId.toString(),
    };
    print("Headers:>>>$headers");
    try {
      EasyLoading.show(
        status: 'Please wait...',
        dismissOnTap: true,
        maskType: EasyLoadingMaskType.black,
      );
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("Response data :>>>$data");
        return PlaceSearchByVendorDetailsModel.fromJson(data);
      } else {
        throw Exception('Failed to fetch data from API');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error occurred while making the API call');
    } finally {
      EasyLoading.dismiss();
    }
  }

  void onSearchIconClicked() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        filteredStorees = stores; // Reset to original list
      });
      return;
    }

    try {
      EasyLoading.show(
        status: 'Searching...',
        dismissOnTap: false,
        maskType: EasyLoadingMaskType.black,
      );

      resetPageNo();
      final searchResult = await getFilteredVendors(
        token: Constants().token,
        pageNo: filterpageNo,
        pagecount: filterpageCount,
        filterText: _searchQuery,
        placeId: int.parse(widget.placeId),
      );

      setState(() {
        filteredStorees = searchResult.vendors;
      });
    } catch (e) {
      print('Search error: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  void onSearchTextChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();

      if (_searchQuery.isEmpty) {
        // When search query is empty, show all stores
        filteredStorees = stores;
      } else {
        // Perform local filtering for immediate feedback
        filteredStorees = stores.where((vendor) {
          return vendor.vendorBusinessName
                  .toLowerCase()
                  .contains(_searchQuery) ||
              (vendor.vendorPlaceName.toLowerCase().contains(_searchQuery));
        }).toList();

        // Trigger API search after debounce
        _debounceSearch();
      }
    });
  }

  void _debounceSearch() {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Set a new timer to trigger API search after 500ms
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (_searchQuery.isNotEmpty) {
        resetPageNo();
        onSearchIconClicked();
      }
    });
  }

  void cleartextFeild() {
    _textEditingController.clear();
  }

  void resetPageNo() {
    filterpageNo = 1;
  }

  void _loadfilterMoreItems() async {
    filterpageNo++;
    try {
      final searchResult = await getFilteredVendors(
        token: Constants().token,
        pageNo: filterpageNo,
        pagecount: filterpageCount,
        filterText: _searchQuery,
        placeId: int.parse(widget.placeId),
      );

      if (mounted) {
        setState(() {
          filteredStorees.addAll(searchResult.vendors);
        });
      }
    } catch (e) {
      print('Error loading more items: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Image.asset(
            "assets/images/ic_back_img.png",
            height: 37.h,
            width: 37.w,
          ),
        ),
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          'Store List',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: TextFormField(
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: onSearchTextChanged,
                controller: _textEditingController,
                onFieldSubmitted: (value) {
                  resetPageNo();
                  onSearchIconClicked();
                  _searchFocusNode.unfocus();
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants().appColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants().appColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      if (_textEditingController.text.isNotEmpty) {
                        _textEditingController.clear();
                        onSearchTextChanged('');
                        _searchFocusNode.unfocus();
                      } else {
                        resetPageNo();
                        onSearchIconClicked();
                        _searchFocusNode.unfocus();
                      }
                    },
                    icon: Icon(
                      _textEditingController.text.isNotEmpty
                          ? Icons.close
                          : Icons.search,
                      color: Constants().appColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: filteredStorees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Stores Available",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              "Try a different search term",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredStorees.length,
                      itemBuilder: (context, index) {
                        final vendor = filteredStorees[index];
                        return GestureDetector(
                          onTap: () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: StoreDetails(storeList: vendor),
                                ),
                              );
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
                              child: Container(
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          vendor.vendorBusinessPicUrl1 == "null"
                                              ? Image.asset(
                                                  "assets/images/store.jpg",
                                                  fit: BoxFit.cover,
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: vendor
                                                      .vendorBusinessPicUrl1,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Image.asset(
                                                    "assets/images/store.jpg",
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
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vendor.vendorBusinessName,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            if (vendor
                                                .vendorPlaceName.isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 14.sp,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      vendor.vendorPlaceName,
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
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
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
