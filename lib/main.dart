import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tree_clicker/Multiplier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';

import 'AdManager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
    with TickerProviderStateMixin {
  AdManager adManager = AdManager();
  Timer timer;
  int trees = 0;
  BigInt score = BigInt.from(0);

  // AnimationController _controller;
  //Animation<double> _treeAnimation;
  Image treeImg = Image(
    image: AssetImage("assets/img/tree-min.png"),
    height: 160,
  );
  AssetImage backImg = AssetImage("assets/img/background.png");

  // Syntax for new Multipliers: name, image (svg), multiplicationFactor, count, cost, type
  List<Multiplier> multipliers = [
    Multiplier("Leaves", "assets/img/leaf.svg", 1, 0, 5, MultiplierType.onTap),
    Multiplier("Branch", "assets/img/branch.svg", 2, 0, 9, MultiplierType.onTap),
    Multiplier("Stump", "assets/img/stump.svg", 3, 0, 13, MultiplierType.onTap),
    Multiplier("Mushroom", "assets/img/mushroom.svg", 4, 0, 20, MultiplierType.onTap),
    Multiplier("Bark", "assets/img/bark.svg", 1, 0, 50, MultiplierType.perSecond),
    Multiplier("Roots", "assets/img/root.svg", 2, 0, 90, MultiplierType.perSecond),
    Multiplier("Birds", "assets/img/bird.svg", 5, 0, 200, MultiplierType.perSecond),
    Multiplier("River", "assets/img/river.svg", 10, 0, 700, MultiplierType.perSecond),
    Multiplier("Squirrels", "assets/img/squirrel.svg", 25, 0, 2500, MultiplierType.perSecond)
  ];

  @override
  void initState() {
    super.initState();
    getData();
    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => incrementScoreLoop());
  }

  @override
  void dispose() {
    timer?.cancel();
    saveData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Colors.black);
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Expanded(
          child: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
            image: DecorationImage(
          image: backImg,
          fit: BoxFit.fitHeight,
        )),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("CO2 collected",
                  style: GoogleFonts.vt323(textStyle: TextStyle(fontSize: 20))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(score.toString() + "kg",
                  style: GoogleFonts.pressStart2p(
                      textStyle: TextStyle(fontSize: 30))),
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
      )),
      Expanded(
          child: Container(
              color: Color(0xff1b0000),
              child: Column(children: [
                Row(
                  children: [
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "Real trees planted: ",
                              style: GoogleFonts.vt323(
                                  textStyle: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ))),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(trees.toString(),
                          style: GoogleFonts.pressStart2p(
                              textStyle: TextStyle(
                                  color: Colors.white, fontSize: 25))),
                    ),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () => {playAd()},
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.play_arrow_rounded),
                            ))),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () =>
                                {launch("https://tree-tapper.com")},
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.info),
                            ))),
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
                                              alignment: Alignment.bottomCenter,
                                              child: Text(
                                                "x ",
                                                style: GoogleFonts.vt323(
                                                    textStyle: TextStyle(
                                                        color: Colors.white)),
                                              )),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Text(
                                                  multipliers[index]
                                                      .count
                                                      .toString(),
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

  playAd() {
    if (adManager.playAd()) {
      var reward = score / BigInt.from(10);
      addScore(BigInt.from(score / BigInt.from(10)));
      incrementTrees();
      Fluttertoast.showToast(
          msg: "Earned " +
              reward.toInt().toString() +
              " points by watching an ad.\n Good job saving the planet!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

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
  }

  tapMultiplier(int id) {
    if (score > BigInt.from(multipliers[id].cost)) {
      setState(() {
        score = score - BigInt.from(multipliers[id].cost);
        multipliers[id].count++;
      });
    } else {
      Fluttertoast.showToast(
          msg: "Not enough CO2 budget",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  addScore(BigInt bigI) {
    score = score + bigI;
    if (score > BigInt.from(200)) {
      setState(() {
        treeImg = Image(
          image: AssetImage("assets/img/tree-full.png"),
          height: 280,
        );
      });
    }
    if (score > BigInt.from(600)) {
      setState(() {
        backImg = AssetImage("assets/img/background-2.png");
      });
    }
  }

  Future<BigInt> saveScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return BigInt.from(prefs.getString("score") ?? 0);
  }

  // Get data from SharedPreferences (for persistence)
  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    score = BigInt.parse(prefs.getString("score") ?? "0");
    var i = prefs.getInt("treesPlanted");
    trees = i == null ? 0 : i;
  }

  saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("treesPlanted", trees);
    prefs.setString("score", score.toString());
    print('Saving?');
  }
}
