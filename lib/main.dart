import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tree_clicker/Multiplier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tree Tapper',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: TapperHomepage(title: 'Tree Tapper'),
    );
  }
}

class TapperHomepage extends StatefulWidget {
  TapperHomepage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  TapperHomePageState createState() => TapperHomePageState();
}

class TapperHomePageState extends State<TapperHomepage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController controller;

  int prestigeScore = 0;
  bool prestigeVisible = false;

  RewardedAd rewardedAd;

  Timer timer;
  int trees = 0;
  int treesGlobal = 50;
  int treesGoal = 100;
  BigInt score = BigInt.from(0);
  var onTapVal = 1;
  var perSecVal = 0;

  // TODO: This is inefficient. Fix it. Also improve image scaling.
  Image treeImg = Image(
    image: AssetImage("assets/img/tree-full.png"),
    height: 250,
  );
  AssetImage backImg = AssetImage("assets/img/background.png");

  // Syntax for new Multipliers: name (must be unique!), image (svg), multiplicationFactor, count, cost, type
  List<Multiplier> multipliers = [
    Multiplier("Leaves", "assets/img/leaf.svg", 1, 0, 5, MultiplierType.onTap),
    Multiplier("Branch", "assets/img/branch.svg", 2, 0, 9, MultiplierType.onTap),
    Multiplier("Stump", "assets/img/stump.svg", 3, 0, 13, MultiplierType.onTap),
    Multiplier("Mushroom", "assets/img/mushroom.svg", 4, 0, 20, MultiplierType.onTap),
    Multiplier("Bark", "assets/img/bark.svg", 1, 0, 50, MultiplierType.perSecond),
    Multiplier("Roots", "assets/img/root.svg", 2, 0, 90, MultiplierType.perSecond),
    Multiplier("Birds", "assets/img/bird.svg", 5, 0, 200, MultiplierType.perSecond),
    Multiplier("River", "assets/img/river.svg", 10, 0, 700, MultiplierType.perSecond),
    Multiplier("Squirrels", "assets/img/squirrel.svg", 25, 0, 2500, MultiplierType.perSecond),
    Multiplier("Leaves1", "assets/img/leaf.svg", 1, 0, 5, MultiplierType.onTap),
    Multiplier("Branch1", "assets/img/branch.svg", 2, 0, 9, MultiplierType.onTap),
    Multiplier("Stump1", "assets/img/stump.svg", 3, 0, 13, MultiplierType.onTap),
    Multiplier("Mushroom1", "assets/img/mushroom.svg", 4, 0, 20, MultiplierType.onTap),
    Multiplier("Bark1", "assets/img/bark.svg", 1, 0, 50, MultiplierType.perSecond),
    Multiplier("Roots1", "assets/img/root.svg", 2, 0, 90, MultiplierType.perSecond),
    Multiplier("Birds1", "assets/img/bird.svg", 5, 0, 200, MultiplierType.perSecond),
    Multiplier("River1", "assets/img/river.svg", 10, 0, 700, MultiplierType.perSecond),
    Multiplier("Squirrels1", "assets/img/squirrel.svg", 25, 0, 2500, MultiplierType.perSecond),
  ];

  @override
  void initState() {
    rewardedAd = RewardedAd(
      // TODO: Set own ID
      adUnitId: 'ca-app-pub-XXX',
      request: AdRequest(),
      listener: AdListener(
        onRewardedAdUserEarnedReward: (RewardedAd ad, RewardItem reward) {
          rewardUser();
        },
        onAdClosed: (Ad ad) => ad.dispose(),
        onApplicationExit: (Ad ad) => ad.dispose(),
      ),
    );
    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => incrementScoreLoop());
    getData();
    WidgetsBinding.instance.addObserver(this);
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            setState(() {});
          });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    saveData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Colors.black);
    rewardedAd.load();
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Expanded(
          child: Container(
              color: Color(0xff1b0000),
              child: Column(children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(8),
                              child: AutoSizeText(
                                "You planted " +
                                    trees.toString() +
                                    " out of " +
                                    treesGlobal.toString() +
                                    " trees",
                                maxLines: 1,
                                style: GoogleFonts.vt323(
                                    textStyle: TextStyle(
                                        color: Colors.white, fontSize: 20)),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                // doing + 1 here so the indicator is visible even if no tree has been planted yet
                LinearProgressIndicator(
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Color((0xffffc107))),
                    backgroundColor: Color(0xff1b0000),
                    value: trees.toDouble() + 1 / treesGoal.toDouble() + 1,
                    semanticsLabel: "trees progress indicator"),
                Expanded(
                    child: Container(
                  constraints: BoxConstraints.expand(),
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    image: backImg,
                    fit: BoxFit.fitHeight,
                  )),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: AutoSizeText("CO2 collected",
                                  maxLines: 1,
                                  style: GoogleFonts.vt323(
                                      textStyle: TextStyle(fontSize: 20))),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: AutoSizeText(score.toString() + "kg",
                                  maxLines: 1,
                                  style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(fontSize: 25))),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      incrementScoreManual();
                                    },
                                    //child: ScaleTransition(
                                    // scale: _treeAnimation,
                                    child: treeImg,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => playAd(),
                              child: Icon(Icons.play_arrow),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Color(0xffffc107)),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                          side: BorderSide(
                                              color: Color(0xff003300))))),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  launch("https://tree-tapper.com"),
                              child: Icon(Icons.info),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                          side: BorderSide(
                                              color: Color(0xff003300))))),
                            ),
                            Visibility(
                                visible: prestigeVisible,
                                child: ElevatedButton(
                                    onPressed: () => upgradeBackground(),
                                    child: Icon(Icons.plus_one),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.green),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25.0),
                                                side: BorderSide(
                                                    color: Color(0xff003300)))))))
                          ],
                        ),
                      )
                    ],
                  ),
                )),

                LinearProgressIndicator(
                    value: score.toDouble() / 300.toDouble(),
                    semanticsLabel: "prestige progress indicator"),
                Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Row(
                        children: [
                          Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                "CO2 per tap:",
                                style: GoogleFonts.vt323(
                                    textStyle: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              )),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(onTapVal.toString(),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.pressStart2p(
                                        textStyle: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Row(
                        children: [
                          Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                "CO2 / s:",
                                maxLines: 1,
                                style: GoogleFonts.vt323(
                                    textStyle: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              )),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: AutoSizeText(perSecVal.toString(),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    style: GoogleFonts.pressStart2p(
                                        textStyle: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                      primary: false,
                      padding: const EdgeInsets.all(5),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: 3,
                      children: List.generate(multipliers.length, (index) {
                        return Center(
                          child: GestureDetector(
                            onTap: () {
                              tapMultiplier(index);
                            },
                            child: Container(
                              color: Color(0xff003300),
                              alignment: Alignment.center,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SvgPicture.asset(
                                            multipliers[index].image,
                                            semanticsLabel:
                                                multipliers[index].name,
                                            color: Colors.white,
                                            height: 35,
                                            width: 35,
                                            alignment: Alignment.topLeft,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Align(
                                              alignment: Alignment.topCenter,
                                              child: Text(
                                                "x ",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.vt323(
                                                    textStyle: TextStyle(
                                                        color: Colors.white)),
                                              )),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: AutoSizeText(
                                                  multipliers[index]
                                                      .count
                                                      .toString(),
                                                  maxLines: 1,
                                                  style:
                                                      GoogleFonts.pressStart2p(
                                                          textStyle: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 20)),
                                                )),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Text(
                                            "Price: -" +
                                                multipliers[index]
                                                    .cost
                                                    .toString() +
                                                "kg",
                                            style: GoogleFonts.vt323(
                                                textStyle: TextStyle(
                                                    color: Colors.white))),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Text(
                                            "Effect: +" +
                                                multipliers[index]
                                                    .multiplicationFactor
                                                    .toString() +
                                                Multiplier.getStringForType(
                                                    multipliers[index].type),
                                            style: GoogleFonts.vt323(
                                                textStyle: TextStyle(
                                                    color: Colors.white))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })),
                )
              ])))
    ])));
  }

  playAd() async {
    if (await rewardedAd.isLoaded()) {
      rewardedAd.show();
    } else {
      rewardedAd.load();
    }
  }

  rewardUser() {
    addScore(BigInt.from(score / BigInt.from(10)) + BigInt.from(1));
    incrementTrees();
    showToast("Congrats! You helped plant a tree. Enjoy the reward.");
  }

  // This gets called on loop (1/s)
  incrementScoreLoop() {
    int scoreIncrement = 0;
    multipliers.forEach((multiplier) {
      if (multiplier.type == MultiplierType.perSecond)
        scoreIncrement += multiplier.count * multiplier.multiplicationFactor;
    });

    setState(() {
      addScore(BigInt.from(scoreIncrement));
    });
  }

  // This gets called if the tree is tapped manually
  incrementScoreManual() {
    int scoreIncrement = 1;
    multipliers.forEach((multiplier) {
      if (multiplier.type == MultiplierType.onTap)
        scoreIncrement += multiplier.count * multiplier.multiplicationFactor;
    });

    setState(() {
      addScore(BigInt.from(scoreIncrement));
    });
  }

  incrementTrees() {
    setState(() {
      trees = trees + 1;
    });
    saveData();
  }

  // This gets called if a multiplier is tapped and checks if an upgrade can be purchased
  tapMultiplier(int id) {
    if (score >= BigInt.from(multipliers[id].cost)) {
      setState(() {
        score = score - BigInt.from(multipliers[id].cost);
        multipliers[id].count++;
        calcScoreValues();
      });
    } else {
      showToast("Not enough CO2 budget");
    }
  }

  // Calculates the multiplier values displayed (CO2 per tap / CO2 per second)
  calcScoreValues() {
    setState(() {
      onTapVal = 1;
      multipliers.forEach((multiplier) {
        if (multiplier.type == MultiplierType.onTap)
          onTapVal += multiplier.count * multiplier.multiplicationFactor;
      });

      perSecVal = 0;
      multipliers.forEach((multiplier) {
        if (multiplier.type == MultiplierType.perSecond)
          perSecVal += multiplier.count * multiplier.multiplicationFactor;
      });
    });
  }

  addScore(BigInt bigI) {
    score = score + bigI;
    checkAssetUpdates();
  }

  // Check if tree asset changed or prestige button should be visible
  void checkAssetUpdates() {
    List<String> treeAssetStrings = [
      "assets/img/tree-full.png",
      "assets/img/tree-min.png"
    ];
    // TODO: Implement tree asset swapping on threshold hit

    // Enable prestige button if score threshold is reached
    setState(() {
      if (score > BigInt.from(300)) {
        prestigeVisible = true;
      }
    });
  }

  // Update the background image to reflect current prestige score
  void upgradeBackground() {
    List<String> backgroundAssetStrings = [
      "assets/img/background.png",
      "assets/img/background-2.png"
    ];
    score = BigInt.from(0);
    multipliers.forEach((multiplier) {
      multiplier.count = 0;
    });
    prestigeScore++;
    saveData();
    setState(() {
      backImg = AssetImage(backgroundAssetStrings[
          prestigeScore % backgroundAssetStrings.length]);
      prestigeVisible = false;
    });
  }

  void showToast(String t) {
    Fluttertoast.showToast(
        msg: t,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  // Get data from SharedPreferences
  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var spScore = prefs.getString("score") ?? "0";
    score = BigInt.parse(spScore);
    trees = prefs.getInt("treesPlanted") ?? 0;
    multipliers.forEach((multiplier) {
      multiplier.count = prefs.getInt(multiplier.name) ?? 0;
    });
    prestigeScore = prefs.getInt("prestigeScore") ?? 0;
    calcScoreValues();
  }

  // Save data to SharedPreferences
  saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("treesPlanted", trees);
    prefs.setString("score", score.toString());
    multipliers.forEach((multiplier) {
      prefs.setInt(multiplier.name, multiplier.count);
    });
    prefs.setInt("prestigeScore", prestigeScore);
  }

  // Watch application lifecycle so data can be saved on pause
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        saveData();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }
}
