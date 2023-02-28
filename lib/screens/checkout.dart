import 'dart:convert';

import 'package:elmazr3a/custom/box_decorations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:elmazr3a/my_theme.dart';
import 'package:elmazr3a/screens/order_list.dart';
import 'package:elmazr3a/screens/stripe_screen.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:elmazr3a/helpers/shared_value_helper.dart';
import 'package:elmazr3a/repositories/payment_repository.dart';
import 'package:elmazr3a/repositories/cart_repository.dart';
import 'package:elmazr3a/repositories/coupon_repository.dart';
import 'package:elmazr3a/helpers/shimmer_helper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart';
import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkApms.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkTokeniseType.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:elmazr3a/screens/offline_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../data_model/order_mini_response.dart';

class Checkout extends StatefulWidget {
  int order_id; // only need when making manual payment from order details
  bool
  manual_payment_from_order_details; // only need when making manual payment from order details
  String list;
  final bool isWalletRecharge;
  final double rechargeAmount;
  final String title;

  Checkout({Key key,
    this.order_id = 0,
    this.manual_payment_from_order_details = false,
    this.list = "both",
    this.isWalletRecharge = false,
    this.rechargeAmount = 0.0,
    this.title})
      : super(key: key);

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  var _selected_payment_method_index = 0;
  var _selected_payment_method = "";
  var _selected_payment_method_key = "";

  ScrollController _mainScrollController = ScrollController();
  TextEditingController _couponController = TextEditingController();
  var _paymentTypeList = [];
  bool _isInitial = true;
  var _totalString = ". . .";
  var _grandTotalValue = 0.00;
  var _subTotalString = ". . .";
  var _taxString = ". . .";
  var _shippingCostString = ". . .";
  var _discountString = ". . .";
  var _used_coupon_code = "";
  var _coupon_applied = false;
  BuildContext loadingcontext;
  String payment_type = "cart_payment";
  String _title;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    /*print("user data");
    print(is_logged_in.$);
    print(access_token.value);
    print(user_id.$);
    print(user_name.$);*/

    fetchAll();
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  fetchAll() {
    fetchList();

    if (is_logged_in.$ == true) {
      if (widget.isWalletRecharge || widget.manual_payment_from_order_details) {
        _grandTotalValue = widget.rechargeAmount;
        payment_type = "wallet_payment";
      } else {
        fetchSummary();
        //payment_type = payment_type;
      }
    }
  }

  fetchList() async {
    var paymentTypeResponseList = await PaymentRepository()
        .getPaymentResponseList(
        list: widget.list,
        mode: widget.isWalletRecharge ? "wallet" : "order");
    _paymentTypeList.addAll(paymentTypeResponseList);
    if (_paymentTypeList.length > 0) {
      _selected_payment_method = _paymentTypeList[0].payment_type;
      _selected_payment_method_key = _paymentTypeList[0].payment_type_key;
    }
    _isInitial = false;
    setState(() {});
  }

  fetchSummary() async {
    var cartSummaryResponse = await CartRepository().getCartSummaryResponse();

    if (cartSummaryResponse != null) {
      _subTotalString = cartSummaryResponse.sub_total;
      _taxString = cartSummaryResponse.tax;
      _shippingCostString = cartSummaryResponse.shipping_cost;
      _discountString = cartSummaryResponse.discount;
      _totalString = cartSummaryResponse.grand_total;
      _grandTotalValue = cartSummaryResponse.grand_total_value;
      _used_coupon_code = cartSummaryResponse.coupon_code;
      _couponController.text = _used_coupon_code;
      _coupon_applied = cartSummaryResponse.coupon_applied;
      setState(() {});
    }
  }

  reset() {
    _paymentTypeList.clear();
    _isInitial = true;
    _selected_payment_method_index = 0;
    _selected_payment_method = "";
    _selected_payment_method_key = "";
    setState(() {});

    reset_summary();
  }

  reset_summary() {
    _totalString = ". . .";
    _grandTotalValue = 0.00;
    _subTotalString = ". . .";
    _taxString = ". . .";
    _shippingCostString = ". . .";
    _discountString = ". . .";
    _used_coupon_code = "";
    _couponController.text = _used_coupon_code;
    _coupon_applied = false;

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchAll();
  }

  onPopped(value) {
    reset();
    fetchAll();
  }

