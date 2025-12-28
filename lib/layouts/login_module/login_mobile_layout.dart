import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/colors.dart';
import '../../models/user_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';

enum EmailSignInFormType { signIn, register }

class LoginMobileLayout extends ConsumerStatefulWidget {
  LoginMobileLayout({
    //required this.currentScaffold,
    super.key,
  });
  //GlobalKey<ScaffoldState> currentScaffold;

  @override
  ConsumerState<LoginMobileLayout> createState() => _LoginMobileLayoutState();
}

class _LoginMobileLayoutState extends ConsumerState<LoginMobileLayout> {
  final _auth = AuthService();
  EmailSignInFormType _formType = EmailSignInFormType.register;
  final _formKey = GlobalKey<FormState>();
  final _formKeySmsCode = GlobalKey<FormState>();
  final _formKeyPhoneNumber = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? verId;
  // late TapGestureRecognizer _onTapRecognizer;
  // ignore: prefer_final_fields
  String _countryPhoneCode = ' Phone Number ';
  final TextEditingController _controller = TextEditingController();
  String? _phone;
  String? _smsCode;
  bool _loading = false;
  // late GoogleMapController mapController;
  // late String _mapStyle;

  @override
  void initState() {
    super.initState();
    //  _onTapRecognizer = TapGestureRecognizer()..onTap = _handlePress;
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   rootBundle.loadString('assets/style/map_style_dark.txt').then((string) {
    //     _mapStyle = string;
    //   });
    //  });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   widget.currentScaffold.currentState!.showBodyScrim(true, 0.6);
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       widget.currentScaffold.currentState!.showBodyScrim(true, 0.6);
    //       return const LocationDisclosureDialog();
    //     },
    //   );
    // });
  }

  @override
  void dispose() {
    // widget.currentScaffold.currentState!.showBodyScrim(false, 0.5);
    //  _onTapRecognizer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toogleFormType() {
    setState(() {
      _formType = _formType == EmailSignInFormType.signIn
          ? EmailSignInFormType.register
          : EmailSignInFormType.signIn;
    });
    //  final form = _formKey.currentState!;
    // form.reset();
  }

  bool _validateAndSaveForm() {
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      form.reset();
      return true;
    }
    return false;
  }

  Future<UserModel?> _logInEmail() async {
    if (!_validateAndSaveForm()) return null;

    if (_formType == EmailSignInFormType.signIn) {
      return await _logIn();
    } else {
      return await _register();
    }
  }

  Future<UserModel> _register() async {
    final user = await _auth.createUserWithEmailAndPassword(
      _email!,
      _password!,
    );
    return user!;
  }

  Future<UserModel> _logIn() async {
    final user = await _auth.signInWithEmailAndPassword(_email!, _password!);
    return user!;
  }

  Future<UserModel?> _loginGoogle() async {
    final user = await _auth.signInWithGoogle();
    return user;
  }

  // Future<String?> _submitFormVerifyPhoneNumber() async {
  //   try {
  //     if (_validateAndSaveFormPhoneNumber()) {
  //       final result = await _VerifyPhone();
  //       debugPrint('verify phone number');

  //       setState(() {
  //         verId = result;
  //         _loading = false;
  //       });
  //       return result;
  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  //   return null;
  // }

  // Future<UserModel?> _submitFormSmsCode() async {
  //   try {
  //     if (_validateAndSaveFormSmsCode()) {
  //       final user = await _auth.signInWithOTP(_smsCode!, verId!);
  //       debugPrint('log in with otp');
  //       if (user == null) {
  //         setState(() {
  //           _loading = false;
  //         });
  //         return null;
  //       }
  //       setState(() {
  //         _loading = false;
  //       });
  //       return user;
  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  //   return null;
  // }

  // Future<String?> _VerifyPhone() async {
  //   debugPrint('phone entered: $_phone');
  //   Fluttertoast.showToast(
  //       msg: 'phone entered: $_phone',
  //       toastLength: Toast.LENGTH_LONG,
  //       gravity: ToastGravity.BOTTOM,
  //       timeInSecForIosWeb: 1,
  //       backgroundColor: Colors.blue,
  //       textColor: Colors.white,
  //       fontSize: 16.0);
  //   final verId = await _auth.signInWithPhoneNumberAndroid(_phone!);
  //   return verId;
  // }

  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final primaryText = _formType == EmailSignInFormType.signIn
        ? 'Log in'
        : 'Create an account';
    final secondaryText = _formType == EmailSignInFormType.signIn
        ? 'Need an account? Register'
        : 'Have an account? Log in';
    final Size size = MediaQuery.sizeOf(context);
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size.height, //subtract the padding from the height
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              //  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.max,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Dime Meridian',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        //  color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // const SizedBox(
                //   height: 8,
                // ),
                // Text(
                //   'Ready to go',
                //   style: GoogleFonts.inter(
                //     textStyle: const TextStyle(
                //       height: 1.56,
                //       color: kblackgrey79797907,
                //       fontSize: 16,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 19),

                SizedBox(width: 248, child: _buildFormEmail()),
                const SizedBox(height: 15),
                MaterialButton(
                  onPressed: _loading == false
                      ? () async {
                          if (_loading) return;
                          setState(() => _loading = true);

                          final user = await _logInEmail();

                          if (!mounted) return;

                          if (user == null) {
                            setState(() => _loading = false);
                          }
                          // setState(() {
                          //   _loading = true;
                          // });
                          // widget.currentScaffold.currentState!.showBodyScrim(
                          //   true,
                          //   0.5,
                          // );
                          // final user = await _logInEmail();
                          // if (mounted) {
                          //   if (user == null) {
                          //     setState(() {
                          //       _loading = false;
                          //     });
                          //     widget.currentScaffold.currentState!
                          //         .showBodyScrim(false, 0.5);
                          //   }
                          // }
                        }
                      : null,
                  color: kdarkblue,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  height: 55,
                  minWidth: 248,
                  child: Text(
                    primaryText,
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        color: kwhite25525525510,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                MaterialButton(
                  onPressed: () async {
                    if (_loading == false) {
                      _toogleFormType();
                    }
                  },
                  color: kdarkblue,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  height: 55,
                  minWidth: 248,
                  child: _loading == false
                      ? Text(
                          secondaryText,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              height: 1.56,
                              color:
                                  kwhite25525525510, // Color.fromRGBO(255, 230, 2, 1),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : CircularProgressIndicator(
                          color: brightness == Brightness.light
                              ? kdarkblue
                              : kwhite25525525510, // Color.fromRGBO(255, 230, 2, 1),
                        ),
                ),

                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 99,
                      height: 2,
                      child: Divider(height: 1, color: kblackgrey79797903),
                    ),
                    const SizedBox(width: 17),
                    Text(
                      'or',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          // color: kblackgrey79797910,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 17),
                    const SizedBox(
                      width: 99,
                      height: 2,
                      child: Divider(height: 1, color: kblackgrey79797903),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 19),
                MaterialButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_loading) return;
                          setState(() => _loading = true);

                          final user = await _loginGoogle();

                          if (!mounted) return;

                          if (user == null) {
                            setState(() => _loading = false);
                          }
                          // setState(() {
                          //   _loading = true;
                          // });
                          // widget.currentScaffold.currentState!.showBodyScrim(
                          //   true,
                          //   0.5,
                          // );
                          // final user = await _loginGoogle();
                          // if (mounted) {
                          //   if (user == null) {
                          //     setState(() {
                          //       _loading = false;
                          //     });
                          //     widget.currentScaffold.currentState!
                          //         .showBodyScrim(false, 0.5);
                          //   }
                          // }
                        },
                  color: kdarkblue,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  height: 55,
                  minWidth: 248,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // const HugeIcon(
                      //   icon: HugeIcons.strokeRoundedGoogle,
                      //   color: Color.fromARGB(255, 32, 139, 226),
                      //   size: 24.0,
                      // ),
                      Image.asset(
                        'assets/images/googleicon.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "Sign in with gmail",
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            height: 1.56,
                            color: kwhite25525525510,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getUserString(String inputString) {
    String firstFiveChars = inputString.substring(
      0,
      min(inputString.length, 5),
    );
    return "user$firstFiveChars";
  }

  DateTime documentIdFromCurrentDate() => DateTime.now();

  // void _handlePress() {
  //   HapticFeedback.vibrate();
  //   kIsWeb
  //       ? openBrowser(
  //           'https://www.termsfeed.com/live/a6aab9e4-ed91-4539-8f7a-96e1e0fd8bfd',
  //         )
  //       : Navigator.of(context, rootNavigator: true).push(
  //           MaterialPageRoute(
  //             builder: (context) => const WebViewApp(
  //               uri:
  //                   'https://www.termsfeed.com/live/a6aab9e4-ed91-4539-8f7a-96e1e0fd8bfd',
  //             ),
  //           ),
  //         );
  // }

  final emptyUser = UserProfileModel(
    id: '',

    name: '',
    profilePicUrl: '',

    email: '',

    fcmToken: '',

    isVerified: false,

    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget _buildFormEmail() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFormChildrenEmail(),
      ),
    );
  }

