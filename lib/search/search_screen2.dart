import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/Utils/urls.dart';
import 'package:reward_hub_customer/search/search_store_details.dart';
import 'package:reward_hub_customer/store/model/search_town_model.dart';
import 'package:reward_hub_customer/wallet/wallet_screen2.dart';

class SearchScreen2 extends StatefulWidget {
  const SearchScreen2({super.key});

  @override
  State<SearchScreen2> createState() => _SearchScreen2State();
}

DateTime? currentBackPressTime;

List<PlaceModel> places = [];
List<PlaceModel> filteredPlaces = [];
final TextEditingController _searchController = TextEditingController();
FocusNode searchFocus = FocusNode();

class _SearchScreen2State extends State<SearchScreen2> {
  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    final String apiUrl = Urls.getPlaceData;
    final String token = Constants().token;

    try {
      EasyLoading.show(
          status: 'Please Wait...',
          dismissOnTap: false,
          maskType: EasyLoadingMaskType.black);

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Token': token,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          places = placeResponseFromJson(response.body).data;
          // placeModelFromJson(response.body);
          filteredPlaces = places;
        });
      } else {
        throw Exception('Failed to fetch data from API');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentBackPressTime == null ||
            DateTime.now().difference(currentBackPressTime!) >
                Duration(seconds: 1)) {
          // Show a toast or snackbar indicating that the user should double tap to exit
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );

          // Update the currentBackPressTime
          currentBackPressTime = DateTime.now();
          return false; // Do not exit the app
        } else {
          // The user has double-tapped within 2 seconds, exit the app
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: null,
          title: Text(
            "Search Place",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // body: Stack(
        //   children: [
        //   Sample2()
        //   ],
        // ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Constants().appColor.withOpacity(0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    focusNode: searchFocus,
                    controller: _searchController,
                    onChanged: (value) {
                      filterPlaces(value);
                    },
                    style: TextStyle(fontSize: 15, color: Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      hintText: "Search for a place...",
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 14.0),
                      suffixIcon: _searchController.text.isEmpty
                          ? Icon(Icons.search, color: Constants().appColor)
                          : InkWell(
                              onTap: () {
                                _searchController.clear();
                                filterPlaces('');
                                searchFocus.unfocus();
                              },
                              child: Icon(Icons.close,
                                  color: Constants().appColor),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              filteredPlaces.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        physics: filteredPlaces.isEmpty
                            ? NeverScrollableScrollPhysics()
                            : ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filteredPlaces.length,
                        itemBuilder: (context, index) {
                          filteredPlaces.sort(
                              (a, b) => a.placeName.compareTo(b.placeName));
                          final place = filteredPlaces[index];
                          return GestureDetector(
                            onTap: () {
                              handleCategoryTap(
                                  filteredPlaces[index].placeId.toString());
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => SearchStoreDetailsScreen(
                                  placeId:
                                      filteredPlaces[index].placeId.toString(),
                                ),
                              ));
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Constants().appColor.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Constants().appColor.withOpacity(0.12),
                                  child: Text(
                                    place.placeName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Constants().appColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  place.placeName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                subtitle: Text(
                                  place.townName,
                                  style: TextStyle(
                                    color: Color(0xFF2C2C2C).withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right,
                                    color: Constants().appColor),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: Constants().appColor.withOpacity(0.18)),
                            SizedBox(height: 16),
                            Text(
                              "No Data Found...",
                              style: TextStyle(
                                color: Color(0xFF2C2C2C).withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
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
    );
  }

  void filterPlaces(String query) {
    setState(() {
      String trimmedQuery = query.trim();
      filteredPlaces = places
          .where((place) => place.placeName
              .toLowerCase()
              .contains(trimmedQuery.toLowerCase()))
          .toList();
      filteredPlaces.sort((a, b) => a.placeName.compareTo(b.placeName));
    });
  }

  void handleCategoryTap(String VendorPlaceID) {
    int vendorPlaceId = int.tryParse(VendorPlaceID.toString()) ?? 0;
    if (vendorPlaceId > 0) {
      // Implement logic for handling category tap
    } else {
      // Implement logic for handling category tap
    }
  }
}
