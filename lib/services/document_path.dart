class DocumentPath {
  static String privateProfiles(String uid, String profileId) =>
      'Users/$uid/PrivateProfiles/$profileId';
  static String streamPrivateProfiles(String uid) =>
      'Users/$uid/PrivateProfiles/';

  static String userProfiles(String profileId) => 'UserProfiles/$profileId';
  static String streamUserProfiles() => 'UserProfiles/';
}
