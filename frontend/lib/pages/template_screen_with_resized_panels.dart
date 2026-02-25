import 'package:flutter/material.dart';

/// Template screen layout update:
/// - "New Experiment Record" panel is wider (left)
/// - "Template Example" panel is about 1/3 narrower (right)
/// - Responsive: on narrow screens, stacks vertically
///
/// How to use in your project:
/// 1) Put this file at: lib/pages/template_screen_with_resized_panels.dart
/// 2) Replace your existing Template screen's build body with:
///      const TemplateScreenWithResizedPanels(
///        left: YourNewExperimentRecordWidget(),
///        right: YourTemplateExampleWidget(),
///      )
///
/// If you already have a Template screen file, you can also copy just the
/// `TemplateSplitLayout` widget below and use it inside your existing screen.
class TemplateScreenWithResizedPanels extends StatelessWidget {
  const TemplateScreenWithResizedPanels({
    super.key,
    required this.left,
    required this.right,
    this.wideBreakpoint = 1000,
    this.gap = 16,
    this.leftFlex = 7,
    this.rightFlex = 2,
    this.rightMinWidth = 280,
    this.rightMaxWidth,
    this.stackedRightHeight = 280,
    this.title,
  });

  /// Main (New Experiment Record) content
  final Widget left;

  /// Right (Template example) content
  final Widget right;

  /// When width >= breakpoint, show side-by-side. Otherwise stack.
  final double wideBreakpoint;

  /// Gap between panels in wide layout
  final double gap;

  /// Wide layout ratio:
  /// - leftFlex/rightFlex=7/2 gives ~78% / ~22% (right ≈ 1/3 narrower vs 2/1 layout).
  final int leftFlex;
  final int rightFlex;

  /// Keep right panel readable.
  final double rightMinWidth;

  /// Optional hard cap on right panel width (useful on ultra-wide screens).
  final double? rightMaxWidth;

  /// In stacked (narrow) mode, right panel height.
  final double stackedRightHeight;

  final String? title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= wideBreakpoint;

        final header = (title == null)
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );

        if (!isWide) {
          // ✅ Narrow: stack vertically
          return Column(
            children: [
              header,
              Expanded(child: _panelWrap(context, left)),
              const Divider(height: 1),
              SizedBox(
                height: stackedRightHeight,
                child: _panelWrap(context, right),
              ),
            ],
          );
        }

        // ✅ Wide: side-by-side with adjusted ratio
        return Column(
          children: [
            header,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: leftFlex, // ✅ left wider
                      child: _panelWrap(context, left),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      flex: rightFlex, // ✅ right narrower
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: rightMinWidth,
                          maxWidth: rightMaxWidth ?? double.infinity,
                        ),
                        child: _panelWrap(context, right),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panelWrap(BuildContext context, Widget child) {
    // A light card wrapper; remove if your UI already wraps panels.
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// If you prefer to keep your existing screen class,
/// you can use this smaller widget directly:
class TemplateSplitLayout extends StatelessWidget {
  const TemplateSplitLayout({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 7,
    this.rightFlex = 2,
    this.wideBreakpoint = 1000,
    this.gap = 16,
    this.rightMinWidth = 280,
    this.rightMaxWidth,
    this.stackedRightHeight = 280,
  });

  final Widget left;
  final Widget right;

  final int leftFlex;
  final int rightFlex;

  final double wideBreakpoint;
  final double gap;

  final double rightMinWidth;
  final double? rightMaxWidth;

  final double stackedRightHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= wideBreakpoint;

        if (!isWide) {
          return Column(
            children: [
              Expanded(child: left),
              const Divider(height: 1),
              SizedBox(height: stackedRightHeight, child: right),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(
              flex: rightFlex,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: rightMinWidth,
                  maxWidth: rightMaxWidth ?? double.infinity,
                ),
                child: right,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Demo widgets (safe to delete).
/// Replace with your real widgets:
class DemoNewExperimentRecordPanel extends StatelessWidget {
  const DemoNewExperimentRecordPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('New Experiment Record', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Objective')),
          const SizedBox(height: 12),
          TextField(
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'Procedure'),
          ),
        ],
      ),
    );
  }
}

class DemoTemplateExamplePanel extends StatelessWidget {
  const DemoTemplateExamplePanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('템플릿 예제', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const Text(
            '예시 내용이 들어가는 영역입니다.\n\n'
            '- Step 1\n- Step 2\n- Notes\n\n'
            '이 패널은 오른쪽에 1/3 더 좁게 배치됩니다.',
          ),
        ],
      ),
    );
  }
}
