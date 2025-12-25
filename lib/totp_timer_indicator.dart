import 'package:flutter/material.dart';

class TotpTimerIndicator extends StatelessWidget {
  final int period;

  const TotpTimerIndicator({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);
    final progress = remaining / period;

    return SizedBox(
      width: 36,
      height: 36,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: progress, end: progress),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade300,
              ),
              Text(
                remaining.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
