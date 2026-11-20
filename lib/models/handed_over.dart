// what the API gives back once the receiver has the parcel
class HandedOver {
  const HandedOver({
    required this.trackingNo,
    required this.receiverName,
    required this.collectedAt,
    required this.handedOverBy,
    required this.office,
  });

  factory HandedOver.fromJson(Map<String, dynamic> json) {
    final parcel = json['parcel'] as Map<String, dynamic>;

    return HandedOver(
      trackingNo: parcel['tracking_no'] as String,
      receiverName: parcel['receiver_name'] as String,
      collectedAt: DateTime.parse(json['collected_at'] as String).toLocal(),
      handedOverBy: json['by'] as String,
      office: json['office'] as String,
    );
  }

  final String trackingNo;
  final String receiverName;
  final DateTime collectedAt;
  final String handedOverBy;
  final String office;
}
