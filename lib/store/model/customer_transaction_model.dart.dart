import 'dart:convert';

CustomerTransactionModel transactionModelFromJson(String str) =>
    CustomerTransactionModel.fromJson(json.decode(str));

String transactionModelToJson(CustomerTransactionModel data) =>
    json.encode(data.toJson());

class CustomerTransactionModel {
  final bool isSuccess;
  final String message;
  final Data data;

  CustomerTransactionModel({
    required this.isSuccess,
    required this.message,
    required this.data,
  });

  factory CustomerTransactionModel.fromJson(Map<String, dynamic> json) {
    return CustomerTransactionModel(
      isSuccess: json['isSuccess'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: Data.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class Data {
  final List<Transaction> transactions;
  final List<PageContext> pageContext;

  Data({
    required this.transactions,
    required this.pageContext,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map(
                  (e) => Transaction.fromJson(e as Map<String, dynamic>? ?? {}))
              .toList() ??
          [],
      pageContext: (json['pageContext'] as List<dynamic>?)
              ?.map(
                  (e) => PageContext.fromJson(e as Map<String, dynamic>? ?? {}))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'pageContext': pageContext.map((e) => e.toJson()).toList(),
    };
  }
}

class PageContext {
  final int totalRecords;
  final int filterRecords;
  final int totalPages;
  final int pageSize;
  final int currentPage;
  final int hasNext;
  final int hasPrevious;

  PageContext({
    required this.totalRecords,
    required this.filterRecords,
    required this.totalPages,
    required this.pageSize,
    required this.currentPage,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PageContext.fromJson(Map<String, dynamic> json) {
    return PageContext(
      totalRecords: (json['TotalRecords'] as num?)?.toInt() ?? 0,
      filterRecords: (json['FilterRecords'] as num?)?.toInt() ?? 0,
      totalPages: (json['TotalPages'] as num?)?.toInt() ?? 0,
      pageSize: (json['PageSize'] as num?)?.toInt() ?? 0,
      currentPage: (json['CurrentPage'] as num?)?.toInt() ?? 0,
      hasNext: (json['HasNext'] as num?)?.toInt() ?? 0,
      hasPrevious: (json['HasPrevious'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TotalRecords': totalRecords,
      'FilterRecords': filterRecords,
      'TotalPages': totalPages,
      'PageSize': pageSize,
      'CurrentPage': currentPage,
      'HasNext': hasNext,
      'HasPrevious': hasPrevious,
    };
  }
}

class Transaction {
  final String transDate;
  final String vendorName;
  final double amount;
  final String transType;

  Transaction({
    required this.transDate,
    required this.vendorName,
    required this.amount,
    required this.transType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transDate: json['TransDate']?.toString() ?? '',
      vendorName: json['VendorName']?.toString() ?? '',
      amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
      transType: json['TransType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TransDate': transDate,
      'VendorName': vendorName,
      'Amount': amount,
      'TransType': transType,
    };
  }
}

// import 'dart:convert';

// // Changed to parse single object instead of list
// CustomerTransactionModel transactionModelFromJson(String str) =>
//     CustomerTransactionModel.fromJson(json.decode(str));

// String transactionModelToJson(CustomerTransactionModel data) =>
//     json.encode(data.toJson());

// class CustomerTransactionModel {
//   bool isSuccess;
//   String message;
//   Data data;

//   CustomerTransactionModel({
//     required this.isSuccess,
//     required this.message,
//     required this.data,
//   });

//   factory CustomerTransactionModel.fromJson(Map<String, dynamic> json) {
//     return CustomerTransactionModel(
//       isSuccess: json['isSuccess'],
//       message: json['message'],
//       data: Data.fromJson(json['data']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'isSuccess': isSuccess,
//       'message': message,
//       'data': data.toJson(),
//     };
//   }
// }

// class Data {
//   List<Transaction> transactions;
//   List<PageContext> pageContext;

//   Data({
//     required this.transactions,
//     required this.pageContext,
//   });

//   factory Data.fromJson(Map<String, dynamic> json) {
//     return Data(
//       transactions: (json['transactions'] as List)
//           .map((e) => Transaction.fromJson(e))
//           .toList(),
//       pageContext: (json['pageContext'] as List)
//           .map((e) => PageContext.fromJson(e))
//           .toList(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'transactions': transactions.map((e) => e.toJson()).toList(),
//       'pageContext': pageContext.map((e) => e.toJson()).toList(),
//     };
//   }
// }

// class PageContext {
//   int totalRecords;
//   int filterRecords;
//   int totalPages;
//   int pageSize;
//   int currentPage;
//   int hasNext;
//   int hasPrevious;

//   PageContext({
//     required this.totalRecords,
//     required this.filterRecords,
//     required this.totalPages,
//     required this.pageSize,
//     required this.currentPage,
//     required this.hasNext,
//     required this.hasPrevious,
//   });

//   factory PageContext.fromJson(Map<String, dynamic> json) {
//     return PageContext(
//       totalRecords: json['totalRecords'].toInt(),
//       filterRecords: json['filterRecords'].toInt(),
//       totalPages: json['totalPages'].toInt(),
//       pageSize: json['pageSize'].toInt(),
//       currentPage: json['currentPage'].toInt(),
//       hasNext: json['hasNext'].toInt(),
//       hasPrevious: json['hasPrevious'].toInt(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'totalRecords': totalRecords,
//       'filterRecords': filterRecords,
//       'totalPages': totalPages,
//       'pageSize': pageSize,
//       'currentPage': currentPage,
//       'hasNext': hasNext,
//       'hasPrevious': hasPrevious,
//     };
//   }
// }

// class Transaction {
//   String transDate;
//   String vendorName;
//   int amount;
//   String transType;

//   Transaction({
//     required this.transDate,
//     required this.vendorName,
//     required this.amount,
//     required this.transType,
//   });

//   factory Transaction.fromJson(Map<String, dynamic> json) {
//     return Transaction(
//       transDate: json['transDate'].toString(),
//       vendorName: json['vendorName'].toString(),
//       amount: json['amount'],
//       transType: json['transType'].toString(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'transDate': transDate,
//       'vendorName': vendorName,
//       'amount': amount,
//       'transType': transType,
//     };
//   }
// }

// List<CustomerTransactionModel> customerTransactionModelFromJson(String str) =>
//     List<CustomerTransactionModel>.from(
//         json.decode(str).map((x) => CustomerTransactionModel.fromJson(x)));

// String customerTransactionModelToJson(List<CustomerTransactionModel> data) =>
//     json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// class CustomerTransactionModel {
//   String transactionType;
//   DateTime dateTime;
//   num value;
//   String vendorName;

//   CustomerTransactionModel(
//       {required this.transactionType,
//       required this.dateTime,
//       required this.value,
//       required this.vendorName});

//   factory CustomerTransactionModel.fromJson(Map<String, dynamic> json) =>
//       CustomerTransactionModel(
//         transactionType: json["transactionType"],
//         dateTime: DateTime.parse(json["dateTime"]),
//         value: json["value"],
//         vendorName: json["vendorName"] ?? "",
//       );

//   Map<String, dynamic> toJson() => {
//         "transactionType": transactionType,
//         "dateTime": dateTime.toIso8601String(),
//         "value": value,
//         "vendorName": vendorName,
//       };
// }
