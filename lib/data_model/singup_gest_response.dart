// To parse this JSON data, do
//
//     final signupResponse = signupResponseFromJson(jsonString);

import 'dart:convert';

SignupGestResponse signupGestResponseFromJson(String str) => SignupGestResponse.fromJson(json.decode(str));

String signupGestResponseToJson(SignupGestResponse data) => json.encode(data.toJson());

class SignupGestResponse {
  SignupGestResponse({
    this.result,
    this.message,
    this.user_id,
  });

  bool result;
  String message;
  int user_id;

  factory SignupGestResponse.fromJson(Map<String, dynamic> json) => SignupGestResponse(
    result: json["result"],
    message: json["message"],
    user_id: json["user_id"],
  );

  Map<String, dynamic> toJson() => {
    "result": result,
    "message": message,
    "user_id": user_id,
  };
}