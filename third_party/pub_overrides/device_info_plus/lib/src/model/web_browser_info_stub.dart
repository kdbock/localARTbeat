// Stub used for non-web compilation paths so mobile/desktop builds do not
// pull in package:web transitively.

import 'package:device_info_plus_platform_interface/model/base_device_info.dart';

enum BrowserName {
  firefox,
  samsungInternet,
  opera,
  msie,
  edge,
  chrome,
  safari,
  unknown,
}

class WebBrowserInfo implements BaseDeviceInfo {
  WebBrowserInfo({
    this.appCodeName,
    this.appName,
    this.appVersion,
    this.deviceMemory,
    this.language,
    this.languages,
    this.platform,
    this.product,
    this.productSub,
    this.userAgent,
    this.vendor,
    this.vendorSub,
    this.maxTouchPoints,
    this.hardwareConcurrency,
  });

  final String? appCodeName;
  final String? appName;
  final String? appVersion;
  final double? deviceMemory;
  final String? language;
  final List<dynamic>? languages;
  final String? platform;
  final String? product;
  final String? productSub;
  final String? userAgent;
  final String? vendor;
  final String? vendorSub;
  final int? hardwareConcurrency;
  final int? maxTouchPoints;

  BrowserName get browserName => BrowserName.unknown;

  static WebBrowserInfo fromMap(Map<String, dynamic> map) => WebBrowserInfo(
    appCodeName: map['appCodeName'] as String?,
    appName: map['appName'] as String?,
    appVersion: map['appVersion'] as String?,
    deviceMemory: (map['deviceMemory'] as num?)?.toDouble(),
    language: map['language'] as String?,
    languages: map['languages'] as List<dynamic>?,
    platform: map['platform'] as String?,
    product: map['product'] as String?,
    productSub: map['productSub'] as String?,
    userAgent: map['userAgent'] as String?,
    vendor: map['vendor'] as String?,
    vendorSub: map['vendorSub'] as String?,
    hardwareConcurrency: map['hardwareConcurrency'] as int?,
    maxTouchPoints: map['maxTouchPoints'] as int?,
  );

  @override
  Map<String, dynamic> get data => <String, dynamic>{
    'browserName': browserName,
    'appCodeName': appCodeName,
    'appName': appName,
    'appVersion': appVersion,
    'deviceMemory': deviceMemory,
    'language': language,
    'languages': languages,
    'platform': platform,
    'product': product,
    'productSub': productSub,
    'userAgent': userAgent,
    'vendor': vendor,
    'vendorSub': vendorSub,
    'hardwareConcurrency': hardwareConcurrency,
    'maxTouchPoints': maxTouchPoints,
  };

  @Deprecated('use data instead')
  Map<String, dynamic> toMap() => data;
}
