import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pie_menu/src/pie_button.dart';
import 'package:pie_menu/src/pie_canvas.dart';
import 'package:pie_menu/src/pie_menu.dart';
import 'package:pie_menu/src/pie_theme.dart';
import 'package:vector_math/vector_math.dart' hide Matrix4;

/// Customized [FlowDelegate] to size and position pie actions efficiently.
class PieDelegate extends FlowDelegate {
  PieDelegate({
    required this.bounceController,
    required this.pointerOffset,
    required this.canvasOffset,
    required this.baseAngle,
    required this.angleDiff,
    required this.theme,
  }) : super(repaint: bounceController);

  /// Animation controller for the buttons.
  final AnimationController bounceController;

  /// Offset of the widget displayed in the center of the [PieMenu].
  final Offset pointerOffset;

  /// Offset of the [PieCanvas].
  final Offset canvasOffset;

  /// Angle of the first [PieButton] in degrees.
  final double baseAngle;

  /// Angle difference between the [PieButton]s in degrees.
  final double angleDiff;

  /// Theme to use for the [PieMenu].
  final PieTheme theme;

  @override
  bool shouldRepaint(PieDelegate oldDelegate) {
    return bounceController != oldDelegate.bounceController;
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final dx = pointerOffset.dx - canvasOffset.dx;
    final dy = pointerOffset.dy - canvasOffset.dy;
    final count = context.childCount;
    final buttonCount = count - 1;

    final totalDuration = bounceController.duration;

    Animation<double> getAnimation(int index) {
      if (theme.pieAnimationStyle != PieAnimationStyle.stagger ||
          buttonCount <= 0 ||
          totalDuration == null) {
        return CurvedAnimation(
          parent: bounceController,
          curve: theme.pieBounceCurve,
        );
      }

      final staggerDelay =
          totalDuration.inMilliseconds /
          buttonCount *
          theme.pieStaggerDelayFactor;
      final start = min(totalDuration.inMilliseconds, staggerDelay * index);

      return CurvedAnimation(
        parent: bounceController,
        curve: Interval(
          start / totalDuration.inMilliseconds,
          1,
          curve: theme.pieBounceCurve,
        ),
      );
    }

    for (var i = 0; i < count; ++i) {
      final size = context.getChildSize(i)!;
      final angleInRadians = radians(
        baseAngle - theme.angleOffset - angleDiff * (i - 1),
      );
      if (i == 0) {
        context.paintChild(
          i,
          transform: Matrix4.translationValues(
            dx - size.width / 2,
            dy - size.height / 2,
            0,
          ),
        );
      } else {
        final animation = getAnimation(i - 1);
        context.paintChild(
          i,
          transform: Matrix4.translationValues(
            dx -
                size.width / 2 +
                theme.radius * cos(angleInRadians) * animation.value,
            dy -
                size.height / 2 -
                theme.radius * sin(angleInRadians) * animation.value,
            0,
          ),
        );
      }
    }
  }

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tight(
      Size.square(i == 0 ? theme.pointerSize : theme.buttonSize),
    );
  }
}
