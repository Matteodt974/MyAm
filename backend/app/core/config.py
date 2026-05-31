"""Configuration centralisée, lue depuis les variables d'environnement (.env).

pydantic-settings valide les types automatiquement : si une var est absente
ou mal typée, l'app refuse de démarrer plutôt que de planter à la 1re requête.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "INM5151 Scan API"
    environment: str = "development"

    # Optionnel tant que tu n'as pas branché la BD
    database_url: str | None = None

    # Services internes (noms de service docker-compose)
    ocr_url: str = "http://ocr:8001"
    translate_url: str = "http://libretranslate:5000"

    # APIs externes open data
    off_base_url: str = "https://world.openfoodfacts.org"
    obf_base_url: str = "https://world.openbeautyfacts.org"

    # ⚠️ Open Food Facts EXIGE un User-Agent identifiable, sinon ton IP serveur
    # peut être throttlée/bannie. Mets un vrai contact d'équipe.
    off_user_agent: str = "INM5151-ScanApp/0.1 (contact: ton-email@uqam.ca)"


settings = Settings()
