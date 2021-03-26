# Tree Tapper  
Tree Tapper is a new type of idle game, based on Flutter 2. Through the option of interactive video ads, users can not only earn in-game rewards, but also plant actual, real-life trees at the same time. The game features a deep progression system and keeps track of the number of trees planted by each user in order to provide a shareable experience that remains engaging in the long term.

## Running the game
To run the game yourself, do the following in an environment where [Git](https://git-scm.com/) and [Flutter](https://flutter.dev/docs/get-started/install) are installed and available:

```
git clone https://github.com/gereonelvers/tree-tapper.git
```
Navigate into the project with an editor/IDE of your choice and change the AdMob App- as well as Ad-Unit-ID with your own (choose "Rewarded" as ad type). You can create an AdMob account [here](https://admob.google.com/). Remember to use the provided [placeholder ID](https://developers.google.com/admob/android/test-ads) when not deploying to real users. The values can be found in AndroidManifest.xml/Info.plist and GameScreen.dart respectively. They have been marked with TODOs which are automatically highlighted in Android Studio. Afterwards, in order to run the project execute:

```
flutter run
```
Alternatively you can also build project packages using any one of [Flutter's build modes](https://flutter.dev/docs/testing/build-modes). Remember that for Android release deployments, you'll want to sign with your own [keystore](https://flutter.dev/docs/deployment/android).

Note that the AdMob integration (as well as other minor components) currently only work on mobile devices (and the game has only been comprehensively tested on Android). When running as a web app or on desktop, an exception will be thrown in the console - this should not otherwise affect gameplay.
The code for the web server providing the global values to the game can be found [here](https://github.com/gereonelvers/tree-tapper-server).