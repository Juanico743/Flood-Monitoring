import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Lottie.asset(
                'assets/lottie/loading.json',
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
