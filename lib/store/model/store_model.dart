class StoreModel {
  int id = 0;
  var name = "";
  var mobileNumber = "";
  int classificationID = 0;
  var classificationName = "";
  var vendorCategories = "";
  var vendorAddress1 = "";
  var vendorAddress2 = "";
  var vendorPincode = "";
  var vendorGPSLocation = "";
  var imageURL1 = "";
  var imageURL2 = "";
  var imageURL3 = "";
  var imageURL4 = "";
  var imageURL5 = "";
  var imageURL6 = "";
  int countryID = 0;
  var countryName = "";
  int stateID = 0;
  var stateName = "";
  int districtID = 0;
  var districtName = "";
  int townID = 0;
  var townName = "";
  int placeID = 0;
  var placeName = "";
  var discription = "";
  var vendorRegisteredMobileNumber = "";
  var landMark = "";

  StoreModel(
    this.id,
    this.name,
    this.mobileNumber,
    this.classificationID,
    this.classificationName,
    this.vendorCategories,
    this.vendorAddress1,
    this.vendorAddress2,
    this.vendorPincode,
    this.vendorGPSLocation,
    this.imageURL1,
    this.imageURL2,
    this.imageURL3,
    this.imageURL4,
    this.imageURL5,
    this.imageURL6,
    this.countryID,
    this.countryName,
    this.stateID,
    this.stateName,
    this.districtID,
    this.districtName,
    this.townID,
    this.townName,
    this.placeID,
    this.placeName,
    this.discription,
    this.vendorRegisteredMobileNumber,
    this.landMark,
  );

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      int.tryParse(json['id']?.toString() ?? "0") ?? 0,
      json['name'] ?? "",
      json['mobileNumber'] ?? "",
      int.tryParse(json['classificationID']?.toString() ?? "0") ?? 0,
      json['classificationName'] ?? "",
      json['vendorCategories'] ?? "",
      json['vendorAddress1'] ?? "",
      json['vendorAddress2'] ?? "",
      json['vendorPincode'] ?? "",
      json['vendorGPSLocation'] ?? "",
      json['imageURL1'] ?? "",
      json['imageURL2'] ?? "",
      json['imageURL3'] ?? "",
      json['imageURL4'] ?? "",
      json['imageURL5'] ?? "",
      json['imageURL6'] ?? "",
      int.tryParse(json['countryID']?.toString() ?? "0") ?? 0,
      json['countryName'] ?? "",
      int.tryParse(json['stateID']?.toString() ?? "0") ?? 0,
      json['stateName'] ?? "",
      int.tryParse(json['districtID']?.toString() ?? "0") ?? 0,
      json['VendorDistrictName'] ?? "",
      int.tryParse(json['townID']?.toString() ?? "0") ?? 0,
      json['townName'] ?? "",
      int.tryParse(json['placeID']?.toString() ?? "0") ?? 0,
      json['placeName'] ?? "",
      json['VendorBusinessDescription'] ?? "",
      json['VendorRegisteredMobileNumber'] ?? "",
      json['LandMark'] ?? "",
    );
  }
}

// class StoreModel {
//   var id = "";
//   var name = "";
//   var mobileNumber = "";
//   var classificationID = "";
//   var classificationName = "";
//   var vendorCategories = "";
//   var vendorAddress1 = "";
//   var vendorAddress2 = "";
//   var vendorPincode = "";
//   var vendorGPSLocation = "";
//   var imageURL1 = "";
//   var imageURL2 = "";
//   var imageURL3 = "";
//   var imageURL4 = "";
//   var imageURL5 = "";
//   var imageURL6 = "";
//   var countryID = "";
//   var countryName = "";
//   var stateID = "";
//   var stateName = "";
//   var districtID = "";
//   var districtName = "";
//   var townID = "";
//   var townName = "";
//   var placeID = "";
//   var placeName = "";
//   var discription = "";
//   var vendorRegisteredMobileNumber = "";
//   var landMark = "";

//   StoreModel(
//     this.id,
//     this.name,
//     this.mobileNumber,
//     this.classificationID,
//     this.classificationName,
//     this.vendorCategories,
//     this.vendorAddress1,
//     this.vendorAddress2,
//     this.vendorPincode,
//     this.vendorGPSLocation,
//     this.imageURL1,
//     this.imageURL2,
//     this.imageURL3,
//     this.imageURL4,
//     this.imageURL5,
//     this.imageURL6,
//     this.countryID,
//     this.countryName,
//     this.stateID,
//     this.stateName,
//     this.districtID,
//     this.districtName,
//     this.townID,
//     this.townName,
//     this.placeID,
//     this.placeName,
//     this.discription,
//     this.vendorRegisteredMobileNumber,
//     this.landMark,
//   );

//   factory StoreModel.fromJson(Map<String, dynamic> json) {
//     return StoreModel(
//       json['id'] ?? "",
//       json['name'] ?? "",
//       json['mobileNumber'] ?? "",
//       json['classificationID'] ?? "",
//       json['classificationName'] ?? "",
//       json['vendorCategories'] ?? "",
//       json['vendorAddress1'] ?? "",
//       json['vendorAddress2'] ?? "",
//       json['vendorPincode'] ?? "",
//       json['vendorGPSLocation'] ?? "",
//       json['imageURL1'] ?? "",
//       json['imageURL2'] ?? "",
//       json['imageURL3'] ?? "",
//       json['imageURL4'] ?? "",
//       json['imageURL5'] ?? "",
//       json['imageURL6'] ?? "",
//       json['countryID'] ?? "",
//       json['countryName'] ?? "",
//       json['districtID'] ?? "",
//       json['VendorDistrictName'] ?? "",
//       json['stateID'] ?? "",
//       json['stateName'] ?? "",
//       json['townID'] ?? "",
//       json['townName'] ?? "",
//       json['placeID'] ?? "",
//       json['placeName'] ?? "",
//       json['VendorBusinessDescription'] ?? "",
//       json['VendorRegisteredMobileNumber'] ?? "",
//       json['LandMark'] ?? "",
//     );
//   }
// }
