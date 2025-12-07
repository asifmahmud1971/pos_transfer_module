import 'dart:developer';

import 'package:flutter/foundation.dart';

const bool isDev = true;
const bool isAutoFillUpTextField = isDev && kDebugMode;

String firstName = isAutoFillUpTextField == true ? 'Salman' : '';
String lastName = isAutoFillUpTextField == true ? 'Ahmed' : '';
String email = isAutoFillUpTextField == true ? 'salman+1@dinnova.io' : '';
String password = isAutoFillUpTextField == true ? '!1Password' : '';
String otp = isAutoFillUpTextField == true ? '111222' : '';
String username = isAutoFillUpTextField == true ? 'username' : '';
String dob = isAutoFillUpTextField == true ? '2004-11-03' : '';
String dialCode = isAutoFillUpTextField == true ? '+880' : '';
String phone = isAutoFillUpTextField == true ? '1682834622' : '';

void devLog(String text) {
  if (isDev && kDebugMode) log("DEV:: $text");
}

class AppImages {
  static final products = <String>[
    'https://cdn.competec.ch/images2/9/0/3/328390309/328390309_xxl3.jpg',
    'https://cdn.competec.ch/images2/4/6/9/285799964/285799964_xxl3.jpg',
    'https://cdn.competec.ch/images2/0/5/0/270554050/270554050_xxl3.jpg',
    'https://cdn.competec.ch/images2/1/7/6/259925671/259925671_xxl3.jpg',
    'https://demo.com/wp-content/uploads/2024/02/56.jpg',
  ];

  static final users = <String>[
    'https://media.istockphoto.com/photos/young-beautiful-woman-picture-id1294339577?b=1&k=20&m=1294339577&s=170667a&w=0&h=_5-SM0Dmhb1fhRdz64lOUJMy8oic51GB_2_IPlhCCnU='
  ];
}
