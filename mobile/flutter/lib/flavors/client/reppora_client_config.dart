// Compile-time config for the Reppora Client flavor.
// Kept as a separate file so tests can import without booting the App widget.

class RepporaClientConfig {
  final String bundleId;
  final String deepLinkScheme;
  final String appStoreName;
  final bool poweredByFooter;
  final String backendBaseUrl;

  const RepporaClientConfig({
    required this.bundleId,
    required this.deepLinkScheme,
    required this.appStoreName,
    required this.poweredByFooter,
    required this.backendBaseUrl,
  });

  static const RepporaClientConfig values = RepporaClientConfig(
    bundleId: 'com.reppora.app',
    deepLinkScheme: 'reppora',
    appStoreName: 'Reppora',
    poweredByFooter: true,
    backendBaseUrl: 'https://reppora-backend.onrender.com',
  );
}