  List<Widget> _buildFormChildrenEmail() {
    return [
      Text(
        'Email',
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            //  color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextFormField(
        validator: (value) {
          if (value!.isEmpty) {
            return 'Email';
          }
          return null;
        },
        initialValue: '',
        onSaved: (value) => _email = value!.trim(),
        style: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: kblackgrey62606310,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMail01,
            color: kblack00008,
            size: 24.0,
          ),
          fillColor: kwhite25525525510,
          label: Text(
            ' Email ',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: kblackgrey62606310,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          filled: true,
          hintText: '',
          labelStyle: const TextStyle(
            color: kblackgrey62606310,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: kblackgrey79797910, width: 0.5),
            // borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: kblackgrey79797910, width: 0.5),
            // borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusColor: const Color.fromRGBO(243, 242, 242, 1),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: kblackgrey79797910, width: 0.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
          hintStyle: GoogleFonts.dmSans(
            textStyle: const TextStyle(
              color: kblackgrey62606310,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        maxLines: 1,
        textAlign: TextAlign.start,
      ),
      const SizedBox(height: 15),
      Text(
        'Password',
        style: GoogleFonts.inter(
          textStyle: const TextStyle(
            //  color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextFormField(
        validator: (value) {
          if (value!.isEmpty) {
            return 'Password';
          }
          return null;
        },
        initialValue: '',
        onSaved: (value) => _password = value!.trim(),
        style: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: kblackgrey62606310,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        decoration: InputDecoration(
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedLockPassword,
            color: kblack00008,
            size: 24.0,
          ),
          fillColor: kwhite25525525510,
          filled: true,
          label: Text(
            ' Password ',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: kblackgrey62606310,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          hintText: '',
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: kblackgrey79797910, width: 0.5),
            // borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: kblackgrey79797910, width: 0.5),
            // borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusColor: const Color.fromRGBO(243, 242, 242, 1),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: kblackgrey79797910, width: 0.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
          hintStyle: GoogleFonts.dmSans(
            textStyle: const TextStyle(
              color: kblackgrey62606310,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        maxLines: 1,
        textAlign: TextAlign.start,
      ),
    ];
  }

  Future<void> openBrowser(String url) async {
    Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