  onCouponApply() async {
    print(">>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<");
    var coupon_code = _couponController.text.toString();
    if (coupon_code == "") {
      Fluttertoast.showToast(
        msg: AppLocalizations
            .of(context)
            .checkout_screen_coupon_code_warning,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    var couponApplyResponse =
    await CouponRepository().getCouponApplyResponse(coupon_code);
    if (couponApplyResponse.result == false) {
      Fluttertoast.showToast(
        msg: couponApplyResponse.message,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    reset_summary();
    fetchSummary();
  }

  onCouponRemove() async {
    var couponRemoveResponse =
    await CouponRepository().getCouponRemoveResponse();

    if (couponRemoveResponse.result == false) {
      Fluttertoast.showToast(
          msg: couponRemoveResponse.message,
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_LONG);
      return;
    }

    reset_summary();
    fetchSummary();
  }

  onPressPlaceOrderOrProceed() {
    if (_selected_payment_method == "") {
      Fluttertoast.showToast(
        msg: AppLocalizations
            .of(context)
            .common_payment_choice_warning,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    if (_selected_payment_method == "stripe_payment") {
      if (_grandTotalValue == 0.00) {
        Fluttertoast.showToast(
          msg: AppLocalizations
              .of(context)
              .common_nothing_to_pay,
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return StripeScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "wallet_system") {
      payPressedWIthPayTabs();
    } else if (_selected_payment_method == "cash_payment") {
      pay_by_cod();
    } else if (_selected_payment_method == "manual_payment" &&
        widget.manual_payment_from_order_details == false) {
      pay_by_manual_payment();
    } else if (_selected_payment_method == "manual_payment" &&
        widget.manual_payment_from_order_details == true) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OfflineScreen(
          order_id: widget.order_id,
          payment_type: "manual_payment",
          details: _paymentTypeList[_selected_payment_method_index].details,
          offline_payment_id: _paymentTypeList[_selected_payment_method_index]
              .offline_payment_id,
          isWalletRecharge: widget.isWalletRecharge,
          rechargeAmount: widget.rechargeAmount,
        );
      })).then((value) {
        onPopped(value);
      });
    }
  }


  // Future<http.Response> Send_id(String id) {
  //   return http.get( Uri.parse(
  //       'https://amyz.com.eg/tharwat/edit?id=$id',
  //   ),
  //   );
  // }


  Future<void> payPressedWIthPayTabs() async {
    payWithPayTaps();
    FlutterPaytabsBridge.startCardPayment(generateConfig(), (event) {
      setState(()  async {
        if (event["status"] == "success") {
          var transactionDetails = event["data"];
             if (transactionDetails["isSuccess"]) {
               payWithPayTaps();
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
            }}
             else {
               Fluttertoast.showToast(
                msg: "Payment Failed",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 4,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0);}}
        else if (event["status"] == "error") {
          Fluttertoast.showToast(
              msg: "Payment Failed",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 4,
              backgroundColor: MyTheme.accent_color,
              textColor: Colors.white,
              fontSize: 16.0);
        }
        else if (event["status"] == "event") {
          Fluttertoast.showToast(
              msg: "Payment Event Sent",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 4,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              fontSize: 16.0);
          // Handle events here.
        }
      });
    });
  }

  payWithPayTaps() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromPayTabs(_selected_payment_method_key);
    Navigator.of(loadingcontext).pop();
    if (orderCreateResponse.result == false) {
      Fluttertoast.showToast(
        msg: orderCreateResponse.message,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.of(context).pop();
      return;
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OrderList(from_checkout: true);
      }));
    }
  }

