// ignore_for_file: avoid_print, unused_element, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/search/AdvancedSearchFilterScreen.dart';
import 'package:reward_hub_customer/store/StoreDetailScreen.dart';
import 'package:reward_hub_customer/store/model/categories_m.dart';
import 'package:reward_hub_customer/wallet/store_categories.dart';
import '../Utils/toast_widget.dart';
import '../Utils/urls.dart';
import 'model/category_model.dart';
import 'model/filter_model.dart' as filter;
import 'model/store_model.dart';
import 'model/vendor_model.dart';

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

  var pageNo = 1;
  var pageCount = 20;
  var filterpageNo = 1;
  var filterpageCount = 20;

  String _searchQuery = '';

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
    // fetchData();
    categoriesFuture = fetchDataCategories();
    getStoreList(context);
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
    _scrollController.addListener(_scrollListenerForFilterStore);
    _tabController.addListener(() {
      onTabChanged();
    });
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

  void onTabChanged() {
    _searchFocusNode.unfocus();
    _textEditingController.clear();
    onSearchTextChanged("");

    if (_tabController.index == 0) {
      filterVendorModel.data = [];
      filterpageNo = 1;
      if (mounted) {
        setState(() {});
      }
    } else if (_tabController.index == 1) {
      loadAllStores();
    }
  }

  void resetPageNo() {
    filterpageNo = 1;
  }

  void _scrollListenerForFilterStore() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _loadfilterMoreItems();
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _loadMoreItems();
      });
    }
  }

  void _loadMoreItems() {
    pageNo++;

    getStoreList(context, pageNo: pageNo, pageCount: pageCount)
        .then((response) {});
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
      EasyLoading.show(status: 'Please wait...', dismissOnTap: true);
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
    } finally {
      EasyLoading.dismiss();
    }
  }

  void fetchData() async {
    String token = Constants().token;
    try {
      filter.FilterVendorModel filterVendorModel =
          await getApprovedVendorsByfilter(
              token, pageNo, pageCount, _searchQuery);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void onSearchIconClicked() async {
    if (_tabController.index == 1) {
      filterVendorModel = await getApprovedVendorsByfilter(
          Constants().token, filterpageNo, filterpageCount, _searchQuery);
      if (mounted) {
        setState(() {});
      }
    }
    fetchData();
  }

  void _loadfilterMoreItems() {
    filterpageNo++;

    getApprovedVendorsByfilter(
      Constants().token,
      filterpageNo,
      filterpageCount,
      _searchQuery,
    ).then((filterVendorResponse) {
      if (mounted) {
        setState(() {
          filterVendorModel.data?.addAll(filterVendorResponse.data ?? []);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "CATEGORIES & STORE",
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(96.h),
          child: Column(
            children: [
              TabBar(
                indicatorColor: Constants().appColor,
                unselectedLabelColor: Colors.grey,
                labelColor: Colors.black,
                controller: _tabController,
                tabs: [
                  Tab(text: 'Categories'),
                  Tab(text: 'Store'),
                ],
              ),
              Container(
                height: 60.h,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50.h,
                          child: TextFormField(
                            onFieldSubmitted: (value) {
                              resetPageNo();
                              onSearchIconClicked();
                              _searchFocusNode.unfocus();
                              if (_textEditingController.text.isEmpty) {
                                filterVendorModel.data = [];
                              }
                            },
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            onChanged: onSearchTextChanged,
                            controller: _textEditingController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Constants().appColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Constants().appColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              suffixIcon: _tabController.index == 1
                                  ? GestureDetector(
                                      onTap: () {
                                        resetPageNo();
                                        onSearchIconClicked();
                                        _searchFocusNode.unfocus();
                                        if (_textEditingController
                                            .text.isEmpty) {
                                          filterVendorModel.data = [];
                                        }
                                      },
                                      child: Icon(
                                        Icons.search,
                                        color: Constants().appColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
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

  //Fahal
  void _navigateToAdvancedSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedSearchFilterScreen(
          selectedDistrictId: selectedDistrictId,
          selectedTownId: selectedTownId,
          selectedPlaceId: selectedPlaceId,
          selectedDistrictName: selectedDistrictName,
          selectedTownName: selectedTownName,
          selectedPlaceName: selectedPlaceName,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      // Ensure data is correctly structured
      if (result['data'] != null && result['data'] is Map<String, dynamic>) {
        // Assuming the stores list is within the 'data' map
        Map<String, dynamic> data = result['data'];

        // Access and parse the stores list from the 'data' map
        if (data.containsKey('data') && data['data'] is List) {
          List<StoreModel> stores = parseStores(data['data']);
          log("Stores:>>>|||>>:$stores");
          if (mounted) {
            setState(() {
              // Clear the existing stores and repopulate them
              storesList.clear();
              filteredStoresList.clear();
              masterStoreList.clear();

              storesList.addAll(stores);
              filteredStoresList = storesList;
              masterStoreList = storesList;

              // Update the selected filters
              selectedDistrictId = result['selectedDistrictId'];
              selectedTownId = result['selectedTownId'];
              selectedPlaceId = result['selectedPlaceId'];
              selectedDistrictName = result['selectedDistrictName'];
              selectedTownName = result['selectedTownName'];
              selectedPlaceName = result['selectedPlaceName'];
            });

            // Debugging information to ensure everything is working as expected
            print("Stores list updated: ${stores.length} stores loaded");
            print("Selected District ID: $selectedDistrictId");
            print("Selected Town ID: $selectedTownId");
            print("Selected Place ID: $selectedPlaceId");
            print("Selected District  Name: $selectedDistrictName");
            print("Selected Town Name: $selectedTownName");
            print("Selected Place Name: $selectedPlaceName");
          }
        } else {
          print("Error: No stores found in the data map");
        }
      } else {
        print("Error: result['data'] is null or not a Map<String, dynamic>");
      }
    } else {
      print("Error: result is null or not a Map<String, dynamic>");
    }
  }

  // Widget categoryList() {
  //   return FutureBuilder<List<CategoriesM>>(
  //       future: categoriesFuture,
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return Center(
  //             child:
  //                 CircularProgressIndicator(), // Show a loading indicator while waiting
  //           );
  //         } else if (snapshot.hasError) {
  //           return Center(
  //             child: Text('Error: ${snapshot.error}'),
  //           );
  //         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //           return Center(
  //             child: Text('No data available'),
  //           );
  //         } else {
  //           final filteredCategories = snapshot.data!
  //               .where((category) => category.vendorClassificationName
  //                   .toLowerCase()
  //                   .contains(_searchQuery.toLowerCase()))
  //               .toList();
  //           return GridView.builder(
  //             gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
  //               maxCrossAxisExtent: 200,
  //               childAspectRatio: 3 / 2,
  //               crossAxisSpacing: 2,
  //               mainAxisSpacing: 2,
  //             ),
  //             itemCount: filteredCategories.length,
  //             itemBuilder: (context, index) {
  //               CategoriesM category = filteredCategories[index];
  //               return GestureDetector(
  //                 onTap: () {
  //                   String selectedVendorClassificationId =
  //                       category.vendorClassificationId.toString();
  //                   Navigator.of(context).push(MaterialPageRoute(
  //                       builder: (context) => StoreCategories(
  //                             selectedVendorClassificationId:
  //                                 selectedVendorClassificationId,
  //                             fromCategories: true,
  //                           )));
  //                   // print("index id>>>${categoriesList[index].id}");
  //                 },
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(10),
  // image: DecorationImage(
  //   image: category.vendorClassificationImageUrl != null
  //       ? CachedNetworkImageProvider(
  //           category.vendorClassificationImageUrl)
  //       : AssetImage("assets/images/shadow.png")
  //           as ImageProvider<Object>,
  //                         fit: BoxFit.cover,
  //                       )),
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.end,
  //                     children: [
  //                       Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(5),
  //                             color: Colors.black.withOpacity(0.4),
  //                           ),
  //                           width: MediaQuery.of(context).size.width * .65,
  //                           child: Text(
  //                             category.vendorClassificationName,
  //                             textAlign: TextAlign.center,
  //                             style: TextStyle(
  //                                 color: Colors.white,
  //                                 fontWeight: FontWeight.w500),
  //                           ),
  //                         ),
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         }
  //       });
  // }
  Widget categoryList() {
    return FutureBuilder<List<CategoriesM>>(
        future: categoriesFuture,
        builder: (context, snapshot) {
          // Loading state
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return Center(
          //     child: CircularProgressIndicator(
          //       valueColor: AlwaysStoppedAnimation<Color>(Constants().appColor),
          //       strokeWidth: 2.5,
          //     ),
          //   );
          // }
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Details: ${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          // Empty state
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No categories available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          // Data loaded successfully
          else {
            final filteredCategories = snapshot.data!
                .where((category) => category.vendorClassificationName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

            // No results after filtering
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
              // Category image
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

              // Gradient overlay
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

              // Category name
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

  Widget storeList() {
    // Get filtered vendors for search results
    List<filter.Vendor> filteredVendors = filterVendorModel.data ?? [];

    // Handle empty search results case
    if (_searchQuery.isNotEmpty && filteredVendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      // Trigger loading more items when reaching 80% of the scroll extent
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >
            scrollInfo.metrics.maxScrollExtent * 0.8) {
          if (_searchQuery.isNotEmpty) {
            _loadfilterMoreItems();
          } else {
            _loadMoreItems();
          }
        }
        return false;
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: (_searchQuery.isNotEmpty
                ? filteredVendors.length
                : storesList.length) +
            1,
        itemBuilder: (BuildContext ctx, index) {
          // Loading indicator at the end of the list
          if (index ==
              (_searchQuery.isNotEmpty
                  ? filteredVendors.length
                  : storesList.length)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                  // AlwaysStoppedAnimation<Color>(Constants().appColor),
                ),
              ),
            );
          }

          // Store data based on search state
          final bool isSearchMode = _searchQuery.isNotEmpty;
          final String storeName = isSearchMode
              ? filteredVendors[index].vendorBusinessName
              : storesList[index].name;
          final String imageUrl = isSearchMode
              ? filteredVendors[index].vendorBusinessPicUrl1
              : storesList[index].imageURL1;
          final String defaultImage = isSearchMode
              ? "assets/images/ic_sample_image.png"
              : "assets/images/store.jpg";
          final bool hasValidImage = imageUrl != "null" && imageUrl.isNotEmpty;

          // Determine the category name to display
          final String categoryName = isSearchMode
              ? (filteredVendors[index].vendorClassificationName ?? "Store")
              : storesList[index].classificationName;

          return _buildStoreCard(
            ctx,
            index,
            storeName,
            imageUrl,
            defaultImage,
            hasValidImage,
            isSearchMode,
          );
        },
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    int index,
    String storeName,
    String imageUrl,
    String defaultImage,
    bool hasValidImage,
    bool isSearchMode,
  ) {
    // Get the correct vendor/store object for category name
    final String categoryName = isSearchMode
        ? (filterVendorModel.data != null &&
                filterVendorModel.data!.length > index
            ? filterVendorModel.data![index].vendorClassificationName ?? "Store"
            : "Store")
        : (storesList.length > index
            ? storesList[index].classificationName
            : "Store");

    return GestureDetector(
      onTap: () {
        if (mounted) {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: StoreDetailScreen(isSearchMode
                  ? filterVendorModel.data![index]
                  : storesList[index]),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Store image
              hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.transparent),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported_rounded,
                        size: 35,
                        color: Colors.grey[400],
                        // fit: BoxFit.cover,s
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported_rounded,
                      size: 35,
                      color: Colors.grey[400],
                    ),

              // Gradient overlay for text visibility
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

              // Store info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
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
            ],
          ),
        ),
      ),
    );
  }

  // Widget storeList() {
  //   List<filter.Vendor> filteredVendors = filterVendorModel.data ?? [];
  //   if (_searchQuery.isNotEmpty && filteredVendors.isEmpty) {
  //     return Center(
  //       child: Text('Tap to search'),
  //     );
  //   }
  //   return GridView.builder(
  //     controller: _scrollController,
  //     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
  //       maxCrossAxisExtent: 200,
  //       childAspectRatio: 3 / 2,
  //       crossAxisSpacing: 2,
  //       mainAxisSpacing: 2,
  //     ),
  //     itemCount: _searchQuery.isNotEmpty
  //         ? filteredVendors.length ?? 0
  //         : storesList.length,
  //     itemBuilder: (BuildContext ctx, index) {
  //       return GestureDetector(
  //         onTap: () {
  //           if (mounted) {
  //             Navigator.push(
  //               context,
  //               PageTransition(
  //                 type: PageTransitionType.rightToLeft,
  //                 child: StoreDetailScreen(_searchQuery.isEmpty
  //                     ? storesList[index]
  //                     : filteredVendors[index]),
  //               ),
  //             );
  //           }
  //         },
  //         child: _searchQuery.isEmpty
  //             ? Container(
  //                 margin: const EdgeInsets.only(left: 2, right: 2),
  //                 height: 50,
  //                 width: 122,
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(10),
  //                   image: storesList[index].imageURL1 == "null"
  //                       ? const DecorationImage(
  //                           image: AssetImage("assets/images/store.jpg"),
  //                           fit: BoxFit.fill,
  //                         )
  //                       : DecorationImage(
  //                           image: CachedNetworkImageProvider(
  //                               storesList[index].imageURL1),
  //                           fit: BoxFit.fill,
  //                         ),
  //                 ),
  //                 child: Stack(
  //                   fit: StackFit.expand,
  //                   children: [
  //                     Positioned.fill(
  //                       child: DecoratedBox(
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(10),
  //                           image: const DecorationImage(
  //                             image: AssetImage("assets/images/shadow.png"),
  //                             fit: BoxFit.fill,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     Padding(
  //                       padding: const EdgeInsets.only(bottom: 10),
  //                       child: Align(
  //                         alignment: Alignment.bottomCenter,
  //                         child: Text(
  //                           storesList[index].name,
  //                           style: const TextStyle(
  //                             fontSize: 12,
  //                             color: Colors.white,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               )
  //             : Container(
  //                 margin: const EdgeInsets.only(left: 2, right: 2),
  //                 height: 50,
  //                 width: 122,
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(10),
  //                   image: filteredVendors[index].vendorBusinessPicUrl1 ==
  //                           "null"
  //                       ? const DecorationImage(
  //                           image:
  //                               AssetImage("assets/images/ic_sample_image.png"),
  //                           fit: BoxFit.fill,
  //                         )
  //                       : DecorationImage(
  //                           image: NetworkImage(
  //                               filteredVendors[index].vendorBusinessPicUrl1),
  //                           fit: BoxFit.fill,
  //                         ),
  //                 ),
  //                 child: Stack(
  //                   fit: StackFit.expand,
  //                   children: [
  //                     Positioned.fill(
  //                       child: DecoratedBox(
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(10),
  //                           image: const DecorationImage(
  //                             image: AssetImage("assets/images/shadow.png"),
  //                             fit: BoxFit.fill,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     Padding(
  //                       padding: const EdgeInsets.only(bottom: 10),
  //                       child: Align(
  //                         alignment: Alignment.bottomCenter,
  //                         child: Text(
  //                           filteredVendors[index].vendorBusinessName,
  //                           style: const TextStyle(
  //                             fontSize: 12,
  //                             color: Colors.white,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //       );
  //     },
  //   );
  // }

  Future<http.Response> getStoreList(BuildContext context,
      {bool reset = false, int pageNo = 1, int pageCount = 20}) async {
    try {
      if (reset) {
        storesList.clear();
        filteredStoresList.clear();
        masterStoreList.clear();
      }
      EasyLoading.show(
          dismissOnTap: false, maskType: EasyLoadingMaskType.black);

      final Map<String, String> headers = {
        'Token': Constants().token,
        'pageNo': pageNo.toString(),
        'pageSize': pageCount.toString(),
      };

      final response = await http.get(Uri.parse(Urls.stores), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        log("Response:----------->>> ${response.body}");

        if (data['isSuccess'] == true) {
          List<StoreModel> stores = parseStores(data['data']);
          if (mounted) {
            setState(() {
              storesList.addAll(stores);
              filteredStoresList = storesList;
              masterStoreList = storesList;
            });
            print("MasterList1:>>|||>>>${masterStoreList.length}");
            print("MasterList2:>>|||>>>${storesList.length}");
            print("MasterList3:>>|||>>>${filteredStoresList.length}");
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
        EasyLoading.dismiss();
      }
    }
  }

  List<StoreModel> parseStores(List<dynamic> vendors) {
    return vendors.map<StoreModel>((obj) {
      return StoreModel(
        obj['VendorId']?.toString() ?? '',
        obj['VendorBusinessName']?.toString() ?? '',
        obj['VendorRegisteredMobileNumber']?.toString() ?? '',
        obj['VendorClassificationID']?.toString() ?? '',
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
        obj['VendorCountryId']?.toString() ?? '',
        obj['VendorCountryName']?.toString() ?? '',
        obj['VendorStateId']?.toString() ?? '',
        obj['VendorStateName']?.toString() ?? '',
        obj['VendorDistrictId']?.toString() ?? '',
        obj['VendorDistrictName']?.toString() ?? '',
        obj['VendorTownId']?.toString() ?? '',
        obj['VendorTownName']?.toString() ?? '',
        obj['VendorPlaceId']?.toString() ?? '',
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

  void onSearchTextChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
      if (_searchQuery.isEmpty) {
        filterVendorModel.data = [];
      }
    });
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

  @override
  void dispose() {
    _tabController.dispose();
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void loadAllStores() {
    storesList = masterStoreList;
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
}
