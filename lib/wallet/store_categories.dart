import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/Utils/urls.dart';
import 'package:reward_hub_customer/store/model/search_town_model.dart';
import 'package:reward_hub_customer/wallet/wallet_store_details.dart';
import 'package:reward_hub_customer/wallet/wallet_store_model.dart';
import 'package:shimmer/shimmer.dart';

class StoreCategories extends StatefulWidget {
  final String selectedVendorClassificationId;
  final bool? fromCategories;

  const StoreCategories({
    super.key,
    required this.selectedVendorClassificationId,
    this.fromCategories,
  });

  @override
  State<StoreCategories> createState() => _StoreCategoriesState();
}

class _StoreCategoriesState extends State<StoreCategories> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Vendor> vendorsList = [];
  List<Vendor> filteredVendorsList = [];
  List<Vendor> masterVendorsList = [];
  bool isLoading = false;

  // Place filter variables
  List<PlaceModel> places = [];
  String? selectedPlaceIdFilter;
  String? selectedPlaceNameFilter;
  bool _isPlaceFilterActive = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadPlacesData();
  }

  void filterStores(String query) {
    setState(() {
      List<Vendor> baseList = _isPlaceFilterActive
          ? masterVendorsList
              .where(
                  (vendor) => vendor.vendorPlaceName == selectedPlaceNameFilter)
              .toList()
          : masterVendorsList;

      if (query.isEmpty) {
        filteredVendorsList = baseList;
        vendorsList = baseList;
      } else {
        filteredVendorsList = baseList
            .where((store) =>
                store.vendorBusinessName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                store.vendorCategories
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
      filteredVendorsList
          .sort((a, b) => a.vendorBusinessName.compareTo(b.vendorBusinessName));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20.sp, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store List',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _textEditingController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onChanged: filterStores,
                        decoration: InputDecoration(
                          hintText: 'Search stores...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Constants().appColor,
                            size: 22.sp,
                          ),
                          suffixIcon: _textEditingController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _textEditingController.clear();
                                    filterStores('');
                                    _searchFocusNode.unfocus();
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: Constants().appColor,
                                    size: 22.sp,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Constants().appColor,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Filter button
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      height: 48.h,
                      width: 48.w,
                      decoration: BoxDecoration(
                        color: _isPlaceFilterActive
                            ? Constants().appColor
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
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
                ),
              ],
            ),
          ),
          // Place filter indicator
          if (_isPlaceFilterActive)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: Constants().appColor.withOpacity(0.1),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearPlaceFilter,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
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
          Expanded(
            child: filteredVendorsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_mall_directory_outlined,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          "No Stores Available",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16.w),
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredVendorsList.length,
                    itemBuilder: (context, index) {
                      final store = filteredVendorsList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: WalletStoreDetails(storeList: store),
                            ),
                          );
                          filterStores('');
                          _searchFocusNode.unfocus();
                          _textEditingController.clear();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: store.vendorBusinessPicUrl1,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
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
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store.vendorBusinessName,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        // textAlign: TextAlign.center,
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_outlined,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            size: 10.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            store.vendorClassificationName,
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ],
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
    );
  }

  Future<void> fetchData() async {
    try {
      setState(() => isLoading = true);
      EasyLoading.show(
        dismissOnTap: false,
        status: 'Loading stores...',
        maskType: EasyLoadingMaskType.black,
      );

      final walletStoreModel = await getApprovedVendors(
        token: Constants().token,
        pageNo: 1,
        pageCount: 20000,
        classificationID: widget.selectedVendorClassificationId,
        context: context,
      );

      if (mounted && walletStoreModel.vendors.isNotEmpty) {
        setState(() {
          vendorsList = walletStoreModel.vendors;
          filteredVendorsList = vendorsList;
          masterVendorsList = vendorsList;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false);
      EasyLoading.dismiss();
    }
  }

  Future<WalletStoreModel> getApprovedVendors({
    required BuildContext context,
    required String token,
    required int pageNo,
    required int pageCount,
    required String classificationID,
  }) async {
    final Uri apiUrl = Uri.parse(Urls.storesbyCalssification);
    final headers = {
      'Token': token,
      'pageno': pageNo.toString(),
      'pagecount': pageCount.toString(),
      'ClassificationID': classificationID,
    };

    try {
      final response = await http.get(apiUrl, headers: headers);
      final responseData = json.decode(response.body);

      if (responseData['transactionStatus'] == true) {
        return WalletStoreModel.fromJson(responseData);
      } else {
        return WalletStoreModel(
          transactionStatus: false,
          totalRecords: 0,
          vendors: [],
        );
      }
    } catch (error) {
      throw Exception('Error occurred: $error');
    }
  }

  // Load places data from API
  Future<void> _loadPlacesData() async {
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
        }
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
                  height: 30.h,
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
  // void _showPlaceFilterBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => Container(
  //       height: MediaQuery.of(context).size.height * 0.6,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       child: Column(
  //         children: [
  //           // Handle bar
  //           Container(
  //             margin: EdgeInsets.only(top: 8.h),
  //             width: 40.w,
  //             height: 4.h,
  //             decoration: BoxDecoration(
  //               color: Colors.grey[300],
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           // Header
  //           Padding(
  //             padding: EdgeInsets.all(16.w),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(
  //                   'Filter by Place',
  //                   style: TextStyle(
  //                     fontSize: 18.sp,
  //                     fontWeight: FontWeight.bold,
  //                     color: Color(0xFF2C2C2C),
  //                   ),
  //                 ),
  //                 if (_isPlaceFilterActive)
  //                   TextButton(
  //                     onPressed: _clearPlaceFilter,
  //                     child: Text(
  //                       'Clear',
  //                       style: TextStyle(
  //                         color: Constants().appColor,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //           Divider(height: 1),
  //           // Places list
  //           Expanded(
  //             child: places.isEmpty
  //                 ? Center(
  //                     child: CircularProgressIndicator(
  //                       valueColor:
  //                           AlwaysStoppedAnimation<Color>(Constants().appColor),
  //                     ),
  //                   )
  //                 : ListView.builder(
  //                     itemCount: places.length,
  //                     itemBuilder: (context, index) {
  //                       final place = places[index];
  //                       final isSelected =
  //                           selectedPlaceIdFilter == place.placeId.toString();

  //                       return ListTile(
  //                         title: Text(
  //                           place.placeName,
  //                           style: TextStyle(
  //                             fontSize: 16.sp,
  //                             fontWeight: isSelected
  //                                 ? FontWeight.w600
  //                                 : FontWeight.w400,
  //                             color: isSelected
  //                                 ? Constants().appColor
  //                                 : Color(0xFF2C2C2C),
  //                           ),
  //                         ),
  //                         subtitle: Text(
  //                           place.townName,
  //                           style: TextStyle(
  //                             fontSize: 14.sp,
  //                             color: Colors.grey[600],
  //                           ),
  //                         ),
  //                         trailing: isSelected
  //                             ? Icon(
  //                                 Icons.check_circle,
  //                                 color: Constants().appColor,
  //                                 size: 24.sp,
  //                               )
  //                             : null,
  //                         onTap: () {
  //                           _applyPlaceFilter(
  //                               place.placeId.toString(), place.placeName);
  //                           Navigator.pop(context);
  //                         },
  //                       );
  //                     },
  //                   ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Apply place filter
  void _applyPlaceFilter(String placeId, String placeName) {
    setState(() {
      selectedPlaceIdFilter = placeId;
      selectedPlaceNameFilter = placeName;
      _isPlaceFilterActive = true;

      // Filter vendors by place
      if (_textEditingController.text.isNotEmpty) {
        // If there's a search query, filter the current filtered list by place
        filteredVendorsList = filteredVendorsList.where((vendor) {
          return vendor.vendorPlaceName == placeName;
        }).toList();
      } else {
        // Filter master vendor list by place
        filteredVendorsList = masterVendorsList.where((vendor) {
          return vendor.vendorPlaceName == placeName;
        }).toList();
        vendorsList = filteredVendorsList;
      }
    });
  }

  // Clear place filter
  void _clearPlaceFilter() {
    setState(() {
      selectedPlaceIdFilter = null;
      selectedPlaceNameFilter = null;
      _isPlaceFilterActive = false;

      // Reset vendor list
      if (_textEditingController.text.isNotEmpty) {
        // If there's a search query, reapply search without place filter
        filterStores(_textEditingController.text);
      } else {
        // Reset to master vendor list
        vendorsList = masterVendorsList;
        filteredVendorsList = masterVendorsList;
      }
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
