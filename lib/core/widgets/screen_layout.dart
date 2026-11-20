import 'package:material_ui/material_ui.dart';

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
    this.pinned = false,
  });

  final List<Widget> body;
  final List<Widget> actions;

  /// Screen-margin padding for [body]. Off when the body uses panels,
  /// which bring their own margin.
  final bool padded;

  /// Keeps [actions] fixed at the bottom while only [body] scrolls. For
  /// screens whose list can be long and whose live line ("Rs 200 left to
  /// assign") and Done must stay in view: split, payers, items.
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    const margin = EdgeInsets.symmetric(
      horizontal: AppSpacing.screenHorizontal,
    );
    if (pinned) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // Short lists (people, items): build them all at once.
              child: SingleChildScrollView(
                padding: padded ? margin : EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: body,
                ),
              ),
            ),
            Padding(
              padding: margin.copyWith(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions,
              ),
            ),
          ],
        ),
      );
    }
    // SliverFillRemaining instead of IntrinsicHeight: some children (the QR
    // code) can't report an intrinsic height, which left the screen blank.
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: padded ? margin : EdgeInsets.zero,
            sliver: SliverList.list(children: body),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: actions.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: margin.copyWith(
                      top: AppSpacing.xl,
                      bottom: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: actions,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
