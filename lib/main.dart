import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:reward_hub_customer/Utils/constants.dart';
import 'package:reward_hub_customer/provider/user_data_provider.dart';
import 'package:reward_hub_customer/splash/splash_screen.dart';

@pragma('vm:entry-point')
void main() async {
  // Initialize GetStorage
  await GetStorage.init();

  // Lock orientation to portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

// Rest of your MyApp class remains the same
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(430, 932),
      child: ChangeNotifierProvider(
        create: (context) => UserData(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bizatom',
          home: SplashScreen(),
          builder: EasyLoading.init(),
          theme: ThemeData(
              colorScheme: ColorScheme.fromSwatch(
                  accentColor: Constants().appColor,
                  backgroundColor: Colors.white),
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants().appColor)),
              )),
        ),
      ),
    );
  }
}
