import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:elmazr3a/my_theme.dart';
import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart';
import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
import 'package:flutter_paytabs_bridge/PaymentSDKSavedCardInfo.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkApms.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkTokeniseType.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
import 'package:fluttertoast/fluttertoast.dart';

class IyzicoScreen extends StatefulWidget {
  double amount;
  String payment_type;
  String payment_method_key;

  IyzicoScreen(
      {Key key,
        this.amount = 0.00,
        this.payment_type = "",
        this.payment_method_key = ""})
      : super(key: key);

  @override
  _IyzicoScreenState createState() => _IyzicoScreenState();
}

class _IyzicoScreenState extends State<IyzicoScreen> {
  String _instructions = 'Tap on "Pay" Button to try PayTabs plugin';

  @override
  void initState() {
    super.initState();
  }

  PaymentSdkConfigurationDetails generateConfig() {
    var billingDetails = BillingDetails("John Smith", "email@domain.com",
        "+97311111111", "st. 12", "eg", "dubai", "dubai", "12345");
    var shippingDetails = ShippingDetails("John Smith", "email@domain.com",
        "+97311111111", "st. 12", "eg", "dubai", "dubai", "12345");
    List<PaymentSdkAPms> apms = [];
    apms.add(PaymentSdkAPms.AMAN);
    var configuration = PaymentSdkConfigurationDetails(
        profileId: "99337",
        serverKey: "SMJNGGTRHT-JDNBMJ96NK-6N662RBDWN",
        clientKey: "CBKMNP-69DT6D-Q2N6PG-7GPN26",
        cartId: "12433",
        cartDescription: "Flowers",
        merchantName: "Flowers Store",
        screentTitle: "Pay with Card",
        amount: 2.0,
        showBillingInfo: true,
        forceShippingInfo: false,
        currencyCode: "EGP",
        merchantCountryCode: "EG",
        billingDetails: billingDetails,
        shippingDetails: shippingDetails,
        alternativePaymentMethods: apms,
        linkBillingNameWithCardHolderName: true);
    var theme = IOSThemeConfigurations();

    theme.logoImage = "assets/logo/app_logo.png";
    theme.backgroundColor = "#FFFFFF";
    configuration.iOSThemeConfigurations = theme;
    configuration.tokeniseType = PaymentSdkTokeniseType.MERCHANT_MANDATORY;
    return configuration;
  }

  Future<void> payPressed() async {
    FlutterPaytabsBridge.startCardPayment(generateConfig(), (event) {
      setState(() {
        if (event["status"] == "success") {
          // Handle transaction details here.
          var transactionDetails = event["data"];
          print(transactionDetails);
          if (transactionDetails["isSuccess"]) {
            Fluttertoast.showToast(
                msg: "Successfull Payment",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 4,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0);
            if (transactionDetails["isPending"]) {
              Fluttertoast.showToast(
                  msg: "Payment is Pending",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 4,
                  backgroundColor: Colors.yellow,
                  textColor: Colors.white,
                  fontSize: 16.0);
            }
          } else {
            Fluttertoast.showToast(
                msg: "Payment Failed",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 4,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0);
          }

          // print(transactionDetails["isSuccess"]);
        } else if (event["status"] == "error") {
          // Handle error here.
        } else if (event["status"] == "event") {
          // Handle events here.
        }
      });
    });
  }

  // Future<void> payWithTokenPressed() async {
  //   FlutterPaytabsBridge.startTokenizedCardPayment(
  //       generateConfig(), "*Token*", "*TransactionReference*", (event) {
  //     setState(() {
  //       if (event["status"] == "success") {
  //         // Handle transaction details here.
  //         var transactionDetails = event["data"];
  //         print(transactionDetails);
  //         if (transactionDetails["isSuccess"]) {
  //           print("successful transaction");
  //           if (transactionDetails["isPending"]) {
  //             print("transaction pending");
  //           }
  //         } else {
  //           print("failed transaction");
  //         }

  //         // print(transactionDetails["isSuccess"]);
  //       } else if (event["status"] == "error") {
  //         // Handle error here.
  //       } else if (event["status"] == "event") {
  //         // Handle events here.
  //       }
  //     });
  //   });
  // }

