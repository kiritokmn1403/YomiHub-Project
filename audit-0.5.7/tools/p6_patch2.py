from ed import *
R='lib/router/router.dart'
sub(R,"import 'package:go_router/go_router.dart';\n","import 'package:go_router/go_router.dart';\nimport 'package:mangayomi/yomihub/ui/shiori/shiori_transitions.dart';\nimport 'package:mangayomi/yomihub/ui/ui_style.dart';\n")
sub(R,"""      pageBuilder: isApple
          ? (context, state) {
              final pageChild = builder != null
                  ? builder(_extraOf<T>(state))
                  : child!;
              return transitionPage(key: state.pageKey, child: pageChild);
            }
          : null,
""","""      pageBuilder: isApple
          ? (context, state) {
              final pageChild = builder != null
                  ? builder(_extraOf<T>(state))
                  : child!;
              return transitionPage(key: state.pageKey, child: pageChild);
            }
          : shioriTransitions
          ? (context, state) {
              // YomiHub 0.5.7 (U11): "Moi" UI style -> Shiori shared-axis
              // transition. Decided when the router is built (a restart
              // applies a changed style); the classic style keeps the
              // default page of go_router untouched.
              Widget pageChild;
              if (builder != null) {
                try {
                  pageChild = builder(_extraOf<T>(state));
                } on _MissingExtra {
                  pageChild = const _LostPage();
                }
              } else {
                pageChild = child!;
              }
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: pageChild,
                transitionDuration: ShioriPageTransition.duration,
                reverseTransitionDuration: ShioriPageTransition.duration,
                transitionsBuilder: (context, animation, secondary, c) =>
                    ShioriPageTransition(
                      animation: animation,
                      secondaryAnimation: secondary,
                      child: c,
                    ),
              );
            }
          : null,
""")
sub(R,"  GoRoute _genericRoute<T>({","  /// True for the \"Moi\" UI style on non-Apple, non-TV builds (U11).\n  bool get shioriTransitions => !isApple && !isTv && YomiUi.isModern;\n\n  GoRoute _genericRoute<T>({")
