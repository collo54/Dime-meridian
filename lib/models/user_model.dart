class UserModel {
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.phoneNumber,
    required this.isAnonymous,
  });
  final String uid;
  final String? email;
  final String? photoUrl;
  final String? displayName;
  final String? phoneNumber;
  final bool? isAnonymous;
}
