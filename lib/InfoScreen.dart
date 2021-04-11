import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tindercard/flutter_tindercard.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shadowed_image/shadowed_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    getPackageInfo();
    super.initState();
  }

  var packageInfo;

  List<Widget> assets = [
    Image(image: AssetImage("assets/img/tree-tapper-header.jpg"), fit: BoxFit.fitWidth),
    Lottie.asset("assets/json/photo.json"),
    Lottie.asset("assets/json/up.json"),
    Lottie.asset("assets/json/tree-hand.json"),
    Lottie.asset("assets/json/thumbs-up.json"),
  ];

  List<String> headlines = [
    "Hello there!",
    "Gameplay",
    "Upgrades!",
    "Plant Trees!",
    "That's it!"
  ];

  List<Widget> bodies = [
    Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
              "Welcome to Tree Tapper - a new type of idle game with a real life progression system.\nLet's walk through some things before you get started.",
              style: GoogleFonts.vt323(
                  textStyle: TextStyle(color: Colors.black, fontSize: 20))),
        )),
    Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
              "Tap the big tree at the top to collect CO2 and level up. You can check your progress on the green bar below the tree - the tree grows through the seasons as you advance.\nAt a certain level you will also be able to unlock new backgrounds!",
              style: GoogleFonts.vt323(
                  textStyle: TextStyle(color: Colors.black, fontSize: 20))),
        )),
    Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
              "Upgrade your taps or add other bonuses by purchasing upgrades through the buttons below. Hint: Hold an upgrade to purchase more as many as you can afford!\nYou can also speed up your progress by watching an ad through the gold button on the top right. But there's a twist...",
              style: GoogleFonts.vt323(
                  textStyle: TextStyle(color: Colors.black, fontSize: 20))),
        )),
    Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
              "All money earned through the ads is used to plant actual real life trees. That's right: With each in-game reward you earn, you also help international reforestation initiatives. You can see your approximate contribution on the top right, next to the total number of trees planted globally. Below that, you can see the global progress towards the monthly goal.",
              style: GoogleFonts.vt323(
                  textStyle: TextStyle(color: Colors.black, fontSize: 20))),
        )),
    Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(children: [
            Text(
                "I hope you enjoy playing the game.\nIf you have any feedback or just want to learn more, please visit the project's website using the button below.\nEnjoy!",
                style: GoogleFonts.vt323(
                    textStyle: TextStyle(color: Colors.black, fontSize: 20))),
            OutlinedButton(
              onPressed: () {
                launch("https://tree-tapper.com");
              },
              style: ElevatedButton.styleFrom(
                  primary: Color(0xff1b0000),
                  side: BorderSide(color: Colors.white)),
              child: Padding(
                  child: AutoSizeText("Learn more",
                      style: GoogleFonts.vt323(
                          textStyle:
                              TextStyle(color: Colors.white, fontSize: 18))),
                  padding: EdgeInsets.fromLTRB(0, 16, 0, 16)),
            )
          ]),
        )),
  ];

  @override
  Widget build(BuildContext context) {
    CardController controller; //Use this to trigger swap.
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Color(0xff003300),
          child: Column(children: [
            Expanded(
                flex: 1,
                child: Center(
                  child: AutoSizeText("Introduction",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vt323(
                          textStyle:
                              TextStyle(color: Colors.white, fontSize: 60))),
                )),
            Expanded(
              flex: 7,
              child: Container(
                child: Center(
                  child: TinderSwapCard(
                    orientation: AmassOrientation.TOP,
                    totalNum: assets.length,
                    stackNum: 4,
                    swipeEdge: 4.0,
                    allowVerticalMovement: false,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    minWidth: MediaQuery.of(context).size.width * 0.89,
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                    cardBuilder: (context, index) => Card(
                        //child: Image.asset('${welcomeImages[index]}'),
                        child: Column(
                      children: [
                        Flexible(
                            flex: 4,
                            fit: FlexFit.loose,
                            child: Align(
                                alignment: Alignment.topCenter,
                                child: assets[index])),
                        Flexible(
                          fit: FlexFit.loose,
                          flex: 1,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: AutoSizeText(headlines[index],
                                    textAlign: TextAlign.start,
                                    style: GoogleFonts.vt323(
                                        textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ),
                        ),
                        Flexible(flex: 5, child: bodies[index]),
                      ],
                    )),
                    cardController: controller = CardController(),
                    swipeUpdateCallback:
                        (DragUpdateDetails details, Alignment align) {},
                    swipeCompleteCallback:
                        (CardSwipeOrientation orientation, int index) {
                      if (index == assets.length - 1) finalCard();
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(4, 0, 8, 0),
                          child: OutlinedButton(
                            onPressed: () {
                              showAboutDialog(
                                  context: context,
                                  applicationVersion:
                                      "Version: " + packageInfo.version,
                                  applicationIcon: ShadowedImage(
                                    image: Image.asset("assets/img/icon.png",
                                        width: 40, height: 40),
                                  ),
                                  applicationLegalese:
                                      "The Tree Tapper game itself is Open Source Software under the MIT license. More information, including information on the individual licences applicable to the icons/images/other assets can be found on the projects website (using the button below). Also note the applicable software licences which can be viewed using the \"View Licenses\" button below.",
                                  children: [
                                    Align(
                                        alignment: Alignment.center,
                                        child: OutlinedButton(
                                            onPressed: () {
                                              launch(
                                                  "https://tree-tapper.com/about");
                                            },
                                            child: Text("About",
                                                style: TextStyle(
                                                    color: Colors.green))))
                                  ]);
                            },
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white)),
                            child: Padding(
                                child: Icon(
                                  Icons.info,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.fromLTRB(0, 16, 0, 16)),
                          ))),
                  Expanded(
                      flex: 2,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(4, 0, 8, 0),
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white)),
                            child: Padding(
                                child: Row(children: [
                                  Expanded(
                                      flex: 2,
                                      child: AutoSizeText("Skip to game",
                                          maxLines: 1,
                                          style: GoogleFonts.vt323(
                                              textStyle: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18)))),
                                  Expanded(
                                      flex: 1,
                                      child: Icon(
                                        Icons.fast_forward,
                                        color: Colors.white,
                                      ))
                                ]),
                                padding: EdgeInsets.fromLTRB(0, 16, 0, 16)),
                          ))),
                  Expanded(
                      flex: 2,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                          child: ElevatedButton(
                            onPressed: () {
                              controller.triggerRight();
                            },
                            style: ElevatedButton.styleFrom(
                                primary: Color(0xff1b0000),
                                side: BorderSide(color: Colors.white)),
                            child: Padding(
                                child: Row(children: [
                                  Expanded(
                                      flex: 2,
                                      child: AutoSizeText("Next Slide",
                                          maxLines: 1,
                                          style: GoogleFonts.vt323(
                                              textStyle: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18)))),
                                  Expanded(
                                      flex: 1, child: Icon(Icons.play_arrow))
                                ]),
                                padding: EdgeInsets.fromLTRB(0, 16, 0, 16)),
                          ))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  finalCard() {
    Navigator.pop(context);
  }

  getPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }
}
