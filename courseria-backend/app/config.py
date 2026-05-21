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
    
    # Production CORS settings
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:3006,http://127.0.0.1:3000"
    
    @property
    def is_production(self) -> bool:
        return self.ENV.lower() == "production"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

@lru_cache()
def get_settings():
    return Settings()