  pay_by_cod() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromCod(_selected_payment_method_key);
    Navigator.of(loadingcontext).pop();
    if (orderCreateResponse.result == false) {
      Fluttertoast.showToast(
        msg: orderCreateResponse.message,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.of(context).pop();
      return;
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OrderList(from_checkout: true);
      }));
    }
  }

  pay_by_manual_payment() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromManualPayment(_selected_payment_method_key);
    Navigator.pop(loadingcontext);
    if (orderCreateResponse.result == false) {
      Fluttertoast.showToast(
        msg: orderCreateResponse.message,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  onPaymentMethodItemTap(index) {
    if (_selected_payment_method_key !=
        _paymentTypeList[index].payment_type_key) {
      setState(() {
        _selected_payment_method_index = index;
        _selected_payment_method = _paymentTypeList[index].payment_type;
        _selected_payment_method_key = _paymentTypeList[index].payment_type_key;
      });
    }

    //print(_selected_payment_method);
    //print(_selected_payment_method_key);
  }

  onPressDetails() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            contentPadding:
            EdgeInsets.only(top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
            content: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 16.0),
              child: Container(
                height: 150,
                child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              child: Text(
                                AppLocalizations
                                    .of(context)
                                    .checkout_screen_subtotal,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Spacer(),
                            Text(
                              _subTotalString,
                              style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              child: Text(
                                AppLocalizations
                                    .of(context)
                                    .checkout_screen_tax,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Spacer(),
                            Text(
                              _taxString,
                              style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              child: Text(
                                AppLocalizations
                                    .of(context)
                                    .checkout_screen_shipping_cost,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Spacer(),
                            Text(
                              _shippingCostString,
                              style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              child: Text(
                                AppLocalizations
                                    .of(context)
                                    .checkout_screen_discount,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Spacer(),
                            Text(
                              _discountString,
                              style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                    Divider(),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              child: Text(
                                AppLocalizations
                                    .of(context)
                                    .checkout_screen_grand_total,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Spacer(),
                            Text(
                              _totalString,
                              style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              MaterialButton(
                child: Text(
                  AppLocalizations
                      .of(context)
                      .common_close_in_all_lower,
                  style: TextStyle(color: MyTheme.medium_grey),
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ],
          ),
    );
  }

  PaymentSdkConfigurationDetails generateConfig() {
    var billingDetails = BillingDetails(
        "${user_name.$}",
        "${user_email.$}",
        "${user_phone.$}",
        "",
        "",
        "",
        "",
        "");
    var shippingDetails = ShippingDetails(
        "John Smith",
        "email@domain.com",
        "+97311111111",
        "st. 12",
        "eg",
        "dubai",
        "dubai",
        "1233");
    List<PaymentSdkAPms> apms = [];
    apms.add(PaymentSdkAPms.AMAN);
    var configuration = PaymentSdkConfigurationDetails(
        profileId: "99337",
        serverKey: "SMJNGGTRHT-JDNBMJ96NK-6N662RBDWN",
        clientKey: "CBKMNP-69DT6D-Q2N6PG-7GPN26",
        // cartId: "1233",
        // cartDescription: "Flowers",
        // merchantName: "Flowers Store",
        screentTitle: "Pay with Card",
        amount: _grandTotalValue,
        showBillingInfo: true,
        forceShippingInfo: true,
        currencyCode: "EGP",
        merchantCountryCode: "EG",
        billingDetails: billingDetails,
        shippingDetails: shippingDetails,
        // alternativePaymentMethods: apms,
        // linkBillingNameWithCardHolderName: true
    );
    var theme = IOSThemeConfigurations();

    theme.logoImage = "assets/logo_with_name.png";
    theme.backgroundColor = "#FFFF00";
    configuration.iOSThemeConfigurations = theme;
    configuration.tokeniseType = PaymentSdkTokeniseType.MERCHANT_MANDATORY;
    return configuration;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: buildAppBar(context),
          bottomNavigationBar: buildBottomAppBar(context),
          body: Stack(
            children: [
              RefreshIndicator(
                color: MyTheme.accent_color,
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                displacement: 0,
                child: CustomScrollView(
                  controller: _mainScrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [

                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: buildPaymentMethodList(),
                        ),
                        Container(
                          height: 140,
                        )
                      ]),
                    ),
                  ],
                ),
              ),

              //Apply Coupon and order details container
              Align(
                alignment: Alignment.bottomCenter,
                child: widget.isWalletRecharge
                    ? Container()
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,

                    /*border: Border(
                      top: BorderSide(color: MyTheme.light_grey,width: 1.0),
                    )*/
                  ),
                  height:
                  widget.manual_payment_from_order_details ? 80 : 140,
                  //color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        widget.manual_payment_from_order_details == false
                            ? Padding(
                          padding:
                          const EdgeInsets.only(bottom: 16.0),
                          child: buildApplyCouponRow(context),
                        )
                            : Container(),
                        grandTotalSection(),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Row buildApplyCouponRow(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: (MediaQuery
              .of(context)
              .size
              .width - 32) * (2 / 3),
          child: TextFormField(
            controller: _couponController,
            readOnly: _coupon_applied,
            autofocus: false,
            decoration: InputDecoration(
                hintText: AppLocalizations
                    .of(context)
                    .checkout_screen_enter_coupon_code,
                hintStyle:
                TextStyle(fontSize: 14.0, color: MyTheme.textfield_grey),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: MyTheme.textfield_grey, width: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: const Radius.circular(8.0),
                    bottomLeft: const Radius.circular(8.0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: MyTheme.medium_grey, width: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: const Radius.circular(8.0),
                    bottomLeft: const Radius.circular(8.0),
                  ),
                ),
                contentPadding: EdgeInsets.only(left: 16.0)),
          ),
        ),
        !_coupon_applied
            ? Container(
          width: (MediaQuery
              .of(context)
              .size
              .width - 32) * (1 / 3),
          height: 42,
          child: MaterialButton(
            minWidth: MediaQuery
                .of(context)
                .size
                .width,
            //height: 50,
            color: MyTheme.accent_color,
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.only(
                  topRight: const Radius.circular(8.0),
                  bottomRight: const Radius.circular(8.0),
                )),
            child: Text(
              AppLocalizations
                  .of(context)
                  .checkout_screen_apply_coupon,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              onCouponApply();
            },
          ),
        )
            : Container(
          width: (MediaQuery
              .of(context)
              .size
              .width - 32) * (1 / 3),
          height: 42,
          child: MaterialButton(
            minWidth: MediaQuery
                .of(context)
                .size
                .width,
            //height: 50,
            color: MyTheme.accent_color,
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.only(
                  topRight: const Radius.circular(8.0),
                  bottomRight: const Radius.circular(8.0),
                )),
            child: Text(
              AppLocalizations
                  .of(context)
                  .checkout_screen_remove,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              onCouponRemove();
            },
          ),
        )
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) =>
            IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildPaymentMethodList() {
    if (_isInitial && _paymentTypeList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildListShimmer(item_count: 5, item_height: 100.0));
    } else if (_paymentTypeList.length > 0) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) {
            return SizedBox(
              height: 14,
            );
          },
          itemCount: _paymentTypeList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: buildPaymentMethodItemCard(index),
            );
          },
        ),
      );
    } else if (!_isInitial && _paymentTypeList.length == 0) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
                AppLocalizations
                    .of(context)
                    .common_no_payment_method_added,
                style: TextStyle(color: MyTheme.font_grey),
              )));
    }
  }

  GestureDetector buildPaymentMethodItemCard(index) {
    return GestureDetector(
      onTap: () {
        onPaymentMethodItemTap(index);
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            decoration: BoxDecorations.buildBoxDecoration_1().copyWith(
                border: Border.all(
                    color: _selected_payment_method_key ==
                        _paymentTypeList[index].payment_type_key
                        ? MyTheme.accent_color
                        : MyTheme.light_grey,
                    width: _selected_payment_method_key ==
                        _paymentTypeList[index].payment_type_key
                        ? 2.0
                        : 0.0)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                      width: 100,
                      height: 100,
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                          /*Image.asset(
                          _paymentTypeList[index].image,
                          fit: BoxFit.fitWidth,
                        ),*/
                          FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png',
                            image: _paymentTypeList[index].payment_type ==
                                "manual_payment"
                                ? _paymentTypeList[index].image
                                : _paymentTypeList[index].image,
                            fit: BoxFit.fitWidth,
                          ))),
                  Container(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            _paymentTypeList[index].title,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                height: 1.6,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: buildPaymentMethodCheckContainer(
                _selected_payment_method_key ==
                    _paymentTypeList[index].payment_type_key),
          )
        ],
      ),
    );
  }

  Widget buildPaymentMethodCheckContainer(bool check) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 400),
      opacity: check ? 1 : 0,
      child: Container(
        height: 16,
        width: 16,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0), color: Colors.green),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(FontAwesome.check, color: Colors.white, size: 10),
        ),
      ),
    );
    /* Visibility(
      visible: check,
      child: Container(
        height: 16,
        width: 16,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0), color: Colors.green),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(FontAwesome.check, color: Colors.white, size: 10),
        ),
      ),
    );*/
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
        color: Colors.transparent,
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MaterialButton(
              minWidth: MediaQuery
                  .of(context)
                  .size
                  .width,
              height: 50,
              color: MyTheme.accent_color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
              child: Text(
                widget.isWalletRecharge
                    ? AppLocalizations
                    .of(context)
                    .recharge_wallet_screen_recharge_wallet
                    : widget.manual_payment_from_order_details
                    ? AppLocalizations
                    .of(context)
                    .common_proceed_in_all_caps
                    : AppLocalizations
                    .of(context)
                    .checkout_screen_place_my_order,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                onPressPlaceOrderOrProceed();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget grandTotalSection() {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: MyTheme.soft_accent_color),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                AppLocalizations
                    .of(context)
                    .checkout_screen_total_amount,
                style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
              ),
            ),
            Visibility(
              visible: !widget.manual_payment_from_order_details,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () {
                    onPressDetails();
                  },
                  child: Text(
                    AppLocalizations
                        .of(context)
                        .common_see_details,
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                  widget.manual_payment_from_order_details
                      ? widget.rechargeAmount.toString()
                      : _totalString,
                  style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  loading() {
    showDialog(
        context: context,
        builder: (context) {
          loadingcontext = context;
          return AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    width: 10,
                  ),
                  Text("${AppLocalizations
                      .of(context)
                      .loading_text}"),
                ],
              ));
        });
  }
}
