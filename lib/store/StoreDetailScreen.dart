import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/developer.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:reward_hub_customer/Utils/SharedPrefrence.dart';
import 'package:reward_hub_customer/Utils/phone_dialer.dart';
import 'package:reward_hub_customer/profile/profile_screen.dart';
import 'package:reward_hub_customer/provider/user_data_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Utils/constants.dart';
import 'model/filter_model.dart' as filter;
import 'model/store_model.dart';

class StoreDetailScreen extends StatefulWidget {
  final dynamic storeList;

  StoreDetailScreen(this.storeList);

  @override
  State<StatefulWidget> createState() => StoreDetailScreenState(this.storeList);
}

class StoreDetailScreenState extends State<StoreDetailScreen> {
  List<String> imgList = [];
  List<String> tagList = [];
  int _currentImageIndex = 0;
  dynamic storeList;
  static const platform = MethodChannel('dialer.channel/call');

  StoreDetailScreenState(this.storeList);

  String get vendorId {
    try {
      if (storeList is StoreModel) {
        return storeList.id.toString();
      } else if (storeList is filter.Vendor) {
        return storeList.vendorId.toString();
      }
    } catch (e) {
      print("Error getting vendorId: $e");
    }
    return "";
  }

  String get vendorCategories {
    try {
      if (storeList is StoreModel) {
        return (storeList.vendorCategories ?? "").toString();
      } else if (storeList is filter.Vendor) {
        return (storeList.vendorCategories ?? "").toString();
      }
    } catch (e) {
      print("Error getting vendorCategories: $e");
    }
    return "";
  }

  String get vendorName {
    try {
      if (storeList is StoreModel) {
        return storeList.name.toString();
      } else if (storeList is filter.Vendor) {
        return storeList.vendorBusinessName.toString();
      }
    } catch (e) {
      print("Error getting vendorName: $e");
    }
    return "";
  }

