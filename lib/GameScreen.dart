import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'BackendResponse.dart';
import 'Multiplier.dart';
import 'InfoScreen.dart';

class GameScreen extends StatefulWidget {
  GameScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  TapperHomePageState createState() => TapperHomePageState();
}

class TapperHomePageState extends State<GameScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool isFirstLaunch = true;
  bool acceptedGDPR = false;

  RewardedAd rewardedAd;

  // This timer triggers once a second and is responsible for adding "per second" values
  Timer timer;

  // These variables keep track of the real trees (user, global, goal)
  double trees = 0;
  int treeTotal = 0;
  int treesGoal = 0;

  // This value is how many trees a single ad-watch earns on average
  double adFactor = 1;

  // These variables relate to the user's score
  int collectedCO2 = 0;
  int score = 0;
  int scoreGoal = 1;
  AnimationController lottieController;

  int initialScoreGoal = 200;

  // These are the base values earned per tap/second
  var onTapVal = 1;
  var perSecVal = 0;

  // These values deal with the image assets
  Image treeImage;
  int level = -1;
  int totalTreeAssets = 46;
  Image backgroundImage;
  int backgroundAsset = -1;
  int totalBackgroundAssets = 7;
  bool prestigeVisible = false;

  // These variables relate to the reward earned by watching an ad
  int rewardTimer = 0;
  int rewardFactor = 1;
  bool rewardVisible = false;

  // Syntax for new Multipliers: name (must be unique!), image (svg), multiplicationFactor, count, cost, type
  List<Multiplier> multipliers = [
    // On Tap Multipliers
    Multiplier("Leaves", "assets/img/leaf.svg", 1, 0, 5, MultiplierType.onTap),
    Multiplier("Branch", "assets/img/branch.svg", 5, 0, 100, MultiplierType.onTap),
    Multiplier("Stump", "assets/img/stump.svg", 10, 0, 300, MultiplierType.onTap),
    Multiplier("Mushroom", "assets/img/mushroom.svg", 25, 0, 1000, MultiplierType.onTap),
    Multiplier("Bark", "assets/img/bark.svg", 50, 0, 3000, MultiplierType.onTap),
    Multiplier("Roots", "assets/img/root.svg", 100, 0, 8000, MultiplierType.onTap),
    // Per Second Multipliers
    Multiplier("Birds", "assets/img/bird.svg", 1, 0, 50, MultiplierType.perSecond),
    Multiplier("River", "assets/img/river.svg", 5, 0, 1000, MultiplierType.perSecond),
    Multiplier("Squirrels", "assets/img/squirrel.svg", 10, 0, 3000, MultiplierType.perSecond),
    Multiplier("Sun", "assets/img/sun.svg", 25, 0, 10000, MultiplierType.perSecond),
    Multiplier("Watering Pot", "assets/img/wateringpot.svg", 50, 0, 30000, MultiplierType.perSecond),
    Multiplier("Shovel", "assets/img/shovel.svg", 100, 0, 80000, MultiplierType.perSecond),
  ];

  @override
  void initState() {
    // Initialize the rewarded video ad
    rewardedAd = RewardedAd(
      // TODO: Set own ID
      adUnitId: 'ca-app-pub-xxx',
      request: AdRequest(),
      listener: AdListener(
        onRewardedAdUserEarnedReward: (RewardedAd ad, RewardItem reward) {
          rewardUser();
        },
        onAdClosed: (Ad ad) => adClosed(),
        onAdFailedToLoad: (Ad ad, LoadAdError loadAdError) => showToast("Sorry, ads not available right now"),
        onApplicationExit: (Ad ad) => ad.dispose(),
      ),
    );
    // Start timer for CO2 loop
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => incrementCo2Loop());
    // Set initial image assets
    treeImage = Image.asset("assets/img/tree--1.png", key: ValueKey<int>(-1));
    backgroundImage = Image.asset("assets/img/background--1.png", fit: BoxFit.cover);
    // Get data from shared preferences
    getData();
    WidgetsBinding.instance.addObserver(this);
    lottieController = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    saveData();
    Fluttertoast.cancel();
    lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Colors.black);
    rewardedAd.load();
    firstLaunchTutorialChecking();
    return Scaffold(
        body: SafeArea(
            child: Container(
      color: Color(0xff1b0000),
      child: Column(children: [
        Expanded(
          flex: 10,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
                        child: Tooltip(
                          message: "Total number of trees planted globally",
                          child: Text(
                            "Total trees:",
                            style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(treeTotal.toString(),
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              style: GoogleFonts.pressStart2p(textStyle: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                        child: Tooltip(
                          message: "Your approximate contribution",
                          child: Text(
                            "Your trees:",
                            maxLines: 1,
                            style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText((trees).toString(),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            style: GoogleFonts.pressStart2p(textStyle: TextStyle(color: Colors.white))),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                  flex: 1,
                  child: GestureDetector(
                      child: Icon(
                        Icons.info,
                        color: Colors.white,
                      ),
                      onTap: () => {showInfo()})),
            ],
          ),
        ),
        // doing + 1 here so the indicator is visible even if no tree has been planted yet
        Expanded(
          flex: 1,
          child: LinearProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Color((0xffffc107))),
              backgroundColor: Color(0xff1b0000),
              value: (treeTotal.toDouble() + 1) / (treesGoal.toDouble() + 1),
              semanticsLabel: "trees progress indicator"),
        ),

        Expanded(
          flex: 95,
          child: Stack(fit: StackFit.expand, clipBehavior: Clip.hardEdge, alignment: AlignmentDirectional.center, children: [
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
                    child: AutoSizeText("CO2 collected", maxLines: 1, style: GoogleFonts.vt323(textStyle: TextStyle(fontSize: 20))),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AutoSizeText(DefaultMaterialLocalizations().formatDecimal(collectedCO2) + "kg",
                        maxLines: 1, style: GoogleFonts.pressStart2p(textStyle: TextStyle(fontSize: 25))),
                  ),
                ),
                Expanded(
                    flex: 11,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: treeImage,
                      ),
                    ))
              ],
            ),
            Positioned.fill(
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        incrementCo2Manual();
                      },
                      highlightColor: Colors.transparent,
                      splashColor: Color.fromARGB(33, 27, 205, 39),
                    ))),
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
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          backgroundColor: MaterialStateProperty.all<Color>(Color(0xffffc107)),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0), side: BorderSide(color: Color(0xff003300))))),
                    ),
                    ElevatedButton(
                      onPressed: () => Share.share(
                          'Check out Tree Tapper!\n' +
                              'I planted ' +
                              trees.toString() +
                              " real trees playing this!\n" +
                              "Download it at https://tree-tapper.com",
                          subject: 'Check out Tree Tapper!'),
                      child: Tooltip(message: "Share", child: Icon(Icons.share)),
                      style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          backgroundColor: MaterialStateProperty.all<Color>(Color(0xff558b2f)),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0), side: BorderSide(color: Color(0xff003300))))),
                    ),
                    Visibility(
                        visible: prestigeVisible,
                        child: ElevatedButton(
                            onPressed: () => tapPrestige(),
                            child: Icon(Icons.plus_one),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0), side: BorderSide(color: Color(0xff003300))))))),
                    Visibility(
                        visible: rewardVisible,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            valueColor: new AlwaysStoppedAnimation<Color>(Color((0xffffc107))),
                            value: rewardTimer / 60,
                            semanticsLabel: "circular reward timing indicator",
                          ),
                        )),
                  ],
                ),
              ),
            )
          ]),
        ),

        Expanded(
          flex: 1,
          child: LinearProgressIndicator(value: (score.toDouble() / scoreGoal.toDouble()), semanticsLabel: "game progress indicator"),
        ),
        Expanded(
          flex: 20,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Row(
                        children: [
                          Padding(
                              padding: EdgeInsets.fromLTRB(8, 4, 4, 2),
                              child: AutoSizeText(
                                "CO2 per tap:",
                                maxLines: 1,
                                style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.white, fontSize: 16)),
                              )),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AutoSizeText(onTapVal.toString(),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    style: GoogleFonts.pressStart2p(
                                        textStyle: TextStyle(color: rewardVisible ? Color(0xffffc107) : Colors.white, fontSize: 16))),
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
                              padding: EdgeInsets.fromLTRB(8, 2, 4, 4),
                              child: AutoSizeText(
                                "CO2 / s:",
                                maxLines: 1,
                                style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.white, fontSize: 16)),
                              )),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AutoSizeText(perSecVal.toString(),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    style: GoogleFonts.pressStart2p(
                                        textStyle: TextStyle(color: rewardVisible ? Color(0xffffc107) : Colors.white, fontSize: 16))),
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
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                        child: Tooltip(
                          message: "Level",
                          child: Row(
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Lottie.asset(
                                    "assets/json/up-white.json",
                                    controller: lottieController,
                                    repeat: false,
                                    onLoaded: (composition) {
                                      lottieController..duration = composition.duration;
                                    },
                                  )),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AutoSizeText(level.toString(),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    style: GoogleFonts.pressStart2p(textStyle: TextStyle(color: Colors.white, fontSize: 16))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                          child: Tooltip(
                            message: "Stage",
                            child: Row(children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Icon(
                                  Icons.wallpaper,
                                  color: Colors.white,
                                ),
                              ),
                              AutoSizeText(backgroundAsset.toString(),
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  style: GoogleFonts.pressStart2p(textStyle: TextStyle(color: Colors.white, fontSize: 16))),
                            ]),
                          ),
                        ))
                  ],
                ),
              )
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
                crossAxisCount: 2,
                childAspectRatio: 5 / 3,
                children: List.generate(multipliers.length, (index) {
                  return Center(
                    child: Card(
                        child: InkWell(
                      onTap: () {
                        tapMultiplier(index);
                      },
                      onLongPress: () {
                        tapMultiplierMax(index);
                      },
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: SvgPicture.asset(
                                multipliers[index].image,
                                semanticsLabel: multipliers[index].name,
                                color: Color(0xff558b2f),
                                height: 35,
                                width: 35,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AutoSizeText(
                                        "Count: x" + multipliers[index].count.toString(),
                                        style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.black, fontSize: 20)),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AutoSizeText(
                                        "Price: -" + DefaultMaterialLocalizations().formatDecimal(multipliers[index].cost) + "kg",
                                        style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.black, fontSize: 20)),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AutoSizeText(
                                        "Effect: +" +
                                            multipliers[index].multiplicationFactor.toString() +
                                            Multiplier.getStringForType(multipliers[index].type),
                                        style: GoogleFonts.vt323(textStyle: TextStyle(color: Colors.black, fontSize: 20)),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    )),
                  );
                })))
      ]),
    )));
  }

  showInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InfoScreen()),
    );
  }

  playAd() async {
    if (acceptedGDPR) {
      if (rewardTimer > 0) {
        showToast("You can only watch one ad per minute, \nplease wait for the timer to expire!");
      } else if (await rewardedAd.isLoaded()) {
        rewardedAd.show();
      } else {
        rewardedAd.load();
        showToast("Currently no ad available, \nplease try again later!");
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Watch ad?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('After tapping \'Consent\' below, you\'ll be able double your CO2 earnings for 60 seconds by watching a rewarded video ad using this button. The payout received will then be used to plant real trees.'),
                  Text('By doing that, you consent to both our Legal Notice as well as Google\'s Terms of Service (since they supply the ads). Tap the buttons below to learn more.'),
                  SizedBox(
                    height: 15,
                  ),
                  OutlinedButton(onPressed: () => launch("https://tree-tapper.com/app-legal-notice/"), child: Text("Our Legal Notice")),
                  OutlinedButton(
                      onPressed: () => launch("https://policies.google.com/terms?hl=en-US"), child: Text("Google's Terms of Service"))
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Consent'),
                onPressed: () {
                  acceptedGDPR = true;
                  saveData();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
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
    calcCo2Values();
    incrementTrees();
    showToast("Congrats! You helped plant trees. Enjoy double points for one minute!");
  }

  // This gets called on loop (1/s)
  incrementCo2Loop() {
    int co2Increment = 0;
    multipliers.forEach((multiplier) {
      if (multiplier.type == MultiplierType.perSecond) co2Increment += multiplier.count * multiplier.multiplicationFactor;
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
      calcCo2Values();
    }
    co2Increment = co2Increment * rewardFactor;
    setState(() {
      collectedCO2 += co2Increment;
    });
  }

  // This gets called if the tree is tapped manually
  incrementCo2Manual() {
    int co2Increment = 1;
    multipliers.forEach((multiplier) {
      if (multiplier.type == MultiplierType.onTap) co2Increment += multiplier.count * multiplier.multiplicationFactor;
    });
    co2Increment = co2Increment * rewardFactor;
    setState(() {
      collectedCO2 += co2Increment;
    });
  }

  incrementTrees() {
    setState(() {
      trees = trees + adFactor * 1;
    });
    saveData();
  }

  // This gets called if a multiplier is tapped and checks if an upgrade can be purchased
  tapMultiplier(int id) {
    if (collectedCO2 >= multipliers[id].cost) {
      setState(() {
        addScore(multipliers[id].cost);
        collectedCO2 = collectedCO2 - multipliers[id].cost;
        multipliers[id].count++;
        multipliers[id].cost = multipliers[id].cost * 2;
        calcCo2Values();
      });
    } else {
      showToast("Not enough CO2 budget");
    }
  }

  tapMultiplierMax(int id) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Maximize?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Buy as many ' + multipliers[id].name + " as you can afford?"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () {
                  while (collectedCO2 >= multipliers[id].cost) tapMultiplier(id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  // Calculates the multiplier values displayed (CO2 per tap / CO2 per second)
  calcCo2Values() {
    setState(() {
      onTapVal = 1;
      multipliers.forEach((multiplier) {
        if (multiplier.type == MultiplierType.onTap) onTapVal += multiplier.count * multiplier.multiplicationFactor;
      });
      onTapVal = onTapVal * rewardFactor;

      perSecVal = 0;
      multipliers.forEach((multiplier) {
        if (multiplier.type == MultiplierType.perSecond) perSecVal += multiplier.count * multiplier.multiplicationFactor;
      });
      perSecVal = perSecVal * rewardFactor;
    });
  }

  addScore(int i) {
    setState(() {
      score = score + i;
    });
    checkLevelUp();
  }

  // Check if tree asset changed or prestige button should be visible
  void checkLevelUp() {
    // This needs to be a while-loop in case there is every more than one asset swap per method call (this shouldn't happen, but idk)
    while (score >= scoreGoal) {
      lottieController.forward().whenComplete(() => lottieController.reset());
      level++;
      setState(() {
        // 40 is arbitrary here, I chose it because it's the last 'round' number < totalTreeAssets
        if (level > 40) {
          prestigeVisible = true;
        }
        score = score - scoreGoal;
        scoreGoal = (scoreGoal * 1.25).toInt();
        treeImage =
            Image.asset("assets/img/tree-" + (level % totalTreeAssets).toString() + ".png", key: ValueKey<int>(level % totalTreeAssets));
      });
    }
  }

  void tapPrestige() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text("Are you sure?"),
              content: new Text(
                  "This will upgrade you to the next stage, resetting your current progress (but improving your upgrades). Are you sure?"),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Yes!'),
                  onPressed: () {
                    upgradeStage();
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }

  // This gets called when the prestige button is pressed. Changes the background and resets progress.
  void upgradeStage() {
    if (backgroundAsset < totalBackgroundAssets) {
      // Reset everything to 0
      collectedCO2 = 0;
      scoreGoal = initialScoreGoal;
      multipliers.forEach((multiplier) {
        multiplier.count = 0;
        multiplier.cost = multiplier.baseCost;
        multiplier.multiplicationFactor = multiplier.multiplicationFactor * 2;
      });
      onTapVal = 1;
      perSecVal = 0;
      level = 0;
      score = 0;
      backgroundAsset++;
      saveData();

      // Change background asset
      setState(() {
        backgroundImage = Image.asset(
          "assets/img/background-" + backgroundAsset.toString() + ".png",
          fit: BoxFit.cover,
        );
        treeImage = Image.asset("assets/img/tree-0.png", key: ValueKey<int>(0));
        prestigeVisible = false;
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('You finished the game!'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('You have reached the final stage... for now!'),
                  Text(
                      'The first 10 people to send in the code below through the contact form on the website will get 100 trees planted in their name (remember to mention your name in the submission!).'),
                  // TODO: set own code (or remove)
                  Text('Code to submit: \'TTSC2021\''),
                  OutlinedButton(onPressed: () => launch("https://tree-tapper.com/#contact"), child: Text("Contact Form"))
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void showToast(String t) {
    // Cancel possible previous toasts
    Fluttertoast.cancel();
    // Display toast with message
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
    collectedCO2 = prefs.getInt("co2") ?? 0;
    score = prefs.getInt("score-val") ?? 0;
    scoreGoal = prefs.getInt("scoreGoal") ?? initialScoreGoal;

    trees = prefs.getDouble("treesPlanted") ?? 0;
    multipliers.forEach((multiplier) {
      multiplier.count = prefs.getInt(multiplier.name) ?? 0;
      multiplier.cost = prefs.getInt(multiplier.name + "-cost") ?? multiplier.baseCost;
      multiplier.multiplicationFactor = prefs.getInt(multiplier.name + "-factor") ?? multiplier.multiplicationFactor;
    });

    setState(() {
      level = prefs.getInt("level") ?? 0;
      backgroundAsset = prefs.getInt("backgroundAsset") ?? 0;
      treeImage =
          Image.asset("assets/img/tree-" + (level % totalTreeAssets).toString() + ".png", key: ValueKey<int>(level % totalTreeAssets));
      backgroundImage = Image.asset("assets/img/background-" + backgroundAsset.toString() + ".png", fit: BoxFit.cover);
      if (treeTotal == 0) treeTotal = prefs.getInt("treeTotal") ?? 0;
      if (treesGoal == 0) treesGoal = prefs.getInt("treeGoal") ?? 0;
      if (adFactor == 0) adFactor = prefs.getDouble("adFactor") ?? 0.0;
    });

    calcCo2Values();
    BackendResponse backendResponse = await fetchBackendResponse();
    setState(() {
      if (backendResponse.treeTotal != null) treeTotal = backendResponse.treeTotal.round();
      if (backendResponse.treeGoal != null) treesGoal = backendResponse.treeGoal.round();
      if (backendResponse.adFactor != null) adFactor = backendResponse.adFactor;
    });

    isFirstLaunch = prefs.getBool("isFirstLaunch");
    acceptedGDPR = prefs.getBool("acceptedGDPR") ?? false;
  }

  // Save data to SharedPreferences
  saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("treesPlanted", trees);
    prefs.setInt("co2", collectedCO2);
    prefs.setInt("score-val", score);
    prefs.setInt("scoreGoal", scoreGoal);

    multipliers.forEach((multiplier) {
      prefs.setInt(multiplier.name, multiplier.count);
      prefs.setInt(multiplier.name + "-cost", multiplier.cost);
      prefs.setInt(multiplier.name + "-factor", multiplier.multiplicationFactor);
    });

    prefs.setInt("backgroundAsset", backgroundAsset);
    prefs.setInt("level", level);

    prefs.setInt("treeTotal", treeTotal);
    prefs.setInt("treeGoal", treesGoal);
    prefs.setDouble("adFactor", adFactor);

    prefs.setBool("isFirstLaunch", false);
    prefs.setBool("acceptedGDPR", acceptedGDPR);
  }

  // These are separate functions because they get called every build
  firstLaunchTutorialChecking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isFirstLaunch = prefs.getBool("isFirstLaunch") ?? true;
    if (isFirstLaunch) {
      isFirstLaunch = false;
      saveFirstLaunch();
      Future.microtask(() => Navigator.push(context, MaterialPageRoute(builder: (context) => InfoScreen())));
    }
  }

  saveFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isFirstLaunch", false);
  }

  // Fetch remote data from server
  Future<BackendResponse> fetchBackendResponse() async {
    final response = await http.get(Uri.https('api.tree-tapper.com', "/"));
    if (response.statusCode == 200) {
      BackendResponse backendResponse;
      try {
        backendResponse = BackendResponse.fromJson(jsonDecode(response.body));
      } on FormatException {
        backendResponse = BackendResponse(treeTotal: null, treeGoal: null, adFactor: null);
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
