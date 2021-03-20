import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tree_clicker/BackendResponse.dart';
import 'package:tree_clicker/Multiplier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

import 'Splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(TreeTapper()));
}

class TreeTapper extends StatefulWidget {
  @override
  _TreeTapperState createState() => _TreeTapperState();
}

class _TreeTapperState extends State<TreeTapper> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, AsyncSnapshot snapshot) {
        // Show splash screen while waiting for app resources to load:
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(home: Splash());
        } else {
          // Loading is done, return the app:
          return MaterialApp(
            title: 'Tree Tapper',
            theme: ThemeData(
              primarySwatch: Colors.green,
            ),
            home: TapperHomepage(title: 'Tree Tapper'),
          );
        }
      },
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
  RewardedAd rewardedAd;

  // This timer triggers once a second and is responsible for adding "per second" values
  Timer timer;

  int trees = 0;
  int treeTotal = 0;
  int treesGoal = 0;

  double adFactor = 0.0;

  BigInt score = BigInt.from(0);

  var onTapVal = 1;
  var perSecVal = 0;

  // TODO: Balance these values so progression makes sense
  List treeThresholds = [100,200,300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500,1600,1700,1800,1900,2000,2100,2200,2300,2400,2500,2600,2700,2800,2900,3000,3100,3200,3300,3400,3500,3600,3700,3800,3900,4000,4100,4200,4300,4400,4500,4600];

  Image treeImage;
  int treeAsset = 0;
  int totalTreeAssets = 46;

  Image backgroundImage;
  int backgroundAsset = 0;
  int totalBackgroundAssets = 5;
  bool prestigeVisible = false;

  int rewardTimer = 0;
  int rewardFactor = 1;
  bool rewardVisible = false;

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
      adUnitId: 'ca-app-pub-xxx',
      request: AdRequest(),
      listener: AdListener(
        onRewardedAdUserEarnedReward: (RewardedAd ad, RewardItem reward) {
          rewardUser();
        },
        onAdClosed: (Ad ad) => adClosed(),
        onApplicationExit: (Ad ad) => ad.dispose(),
      ),
    );
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => incrementScoreLoop());
    getData();
    WidgetsBinding.instance.addObserver(this);
    treeImage = Image.asset("assets/img/tree-" + treeAsset.toString() + ".png", key: ValueKey<int>(treeAsset));
    backgroundImage = Image.asset("assets/img/background-" + backgroundAsset.toString() + ".png", fit: BoxFit.cover,);
    super.initState();
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
    rewardedAd.load();
    return Scaffold(
        body: SafeArea(
            child: Container(
      color: Color(0xff1b0000),
      child: Column(children: [
        Expanded(
          flex: 10,
          child: Row(
            children: [
              Flexible(
                flex: 5,
                child: Row(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Total trees:",
                          style: GoogleFonts.vt323(
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(treeTotal.toString(),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.pressStart2p(
                                  textStyle: TextStyle(
                                      color: Colors.white, fontSize: 16))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 5,
                child: Row(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Your trees:",
                          maxLines: 1,
                          style: GoogleFonts.vt323(
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText((trees * adFactor).toString(),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: GoogleFonts.pressStart2p(
                                textStyle: TextStyle(
                                    color: Colors.white, fontSize: 16))),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                      child: Icon(
                        Icons.info,
                        color: Colors.white,
                      ),
                      onTap: () => launch("https://tree-tapper.com/faq")),
                ),
              ),
            ],
          ),
        ),
        // doing + 1 here so the indicator is visible even if no tree has been planted yet
        Expanded(
          flex: 1,
          child: LinearProgressIndicator(
              valueColor:
                  new AlwaysStoppedAnimation<Color>(Color((0xffffc107))),
              backgroundColor: Color(0xff1b0000),
              value: (trees.toDouble() * adFactor + 1) /
                  (treesGoal.toDouble() + 1),
              semanticsLabel: "trees progress indicator"),
        ),

        Expanded(
          flex: 100,
          child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              alignment: AlignmentDirectional.center,
              children: [
                AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Column(children: [Expanded(child: backgroundImage)], key: ValueKey<int>(backgroundAsset))),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AutoSizeText("CO2 collected",
                            maxLines: 1,
                            style: GoogleFonts.vt323(
                                textStyle: TextStyle(fontSize: 20))),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AutoSizeText(score.toString() + "kg",
                            maxLines: 1,
                            style: GoogleFonts.pressStart2p(
                                textStyle: TextStyle(fontSize: 25))),
                      ),
                    ),
                    Expanded(
                        flex: 11,
                        child: GestureDetector(
                          onTap: () {
                            incrementScoreManual();
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: treeImage,
                            ),
                          ),
                        ))
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => playAd(),
                          child: Icon(Icons.play_arrow),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xffffc107)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      side: BorderSide(
                                          color: Color(0xff003300))))),
                        ),
                        ElevatedButton(
                          onPressed: () => Share.share(
                              'Check out Tree Tapper!\n' +
                                  'I planted ' +
                                  (trees * adFactor).toString() +
                                  " real trees playing this game!\n" +
                                  "Download it at https://tree-tapper.com",
                              subject: 'Check out Tree Tapper!'),
                          child: Icon(Icons.share),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.green),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      side: BorderSide(
                                          color: Color(0xff003300))))),
                        ),
                        Visibility(
                            visible: rewardVisible,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                    Color((0xffffc107))),
                                value: rewardTimer / 60,
                                semanticsLabel:
                                    "circular reward timing indicator",
                              ),
                            )),
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
                  ),
                )
              ]),
        ),

        Expanded(
          flex: 1,
          child: LinearProgressIndicator(
              // This is really ugly. Basically:
              // (current score - last threshold) / (next threshold - last threshold) with a lot of edge cases and type conversions
              value: (((score % BigInt.from(treeThresholds.last) - BigInt.from(treeAsset == 0 ? 0 : treeThresholds[treeAsset - 1])).toDouble()) /
                      ((treeThresholds[treeAsset % treeThresholds.last] - (treeAsset == 0 ? 0 : treeThresholds[treeAsset - 1])).toDouble())) % 1,
              semanticsLabel: "game progress indicator"),
        ),
        Expanded(
          flex: 10,
          child: Row(
            children: [
              Flexible(
                flex: 1,
                child: Row(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: AutoSizeText(
                          "CO2 per tap:",
                          maxLines: 1,
                          style: GoogleFonts.vt323(
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(onTapVal.toString(),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.pressStart2p(
                                  textStyle: TextStyle(
                                      color: Colors.white, fontSize: 16))),
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
                        child: AutoSizeText(
                          "CO2 / s:",
                          maxLines: 1,
                          style: GoogleFonts.vt323(
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(perSecVal.toString(),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: GoogleFonts.pressStart2p(
                                  textStyle: TextStyle(
                                      color: Colors.white, fontSize: 16))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
            flex: 80,
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
                                      semanticsLabel: multipliers[index].name,
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
                                          alignment: Alignment.bottomRight,
                                          child: AutoSizeText(
                                            multipliers[index].count.toString(),
                                            maxLines: 1,
                                            style: GoogleFonts.pressStart2p(
                                                textStyle: TextStyle(
                                                    color: Colors.white,
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
                                          multipliers[index].cost.toString() +
                                          "kg",
                                      style: GoogleFonts.vt323(
                                          textStyle:
                                              TextStyle(color: Colors.white))),
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
                                          textStyle:
                                              TextStyle(color: Colors.white))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                })))
      ]),
    )));
  }

  playAd() async {
    if (await rewardedAd.isLoaded()) {
      rewardedAd.show();
    } else {
      rewardedAd.load();
    }
  }

  // In order to correctly display the reward timer, this can't be done in rewardUser()
  adClosed() {
    rewardedAd.dispose();
    setState(() {
      if (rewardTimer > 0) {
        rewardVisible = true;
      }
    });
  }

  // This is called after the user watched an ad
  rewardUser() {
    rewardTimer = rewardTimer + 60;
    rewardFactor = 2;
    calcScoreValues();
    incrementTrees();
    showToast("Congrats! You helped plant a tree. Enjoy double points for one minute!");
  }

  // This gets called on loop (1/s)
  incrementScoreLoop() {
    int scoreIncrement = 0;
    multipliers.forEach((multiplier) {
      if (multiplier.type == MultiplierType.perSecond)
        scoreIncrement += multiplier.count * multiplier.multiplicationFactor;
    });
    if (rewardTimer > 0) {
      setState(() {
        rewardTimer--;
      });
    }
    if (rewardVisible && rewardTimer == 0) {
      rewardFactor = 1;
      setState(() {
        rewardVisible = false;
      });
      calcScoreValues();
    }
    scoreIncrement = scoreIncrement * rewardFactor;

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
    scoreIncrement = scoreIncrement * rewardFactor;
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
      onTapVal = onTapVal * rewardFactor;

      perSecVal = 0;
      multipliers.forEach((multiplier) {
        if (multiplier.type == MultiplierType.perSecond)
          perSecVal += multiplier.count * multiplier.multiplicationFactor;
      });
      perSecVal = perSecVal * rewardFactor;
    });
  }

  addScore(BigInt bigI) {
    score = score + bigI;
    checkAssetUpdates();
  }

  // Check if tree asset changed or prestige button should be visible
  void checkAssetUpdates() {
    if (treeAsset >= totalTreeAssets) treeAsset = 0;
    // This needs to be a while-loop in case there is every more than one asset swap per method call
    while ((score % BigInt.from(treeThresholds.last + 1)) >=
        BigInt.from(treeThresholds[treeAsset])) {
      treeAsset++;
      setState(() {
        treeImage = Image.asset(
          "assets/img/tree-" + treeAsset.toString() + ".png",
          key: ValueKey<int>(treeAsset),
        );
      });
    }

    // Enable prestige button if score threshold is reached
    if (score >= BigInt.from(treeThresholds[2])) {
      setState(() {
        prestigeVisible = true;
      });
    }
  }

  // This gets called when the prestige button is pressed. Changes the background and resets progress.
  void upgradeBackground() {
    // Reset everything to 0
    score = BigInt.from(0);
    multipliers.forEach((multiplier) {
      multiplier.count = 0;
    });
    onTapVal = 0;
    perSecVal = 0;
    backgroundAsset++;
    if (backgroundAsset > 4) backgroundAsset = 0;
    treeAsset = 0;
    saveData();

    // Change background asset
    setState(() {
      backgroundImage = Image.asset("assets/img/background-" + backgroundAsset.toString() + ".png", fit: BoxFit.cover,);
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
    treeAsset = prefs.getInt("treeAssets") ?? 0;
    backgroundAsset = prefs.getInt("backgroundAsset") ?? 0;

    setState(() {
      backgroundAsset = prefs.getInt("backgroundAsset") ?? 0;
      if (treeTotal == 0) treeTotal = prefs.getInt("treeTotal") ?? 0;
      if (treesGoal == 0) treesGoal = prefs.getInt("treeGoal") ?? 0;
      if (adFactor == 0) adFactor = prefs.getDouble("adFactor") ?? 0.0;
    });

    calcScoreValues();
    BackendResponse backendResponse = await fetchBackendResponse();
    setState(() {
      if (backendResponse.treeTotal != null)
        treeTotal = backendResponse.treeTotal;
      if (backendResponse.treeGoal != null)
        treesGoal = backendResponse.treeGoal;
      if (backendResponse.adFactor != null) adFactor = backendResponse.adFactor;
    });
  }

  // Save data to SharedPreferences
  saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("treesPlanted", trees);
    prefs.setString("score", score.toString());
    multipliers.forEach((multiplier) {
      prefs.setInt(multiplier.name, multiplier.count);
    });

    prefs.setInt("backgroundAsset", backgroundAsset);
    prefs.setInt("treeAsset", treeAsset);

    prefs.setInt("treeTotal", treeTotal);
    prefs.setInt("treeGoal", treesGoal);
    prefs.setDouble("adFactor", adFactor);
  }

  // Fetch remote data from server
  Future<BackendResponse> fetchBackendResponse() async {
    // TODO: replace with correct URL once backend is set up
    final response = await http.get(
        Uri.https('run.mocky.io', "/v3/acc51187-a4bf-442d-a2cd-027e07dd2745"));
    if (response.statusCode == 200) {
      BackendResponse backendResponse;
      try {
        backendResponse = BackendResponse.fromJson(jsonDecode(response.body));
      } on FormatException {
        backendResponse =
            BackendResponse(treeTotal: null, treeGoal: null, adFactor: null);
      }
      return backendResponse;
    } else {
      return BackendResponse(treeTotal: null, treeGoal: null, adFactor: null);
    }
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