  Future<void> payWith3ds() async {
    FlutterPaytabsBridge.start3DSecureTokenizedCardPayment(
        generateConfig(),
        PaymentSDKSavedCardInfo("4111 11## #### 1111", "visa"),
        "*Token*", (event) {
      setState(() {
        if (event["status"] == "success") {
          // Handle transaction details here.
          var transactionDetails = event["data"];
          print(transactionDetails);
          if (transactionDetails["isSuccess"]) {
            print("successful transaction");
            if (transactionDetails["isPending"]) {
              print("transaction pending");
            }
          } else {
            print("failed transaction");
          }

          // print(transactionDetails["isSuccess"]);
        } else if (event["status"] == "error") {
          // Handle error here.
        } else if (event["status"] == "event") {
          // Handle events here.
        }
      });
    });
  }

  Future<void> payWithSavedCards() async {
    FlutterPaytabsBridge.startPaymentWithSavedCards(generateConfig(), false,
            (event) {
          setState(() {
            if (event["status"] == "success") {
              // Handle transaction details here.
              var transactionDetails = event["data"];
              print(transactionDetails);
              if (transactionDetails["isSuccess"]) {
                print("successful transaction");
                if (transactionDetails["isPending"]) {
                  print("transaction pending");
                }
              } else {
                print("failed transaction");
              }

              // print(transactionDetails["isSuccess"]);
            } else if (event["status"] == "error") {
              // Handle error here.
            } else if (event["status"] == "event") {
              // Handle events here.
            }
          });
        });
  }

  Future<void> apmsPayPressed() async {
    FlutterPaytabsBridge.startAlternativePaymentMethod(await generateConfig(),
            (event) {
          setState(() {
            if (event["status"] == "success") {
              print("<<<<<<<<<<<<< SUCCESS >>>>>>>>>>>");            }
            else if (event["status"] == "error") {
              print("<<<<<<<<<<<<< ERROR >>>>>>>>>>>");
            } else if (event["status"] == "event") {
              print("<<<<<<<<<<<<< EVENT >>>>>>>>>>>");            }
          });
        });
  }

  Future<void> applePayPressed() async {
    var configuration = PaymentSdkConfigurationDetails(
        profileId: "*Profile id*",
        serverKey: "*server key*",
        clientKey: "*client key*",
        cartId: "12433",
        cartDescription: "Flowers",
        merchantName: "Flowers Store",
        amount: 20.0,
        currencyCode: "AED",
        merchantCountryCode: "ae",
        merchantApplePayIndentifier: "merchant.com.bunldeId",
        simplifyApplePayValidation: true);
    FlutterPaytabsBridge.startApplePayPayment(configuration, (event) {
      setState(() {
        if (event["status"] == "success") {
          // Handle transaction details here.
          var transactionDetails = event["data"];
          print(transactionDetails);
        } else if (event["status"] == "error") {
          // Handle error here.
        } else if (event["status"] == "event") {
          // Handle events here.
        }
      });
    });
  }

  // Widget applePayButton() {
  //   if (Platform.isIOS) {
  //     return TextButton(
  //       onPressed: () {
  //         applePayPressed();
  //       },
  //       child: Text('Pay with Apple Pay'),
  //     );
  //   }
  //   return SizedBox(height: 0);
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PayTabs Options'),
          backgroundColor: MyTheme.accent_color,
          leading: IconButton(
            splashRadius: 15,
            padding: EdgeInsets.all(0.0),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Image.asset(
              'assets/icon/arrow.png',
              height: 20,
              width: 20,
              color: Colors.white,
              //color: MyTheme.dark_grey,
            ),
          ),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Text('$_instructions'),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      payPressed();
                    },
                    child: Text('Pay with Card'),
                  ),
                  // TextButton(
                  //   onPressed: () {
                  //     payWithTokenPressed();
                  //   },
                  //   child: Text('Pay with Token'),
                  // ),
                  // TextButton(
                  //   onPressed: () {
                  //     payWith3ds();
                  //   },
                  //   child: Text('Pay with 3ds'),
                  // ),
                  // TextButton(
                  //   onPressed: () {
                  //     payWithSavedCards();
                  //   },
                  //   child: Text('Pay with saved cards'),
                  // ),
                  TextButton(
                    onPressed: () {
                      apmsPayPressed();
                    },
                    child: Text('Pay with Alternative payment methods'),
                  ),
                  // SizedBox(height: 16),
                  // applePayButton()
                ])),
      ),
    );
  }
}
