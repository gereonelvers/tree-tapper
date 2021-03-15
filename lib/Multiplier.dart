/// This class contains all data for a single multiplier. It also manages typing of Multipliers
enum MultiplierType { onTap, perSecond }

class Multiplier {
  String name;
  String image;
  int multiplicationFactor;
  int count;
  int cost;
  MultiplierType type;

  Multiplier(String name, String image, int multiplicationFactor, int count,
      int cost, MultiplierType type) {
    this.name = name;
    this.image = image;
    this.multiplicationFactor = multiplicationFactor;
    this.count = count;
    this.cost = cost;
    this.type = type;
  }

  static String getStringForType(MultiplierType type) {
    switch (type) {
      case MultiplierType.onTap:
        return " on Tap";
      case MultiplierType.perSecond:
        return " / s";
      default:
        return "";
    }
  }
}
