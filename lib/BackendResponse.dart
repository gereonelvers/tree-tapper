class BackendResponse {
  final int treeTotal;
  final int treeGoal;
  final double adFactor;

  /// Expected response format is JSON:
  /// {
  ///  "treeTotal" : int,
  ///   "treeGoal" : int,
  ///   "adFactor" : double
  /// }
  BackendResponse({this.treeTotal, this.treeGoal, this.adFactor});

  factory BackendResponse.fromJson(Map<String, dynamic> json) {
    int treeTotal = json['treeTotal'];
    int treeGoal = json['treeGoal'];
    // This conversion is required if the response does not have a decimal place (as the json library then assumes it is an integer and the type conversion breaks)
    double adFactor = double.parse(json['adFactor'].toString());
    return BackendResponse(treeTotal: treeTotal, treeGoal: treeGoal, adFactor: adFactor);
  }
}
