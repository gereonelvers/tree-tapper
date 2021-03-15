import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// This class manages the ad-showing process
class AdManager {
  InterstitialAd myInterstitial;

  bool playAd() {
    print('init ad');
    final AdListener listener = AdListener(
      onAdLoaded: (Ad ad) => {myInterstitial.show()},
      onAdFailedToLoad: (Ad ad, LoadAdError error) => _toastNegative(),
      onAdOpened: (Ad ad) => {print('Ad opened.')},
      onAdClosed: (Ad ad) => {ad.dispose()},
      onApplicationExit: (Ad ad) => {ad.dispose()},
    );
    myInterstitial = InterstitialAd(
      // TODO: Set own key.
      adUnitId: 'ca-app-pub-XXXX',
      request: AdRequest(),
      listener: listener,
    );
    myInterstitial.load();
    return true;
  }

  _toastNegative() {
    Fluttertoast.showToast(
        msg: "No ads right now, sorry",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0);
    return false;
  }
}
