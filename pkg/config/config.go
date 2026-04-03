package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	App      AppConfig
	Postgres PostgresConfig
	Redis    RedisConfig
	MinIO    MinIOConfig
	JWT      JWTConfig
	OTP      OTPConfig
	Eskiz    EskizConfig
	Telegram TelegramConfig
}

type EskizConfig struct {
	Email    string
	Password string
}

type TelegramConfig struct {
	BotToken string
}

type AppConfig struct {
	Port string
	Env  string
}

type PostgresConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DB       string
}

func (p PostgresConfig) DSN() string {
	return "host=" + p.Host +
		" port=" + p.Port +
		" user=" + p.User +
		" password=" + p.Password +
		" dbname=" + p.DB +
		" sslmode=disable"
}

type RedisConfig struct {
	Host string
	Port string
}

func (r RedisConfig) Addr() string {
	return r.Host + ":" + r.Port
}

type MinIOConfig struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	UseSSL    bool
}

type JWTConfig struct {
	Secret string
	Expiry time.Duration
}

type OTPConfig struct {
	Length int
	Expiry time.Duration
}

func Load() *Config {
	return &Config{
		App: AppConfig{
			Port: getEnv("APP_PORT", "8080"),
			Env:  getEnv("APP_ENV", "development"),
		},
		Postgres: PostgresConfig{
			Host:     getEnv("POSTGRES_HOST", "localhost"),
			Port:     getEnv("POSTGRES_PORT", "5432"),
			User:     getEnv("POSTGRES_USER", "rentgo"),
			Password: getEnv("POSTGRES_PASSWORD", "rentgo_secret"),
			DB:       getEnv("POSTGRES_DB", "rentgo"),
		},
		Redis: RedisConfig{
			Host: getEnv("REDIS_HOST", "localhost"),
			Port: getEnv("REDIS_PORT", "6379"),
		},
		MinIO: MinIOConfig{
			Endpoint:  getEnv("MINIO_ENDPOINT", "localhost:9000"),
			AccessKey: getEnv("MINIO_ACCESS_KEY", "minioadmin"),
			SecretKey: getEnv("MINIO_SECRET_KEY", "minioadmin"),
			Bucket:    getEnv("MINIO_BUCKET", "rentgo-images"),
			UseSSL:    getEnv("MINIO_USE_SSL", "false") == "true",
		},
		JWT: JWTConfig{
			Secret: getEnv("JWT_SECRET", "change-me-in-production"),
			Expiry: time.Duration(getEnvInt("JWT_EXPIRY_HOURS", 72)) * time.Hour,
		},
		OTP: OTPConfig{
			Length: getEnvInt("OTP_LENGTH", 5),
			Expiry: time.Duration(getEnvInt("OTP_EXPIRY_SECONDS", 300)) * time.Second,
		},
		Eskiz: EskizConfig{
			Email:    getEnv("ESKIZ_EMAIL", ""),
			Password: getEnv("ESKIZ_PASSWORD", ""),
		},
		Telegram: TelegramConfig{
			BotToken: getEnv("TELEGRAM_BOT_TOKEN", ""),
		},
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return fallback
}
