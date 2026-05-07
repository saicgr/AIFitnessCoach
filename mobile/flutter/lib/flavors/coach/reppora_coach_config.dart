// Compile-time config for the Reppora Coach flavor.

class RepporaCoachConfig {
  final String bundleId;
  final String deepLinkScheme;
  final String appStoreName;
  final String backendBaseUrl;

  const RepporaCoachConfig({
    required this.bundleId,
    required this.deepLinkScheme,
    required this.appStoreName,
    required this.backendBaseUrl,
  });

  static const RepporaCoachConfig values = RepporaCoachConfig(
    bundleId: 'com.reppora.coach',
    deepLinkScheme: 'reppora-coach',
    appStoreName: 'Reppora for Coach',
    backendBaseUrl: 'https://reppora-backend.onrender.com',
  );
}
