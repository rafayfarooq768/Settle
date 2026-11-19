import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Uses the whole screen (DESIGN.md §4): [body] from the top, [actions]
/// pinned to the bottom in the thumb zone. When the keyboard is up or the
/// screen is short, everything scrolls together instead of overflowing.
class ScreenLayout extends StatelessWidget {
  const ScreenLayout({
    super.key,
    required this.body,
    this.actions = const [],
    this.padded = true,
  });

  final List<Widget> body;
  final List<Widget> actions;

  /// Screen-margin padding for [body]. Off when the body uses panels,
  /// which bring their own margin.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    const margin = EdgeInsets.symmetric(
      horizontal: AppSpacing.screenHorizontal,
    );
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: padded ? margin : EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: body,
                    ),
                  ),
                  const Spacer(),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: margin.copyWith(
                        top: AppSpacing.xl,
                        bottom: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
