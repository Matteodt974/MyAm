class ApiEndpoints {
  // URL de base du backend.
  // Deux backends interchangeables exposent le MEME contrat :
  //   - FastAPI (../backend)        -> port 8000  (defaut ci-dessous)
  //   - Spring Boot (../backend_spring) -> port 8080
  // Surcharge au lancement :
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # backend Spring
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

  // Endpoints (voir backend/app/api/ ou backend_spring/src/main/.../api/*).
  static const String health = '/health';
  static const String scanBarcode = '/v1/scan/barcode';
  static const String scanDish = '/v1/scan/dish';
}