  String get vendorClassificationName {
    try {
      if (storeList is StoreModel) {
        return (storeList.classificationName ?? "").toString();
      } else if (storeList is filter.Vendor) {
        return (storeList.vendorClassificationName ?? "").toString();
      }
    } catch (e) {
      print("Error getting vendorClassificationName: $e");
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
    print("StoreList Data=======: ${storeList}");
    debugPrint("StoreList Full Data: ${storeList.toString()}", wrapWidth: 1024);

    if (storeList is StoreModel) {
      imgList = [
        storeList.imageURL1 ?? "",
        storeList.imageURL2 ?? "",
        storeList.imageURL3 ?? "",
        storeList.imageURL4 ?? "",
        storeList.imageURL5 ?? "",
        storeList.imageURL6 ?? "",
      ];
    } else if (storeList is filter.Vendor) {
      imgList = [
        storeList.vendorBusinessPicUrl1 ?? "",
        storeList.vendorBusinessPicUrl2 ?? "",
        storeList.vendorBusinessPicUrl3 ?? "",
        storeList.vendorBusinessPicUrl4 ?? "",
        storeList.vendorBusinessPicUrl5 ?? "",
      ];
    }
    imgList = imgList.where((url) => url.isNotEmpty).toList();
    String categories = vendorCategories;
    tagList = categories.isNotEmpty ? categories.split(',') : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ProfileScreen())),
                      child: Container(
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Consumer<UserData>(
                          builder: (context, userData, _) {
                            String profilePhotoPath =
                                SharedPrefrence().getUserProfilePhoto();
                            File profilePhotoFile = File(profilePhotoPath);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: profilePhotoFile.existsSync()
                                  ? Image.file(
                                      profilePhotoFile,
                                      height: 35.h,
                                      width: 35.w,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      "assets/images/ic_profile.png",
                                      height: 35.h,
                                      width: 35.w,
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 350,
                          viewportFraction: 1,
                          autoPlay: imgList.length > 1,
                          autoPlayInterval: Duration(seconds: 3),
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                        items: imgList.isEmpty
                            ? [
                                Image.asset(
                                  "assets/images/store.jpg",
                                  fit: BoxFit.cover,
                                )
                              ]
                            : imgList.map((item) {
                                return CachedNetworkImage(
                                  imageUrl: item,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Center(
                                    child: CupertinoActivityIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    "assets/images/store.jpg",
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }).toList(),
                      ),
                      if (imgList.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: imgList.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(
                                    _currentImageIndex == entry.key ? 0.9 : 0.4,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                storeList is StoreModel
                                    ? storeList.name ?? ""
                                    : (storeList is filter.Vendor
                                        ? storeList.vendorBusinessName ?? ""
                                        : ''),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                makePhoneCall(
                                  context,
                                  storeList is StoreModel
                                      ? storeList.mobileNumber ?? ""
                                      : (storeList is filter.Vendor
                                          ? storeList
                                                  .vendorRegisteredMobileNumber
                                                  .toString() ??
                                              ""
                                          : ''),
                                  platform,
                                );
                              },
                              icon: Icon(Icons.call, color: Colors.white),
                              label: Text('Call Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildLocationInfo(),
                        SizedBox(height: 24),
                        _buildDescriptionSection(),
                        SizedBox(height: 24),
                        _buildCategoriesSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on,
            storeList is StoreModel
                ? "${storeList.landMark ?? ""}"
                : (storeList is filter.Vendor ? storeList.landMark ?? "" : ''),
            "Landmark",
          ),
          _buildInfoRow(
            Icons.place,
            storeList is StoreModel
                ? "${storeList.placeName ?? ""}"
                : (storeList is filter.Vendor
                    ? storeList.vendorplaceName ?? ""
                    : ''),
            "Place",
          ),
          _buildInfoRow(
            Icons.location_city,
            storeList is StoreModel
                ? "${storeList.townName ?? ""}"
                : (storeList is filter.Vendor
                    ? storeList.vendorTownName ?? ""
                    : ''),
            "Town",
          ),
          _buildInfoRow(
            Icons.map,
            storeList is StoreModel
                ? "${storeList.districtName ?? ""}"
                : (storeList is filter.Vendor
                    ? storeList.vendordistrictName ?? ""
                    : ''),
            "District",
          ),
          _buildInfoRow(
            Icons.pin_drop,
            storeList is StoreModel
                ? "${storeList.vendorPincode ?? ""}"
                : (storeList is filter.Vendor
                    ? storeList.vendorPinCode ?? ""
                    : ''),
            "Pin Code",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, String label) {
    if (value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Constants().appColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = storeList is StoreModel
        ? storeList.discription ?? ""
        : (storeList is filter.Vendor
            ? storeList.vendorBusinessDescription ?? ""
            : '');

    if (description.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    if (tagList.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tagList.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Constants().appColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Constants().appColor,
                  width: 1,
                ),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: Constants().appColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

Future<void> makePhoneCall(
    BuildContext context, String phoneNumber, dynamic platform) async {
  if (phoneNumber.isEmpty) return;

  final bool? shouldCall = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Confirm Call',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
        ),
      ),
      content: Text(
        'Do you want to call $phoneNumber ?',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'No',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Yes',
            style: TextStyle(
              color: Constants().appColor,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    ),
  );

  if (shouldCall != true) return;

  if (Platform.isAndroid) {
    try {
      await platform.invokeMethod('makeCall', {'number': phoneNumber});
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to make call: ${e.message}"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } else if (Platform.isIOS) {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot launch dialer"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

//   final status = await Permission.phone.status;
//   if (status.isDenied || status.isPermanentlyDenied) {
//     final result = await Permission.phone.request();
//     if (!result.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text("Phone call permission denied"),
//       ));
//       return;
//     }
//   }

//   try {
//     await platform.invokeMethod('makeCall', {'number': phoneNumber});
//   } on PlatformException catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text("Failed to make call: ${e.message}"),
//     ));
//   }
// }
// Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
//   final status = await Permission.phone.status;

//   if (status.isGranted) {
//     // Permission granted — proceed to call
//     try {
//       await PhoneDialer.makeCall(context, phoneNumber);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Could not launch dialer: $e')),
//       );
//     }
//   } else {
//     // Request permission
//     final result = await Permission.phone.request();
//     if (result.isGranted) {
//       try {
//         await PhoneDialer.makeCall(context, phoneNumber);
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not launch dialer: $e')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Phone call permission denied')),
//       );
//     }
//   }
// }
// Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
//   await PhoneDialer.makeCall(context, phoneNumber);
// }
