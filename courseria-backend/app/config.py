from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    ENV: str = "development"  # "development" or "production"
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_SERVICE_ROLE_KEY: str
    JWT_SECRET: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200  # 30 days for local offline usage
    
    # Backdoor settings
    ENABLE_DEV_BACKDOOR: bool = True
    DEV_BACKDOOR_CODE: str = "@1258998521@"
    
    # Production CORS settings
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:3006,http://127.0.0.1:3000"
    
    @property
    def is_production(self) -> bool:
        return self.ENV.lower() == "production"

    # Green API (WhatsApp) settings
    WA_API_URL: str = "https://api.green-api.com"
    WA_ID_INSTANCE: str = ""
    WA_TOKEN_INSTANCE: str = ""
    
    # Telegram Bot settings
    TG_API_URL: str = "https://api.green-api.com" # Green API supports TG too
    TG_ID_INSTANCE: str = ""
    TG_TOKEN_INSTANCE: str = ""

    # Resend Email API settings
    EMAIL_API_KEY: str = ""
    EMAIL_API_URL: str = "https://api.resend.com/emails"
    FROM_EMAIL: str = "onboarding@resend.dev"

    # AI settings
    OPENROUTER_API_KEY: str = ""
    OPENROUTER_URL: str = "https://openrouter.ai/api/v1/chat/completions"
    DEFAULT_AI_MODEL: str = "google/gemini-2.0-flash-exp:free"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

@lru_cache()
def get_settings():
    return Settings()
