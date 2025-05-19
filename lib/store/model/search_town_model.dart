import 'dart:convert';

PlaceResponse placeResponseFromJson(String str) =>
    PlaceResponse.fromJson(json.decode(str));

String placeResponseToJson(PlaceResponse data) => json.encode(data.toJson());

class PlaceResponse {
  bool isSuccess;
  String message;
  List<PlaceModel> data;

  PlaceResponse({
    required this.isSuccess,
    required this.message,
    required this.data,
  });

  factory PlaceResponse.fromJson(Map<String, dynamic> json) => PlaceResponse(
        isSuccess: json["isSuccess"],
        message: json["message"],
        data: List<PlaceModel>.from(
            json["data"].map((x) => PlaceModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "isSuccess": isSuccess,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class PlaceModel {
  int placeId;
  String placeName;
  int townId;
  String townName;

  PlaceModel({
    required this.placeId,
    required this.placeName,
    required this.townId,
    required this.townName,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
        placeId: json["PlaceID"],
        placeName: json["PlaceName"],
        townId: json["TownID"],
        townName: json["TownName"],
      );

  Map<String, dynamic> toJson() => {
        "PlaceID": placeId,
        "PlaceName": placeName,
        "TownID": townId,
        "TownName": townName,
      };
}
// // To parse this JSON data, do
// //
// //     final placeModel = placeModelFromJson(jsonString);

// import 'dart:convert';

// List<PlaceModel> placeModelFromJson(String str) =>
//     List<PlaceModel>.from(json.decode(str).map((x) => PlaceModel.fromJson(x)));

// String placeModelToJson(List<PlaceModel> data) =>
//     json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// class PlaceModel {
//   int placeId;
//   String placeName;
//   int townId;
//   String townName;

//   PlaceModel({
//     required this.placeId,
//     required this.placeName,
//     required this.townId,
//     required this.townName,
//   });

//   factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
//         placeId: json["PlaceID"],
//         placeName: json["PlaceName"],
//         townId: json["TownID"],
//         townName: json["TownName"],
//       );

//   Map<String, dynamic> toJson() => {
//         "PlaceID": placeId,
//         "PlaceName": placeName,
//         "TownID": townId,
//         "TownName": townName,
//       };
// }
