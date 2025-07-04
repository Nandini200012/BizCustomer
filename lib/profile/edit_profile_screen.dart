// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reward_hub_customer/Utils/SharedPrefrence.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:reward_hub_customer/Utils/toast_widget.dart';
import 'package:reward_hub_customer/Utils/urls.dart';
import 'package:reward_hub_customer/profile/api_service.dart';
import 'package:reward_hub_customer/provider/user_data_provider.dart';
import 'package:reward_hub_customer/store/model/profile_data_model.dart';

import 'package:image_cropper/image_cropper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

TextEditingController _fulNameController = TextEditingController();
TextEditingController _addres1Controller = TextEditingController();
TextEditingController _addres2Controller = TextEditingController();
TextEditingController _pinCodeController = TextEditingController();
TextEditingController _emailController = TextEditingController();
TextEditingController _phoneNumberController = TextEditingController();

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  ApiService apiService = ApiService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUserProfileData();
  }

  Future<void> _loadUserProfileData() async {
    try {
      GetUserDetails userDetails = await apiService.fetchUserProfileData(
        Constants().token,
        SharedPrefrence().getUserPhone(),
      );

      setState(() {
        _fulNameController.text = SharedPrefrence().getUsername();
        _emailController.text = userDetails.cmCustomerEmail.toString();
        _phoneNumberController.text =
            userDetails.cmCustomerRegisteredMobileNumber.toString();
        _addres1Controller.text = userDetails.cmCustomerAddressL1.toString();
        _addres2Controller.text = userDetails.cmCustomerAddressL2.toString();
        _pinCodeController.text = userDetails.cmCustomerPinCode.toString();
        if (userDetails.customerPhotoUrl != null &&
            userDetails.customerPhotoUrl.isNotEmpty) {
          _imageFile = File(userDetails.customerPhotoUrl);
        }
      });
    } catch (error) {
      print("Error loading user profile data: $error");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source).then((
      value,
    ) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
    ;

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.camera_alt),
              //   title: Text('Take a photo'),
              //   onTap: () {
              //     _pickImage(ImageSource.camera);
              //     // _cropImage(imgFile)
              //     Navigator.pop(context);
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                flex: 0,
                child: Container(
                  height: 50,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: Constants().appColor, size: 22),
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "EDIT PROFILE",
                            style: TextStyle(
                              color: Color(0xFF2C2C2C),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Constants().appColor.withOpacity(0.1),
                        Colors.white
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showImagePicker(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Constants().appColor.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: _imageFile == null
                              ? Image.asset(
                                  "assets/images/Frame_2.png",
                                  height: 98.h,
                                  width: 98.h,
                                  fit: BoxFit.cover,
                                )
                              : _imageFile!.existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(49),
                                      child: Image.file(
                                        _imageFile!,
                                        height: 98,
                                        width: 98,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      "assets/images/Frame_2.png",
                                      height: 98.h,
                                      width: 98.h,
                                      fit: BoxFit.cover,
                                    ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          top: 16,
                          right: 8,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            SharedPrefrence().getUsername(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          SharedPrefrence().getUserPhone(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Full Name",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _fulNameController,
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Constants().appColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Constants().appColor),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address.';
                          }
                          bool isValid = RegExp(
                            r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
                          ).hasMatch(value);
                          if (!isValid) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Address 1",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _addres1Controller,
                        decoration: InputDecoration(
                          hintText: "Address1",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Constants().appColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Address 2",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _addres2Controller,
                        decoration: InputDecoration(
                          hintText: "Address2",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Constants().appColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Pincode",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _pinCodeController,
                        decoration: InputDecoration(
                          hintText: "Pin code",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Constants().appColor),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9]'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 5.0),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              Constants().appColor,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Colors.white,
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            elevation: MaterialStateProperty.all(4),
                            shadowColor: MaterialStateProperty.all(
                              Constants().appColor.withOpacity(0.3),
                            ),
                          ),
                          onPressed: () {
                            _updateProfile();
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                          child: Text(
                            "SAVE",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
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
    );
  }

  void _updateProfile() async {
    final String apiUrl = Urls.updateProfileData;
    final String token = Constants().token;

    Map<String, dynamic> requestBody = {
      "customerID": 0,
      "customerRegisteredMobileNumber": int.parse(_phoneNumberController.text),
      "customerName": _fulNameController.text,
      "customerEmail": _emailController.text,
      "customerAddressL1": _addres1Controller.text,
      "customerAddressL2": _addres2Controller.text,
      "customerPinCode": int.parse(_pinCodeController.text),
      "customerIdproofUrl": "",
      "customerPhotoUrl": _imageFile != null ? _imageFile?.path : "",
    };

    try {
      EasyLoading.show(
        dismissOnTap: false,
        maskType: EasyLoadingMaskType.black,
      );
      setState(() {
        Provider.of<UserData>(
          context,
          listen: false,
        ).setUserName(_fulNameController.text);

        Provider.of<UserData>(
          context,
          listen: false,
        ).setUserProfilePhotoData(_imageFile?.path ?? "");
      });
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          "Token": token,
          HttpHeaders.contentTypeHeader: "application/json", // Set content type
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        await _loadUserProfileData();
        ToastWidget().showToastSuccess("Profile updated successfully");
        print("Profile updated successfully");
      } else {
        // Handle error
        print("Failed to update profile. Status code: ${response.statusCode}");
      }
    } catch (error) {
      // Handle exception
      print("Error updating profile: $error");
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _cropImage(File imgFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imgFile.path,
      // Removed the invalid 'cropStyle' parameter
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Image Cropper",
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: "Image Cropper"),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }
}
