import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: web_only.renderButton(
      configuration: web_only.GSIButtonConfiguration(
        theme: web_only.GSIButtonTheme.outline,
        size: web_only.GSIButtonSize.large,
        shape: web_only.GSIButtonShape.pill,
        text: web_only.GSIButtonText.continueWith,
        logoAlignment: web_only.GSIButtonLogoAlignment.left,
        minimumWidth: 300,
      ),
    ),
  );
}
