import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Full-screen Lottie popup with fixed settings
/// Auto-closes after 5 seconds, black semi-transparent background, Lottie size 300x300
void showFullScreenLottiePopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // cannot tap outside
    builder: (context) {
      // auto close after 5 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });

      return Dialog(
        backgroundColor: Colors.transparent, // transparent dialog
        insetPadding: EdgeInsets.zero,       // full screen
        child: SizedBox.expand(
          child: Container(
            color: Colors.black.withOpacity(0.8), // semi-transparent black
            child: Center(
              child: Lottie.asset(
                'assets/lottie/loading.json', // fixed Lottie file
                width: 300,
                height: 300,
                fit: BoxFit.contain,
                repeat: false,
              ),
            ),
          ),
        ),
      );
    },
  );
}
