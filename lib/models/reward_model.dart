class Reward {
  final String id;
  final String title;
  final String description;
  final String businessName;
  final String businessType; // 'spa', 'pastry', 'restaurant', 'shop', 'experience'
  final String imageUrl;
  final String address;
  final int pointsCost;
  final String discount;
  final String? validUntil;
  final List<String> termsAndConditions;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.businessName,
    required this.businessType,
    required this.imageUrl,
    required this.address,
    required this.pointsCost,
    required this.discount,
    this.validUntil,
    required this.termsAndConditions,
  });
}
