class ApiEndpoints {
  // URL de base du backend FastAPI.
  // Surcharge au lancement :
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000
  //
  // Valeurs selon la cible :
  //   - Émulateur Android        -> http://10.0.2.2:8000   (PAS localhost)
  //   - Simulateur iOS / desktop -> http://localhost:8000
  //   - Téléphone physique       -> http://<IP-LAN-de-ta-machine>:8000
  //     (lancer le backend en --host 0.0.0.0 ; Docker le fait déjà)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Endpoints (voir backend/app/api/)
  static const String health = '/health';
  static const String scanBarcode = '/v1/scan/barcode';
}
