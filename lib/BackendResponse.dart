class BackendResponse {
  final int treeTotal;
  final int treeGoal;
  final double adFactor;


  /// Expected response format is JSON:
  /// {
  ///  "totalTotal" : int,
  ///   "treeGoal" : int,
  ///   "adFactor" : double
  /// }
  BackendResponse({this.treeTotal, this.treeGoal, this.adFactor});

  factory BackendResponse.fromJson(Map<String, dynamic> json) {
    return BackendResponse(
      treeTotal: json['treeTotal'],
      treeGoal: json['treeGoal'],
      adFactor: json['adFactor']
    );
  }
}