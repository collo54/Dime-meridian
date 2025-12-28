import 'dart:math';

import 'package:dime_meridian/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
//import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

abstract class AuthBase {
  Stream<UserModel?> get onAuthStateChanged;
  UserModel? currentUser();
  Future<UserModel?> signInAnonymously();
  Future<UserModel?> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> createUserWithEmailAndPassword(
    String email,
    String password,
  );
  Future<void> passwordReset(String email);
  Future<UserModel?> signInWithGoogle();
  // Future<UserModel?> signInWithFacebook();
  Future<void> signOut();
  Future<void> deleteUserAccount();
}

class AuthService implements AuthBase {
  final _firebaseAuth = FirebaseAuth.instance;
  static const String clientId =
      '222936818676-t8s1rnl7l5ofpgmv4usms9jas7cko37e.apps.googleusercontent.com';
  static const String webClientId =
      '222936818676-4ace0f7ikqehfgfmcj43rbl9r8lbil4n.apps.googleusercontent.com';

  String getUserString(String inputString) {
    String firstFiveChars = inputString.substring(
      0,
      min(inputString.length, 5),
    );
    return "user$firstFiveChars";
  }

  UserModel? _userFromFirebase(User? user) {
    if (user == null) {
      return null;
    }
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName ?? getUserString(user.uid),
      photoUrl: user.photoURL ?? '',
      phoneNumber: user.phoneNumber ?? '',
      isAnonymous: user.isAnonymous,
    );
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
    // return _firebaseAuth.idTokenChanges().map(_userFromFirebase);
  }

  @override
  UserModel? currentUser() {
    final user = _firebaseAuth.currentUser;
    return _userFromFirebase(user);
  }

  @override
  Future<UserModel?> signInAnonymously() async {
    Fluttertoast.showToast(
      msg: "Signing in",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    final authResult = await _firebaseAuth.signInAnonymously();
    return _userFromFirebase(authResult.user);
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final authResult = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _userFromFirebase(authResult.user);
    } on Exception catch (e) {
      Fluttertoast.showToast(
        msg: "Error sigining in with email: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      if (kDebugMode) {
        print('Error sigining in with email: $e');
      }
      rethrow;
    }
  }

  @override
  Future<UserModel?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final authResult = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _userFromFirebase(authResult.user);
    } on Exception catch (e) {
      Fluttertoast.showToast(
        msg: "Error creating account: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      if (kDebugMode) {
        print('Error creating account: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> passwordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw PlatformException(code: e.code, message: e.message);
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final googleSignIn = kIsWeb
        ? GoogleSignIn(clientId: webClientId, scopes: ['email', 'profile'])
        : GoogleSignIn(
            // scopes: [
            //   'email',
            //   'profile',
            // ],
            scopes: ['email', 'profile'],
            // serverClientId: clientId,
            // clientId: clientId,
          );
    GoogleSignInAccount? googleAccount = kIsWeb
        ? await googleSignIn.signInSilently()
        : await googleSignIn.signIn();
    if (kIsWeb && googleAccount == null) {
      googleAccount = await (googleSignIn.signIn());
    }
    if (googleAccount != null) {
      final googleAuth = await googleAccount.authentication;
      if (kIsWeb ||
          (googleAuth.accessToken != null && googleAuth.idToken != null)) {
        final authResult = await _firebaseAuth.signInWithCredential(
          kIsWeb
              ? GoogleAuthProvider.credential(
                  idToken: googleAuth.idToken,
                  accessToken: googleAuth.accessToken,
                )
              : GoogleAuthProvider.credential(
                  idToken: googleAuth.idToken,
                  accessToken: googleAuth.accessToken,
                ),
        );
        return _userFromFirebase(authResult.user);
      } else {
        Fluttertoast.showToast(
          msg: "Missing Google Auth Token",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        throw PlatformException(
          code: 'ERROR_MISSING_GOOGLE_AUTH_TOKEN',
          message: 'Missing Google Auth Token',
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Sign in aborted by user",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      throw PlatformException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
  }

  Future<UserModel?> signInWithPhoneNumberWeb(
    String phoneno,
    String code,
  ) async {
    ConfirmationResult confirmationResult = await _firebaseAuth
        .signInWithPhoneNumber(phoneno);
    UserCredential userCredential = await confirmationResult.confirm(code);
    return _userFromFirebase(userCredential.user);
  }

  // NEW, SIMPLIFIED verification method
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    int? resendToken,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This is for auto-retrieval, which is rare.
        // You can optionally sign the user in directly here.
        final authResult = await _firebaseAuth.signInWithCredential(credential);
        _userFromFirebase(authResult.user);
        Fluttertoast.showToast(msg: "Auto-verification completed.");
      },
      verificationFailed: onVerificationFailed, // Pass the failure callback
      codeSent: onCodeSent, // Pass the code sent callback
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out
      },
    );
  }

  // NEW, SIMPLIFIED OTP sign-in method
  Future<UserModel?> signInWithOTP(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final authResult = await _firebaseAuth.signInWithCredential(credential);
      return _userFromFirebase(authResult.user);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: "Error signing in with OTP: ${e.message}",
        backgroundColor: Colors.red,
      );
      debugPrint('Error signing in with OTP: ${e.message}');
      rethrow; // Rethrow to be caught by the UI
    }
  }

  // Future<String?> signInWithPhoneNumberAndroid(String phoneNumber) async {
  //   try {
  //     String? verificationId;
  //     await _firebaseAuth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         Fluttertoast.showToast(
  //             msg: phoneNumber,
  //             toastLength: Toast.LENGTH_LONG,
  //             gravity: ToastGravity.BOTTOM,
  //             timeInSecForIosWeb: 1,
  //             backgroundColor: Colors.deepOrange,
  //             textColor: Colors.white,
  //             fontSize: 16.0);
  //         // Auto-verification (may not work on all devices)
  //         final authResult =
  //             await _firebaseAuth.signInWithCredential(credential);
  //         _userFromFirebase(authResult.user);
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         if (e.code == 'invalid-phone-number') {
  //           debugPrint('The provided phone number is not valid.');
  //         } else {
  //           debugPrint('Error during phone verification: ${e.message}');
  //         }
  //         Fluttertoast.showToast(
  //           msg: "Error creating account: ${e.message}",
  //           toastLength: Toast.LENGTH_LONG,
  //           gravity: ToastGravity.BOTTOM,
  //           timeInSecForIosWeb: 1,
  //           backgroundColor: Colors.redAccent,
  //           textColor: Colors.white,
  //           fontSize: 16.0,
  //         );
  //         // Handle verification failures
  //         throw e; // Rethrow the exception to be handled by the caller
  //       },
  //       codeSent: (String verId, int? resendToken) async {
  //         // Save the verification ID for later use
  //         verificationId = verId;
  //       },
  //       codeAutoRetrievalTimeout: (String verId) {
  //         // Handle auto-retrieval timeout (if needed)
  //         verificationId = verId;
  //       },
  //     );
  //     return verificationId;
  //   } on Exception catch (e) {
  //     Fluttertoast.showToast(
  //         msg: "Error verifying phone number: $e",
  //         toastLength: Toast.LENGTH_LONG,
  //         gravity: ToastGravity.BOTTOM,
  //         timeInSecForIosWeb: 1,
  //         backgroundColor: Colors.blueAccent,
  //         textColor: Colors.white,
  //         fontSize: 16.0);
  //     if (kDebugMode) {
  //       print('Error verifying phone number: $e');
  //     }
  //     rethrow;
  //   }
  // }

  // Future<void> signInWithOTP(
  //   String smsCode,
  //   String phoneNumber,
  // ) async {
  //   try {
  //     // AuthCredential credential =
  //     //     PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
  //     // final authResult = await _firebaseAuth.signInWithCredential(credential);
  //     // return _userFromFirebase(authResult.user);

  //     await _firebaseAuth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       codeSent: (String verificationId, int? resendToken) async {
  //         PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //             verificationId: verificationId, smsCode: smsCode);

  //         final authResult =
  //             await _firebaseAuth.signInWithCredential(credential);
  //         _userFromFirebase(authResult.user);
  //       },
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         Fluttertoast.showToast(
  //             msg: phoneNumber,
  //             toastLength: Toast.LENGTH_LONG,
  //             gravity: ToastGravity.BOTTOM,
  //             timeInSecForIosWeb: 1,
  //             backgroundColor: Colors.deepOrange,
  //             textColor: Colors.white,
  //             fontSize: 16.0);
  //         // Auto-verification (may not work on all devices)
  //         final authResult =
  //             await _firebaseAuth.signInWithCredential(credential);
  //         _userFromFirebase(authResult.user);
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         if (e.code == 'invalid-phone-number') {
  //           debugPrint('The provided phone number is not valid.');
  //         } else {
  //           debugPrint('Error during phone verification: ${e.message}');
  //         }
  //         Fluttertoast.showToast(
  //           msg: "Error creating account: ${e.message}",
  //           toastLength: Toast.LENGTH_LONG,
  //           gravity: ToastGravity.BOTTOM,
  //           timeInSecForIosWeb: 1,
  //           backgroundColor: Colors.redAccent,
  //           textColor: Colors.white,
  //           fontSize: 16.0,
  //         );
  //         // Handle verification failures
  //         throw e; // Rethrow the exception to be handled by the caller
  //       },
  //       codeAutoRetrievalTimeout: (String verId) {
  //         // Handle auto-retrieval timeout (if needed)
  //       },
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     // Handle sign-in errors (e.g., invalid OTP)
  //     if (e.code == 'invalid-verification-code') {
  //       Fluttertoast.showToast(
  //           msg: "Invalid OTP",
  //           toastLength: Toast.LENGTH_LONG,
  //           gravity: ToastGravity.BOTTOM,
  //           timeInSecForIosWeb: 1,
  //           backgroundColor: Colors.redAccent,
  //           textColor: Colors.white,
  //           fontSize: 16.0);
  //     } else {
  //       Fluttertoast.showToast(
  //           msg: "Error signing in with OTP: ${e.message}",
  //           toastLength: Toast.LENGTH_LONG,
  //           gravity: ToastGravity.BOTTOM,
  //           timeInSecForIosWeb: 1,
  //           backgroundColor: Colors.redAccent,
  //           textColor: Colors.white,
  //           fontSize: 16.0);
  //     }
  //     debugPrint('Error signing in with OTP: ${e.message}');
  //     rethrow;
  //   }
  // }

  Future<UserModel?> signInWithOTPCode(
    ConfirmationResult confirmationResult,
    String code,
  ) async {
    UserCredential userCredential = await confirmationResult.confirm(code);
    return _userFromFirebase(userCredential.user);
  }

  @override
  Future<void> signOut() async {
    User? user = _firebaseAuth.currentUser;

    if (user != null) {
      // Get the list of sign-in methods for the user
      List<UserInfo> providerData = user.providerData;

      bool isGoogleUser = providerData.any(
        (info) => info.providerId == "google.com",
      );

      if (isGoogleUser) {
        await GoogleSignIn().signOut(); // Sign out from Google
      }

      // final googleSignIn = GoogleSignIn();
      // await googleSignIn.signOut();

      //  final facebookLogin = FacebookLogin();
      // await facebookLogin.logOut();
      await _firebaseAuth.signOut();
    }
  }

  @override
  Future<void> deleteUserAccount() async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user != null) {
        await user.delete();
        Fluttertoast.showToast(
          msg: "User account deleted successfully",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        debugPrint("User account deleted successfully.");
      } else {
        Fluttertoast.showToast(
          msg: "No user is signed in",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        debugPrint("No user is signed in.");
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting user: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: kred236575710,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      debugPrint("Error deleting user: $e");
    }
  }

  /*
  @override
  Future<UserModel> signInWithFacebook() async {
      final facebookLogin = FacebookLogin();
    final result = await facebookLogin.logInWithReadPermissions(
      ['public_profile'],
    );
    if (result.accessToken != null) {
      final authResult = await _firebaseAuth.signInWithCredential(
        FacebookAuthProvider.getCredential(
          accessToken: result.accessToken.token,
        ),
      );
      return _userFromFirebase(authResult.user);
    } else {
      throw PlatformException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
  }
  */

  /* 
   Future<UserModel?> signInWithPhoneNumber(String phoneno, String code) async {
    ConfirmationResult confirmationResult =
        await _firebaseAuth.signInWithPhoneNumber(
      phoneno,
    );
    UserCredential userCredential = await confirmationResult.confirm(code);
    return _userFromFirebase(userCredential.user);
  }

  Future<ConfirmationResult> signInWithPhoneNumber2(String string) async {
    ConfirmationResult confirmationResult =
        await _firebaseAuth.signInWithPhoneNumber(
      string,
    );

    return confirmationResult;
  }

  Future<UserModel?> signInWithOTPCode(
      ConfirmationResult confirmationResult, String code) async {
    UserCredential userCredential = await confirmationResult.confirm(code);
    return _userFromFirebase(userCredential.user);
  }

  Future<UserModel?> signInWithOTP(String smsCode, String verId) async {
    AuthCredential credential =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    final authResult = await _firebaseAuth.signInWithCredential(credential);
    return _userFromFirebase(authResult.user);
  }
*/
}
