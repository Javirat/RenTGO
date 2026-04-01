package service

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/MuhammadYahyo/RenTGO/pkg/config"
)

type OTPService struct {
	rdb    *redis.Client
	config config.OTPConfig
}

func NewOTPService(rdb *redis.Client, cfg config.OTPConfig) *OTPService {
	return &OTPService{rdb: rdb, config: cfg}
}

func (s *OTPService) Generate(ctx context.Context, phone string) (string, error) {
	code := generateCode(s.config.Length)
	key := "otp:" + phone
	err := s.rdb.Set(ctx, key, code, s.config.Expiry).Err()
	if err != nil {
		return "", fmt.Errorf("store OTP: %w", err)
	}
	return code, nil
}

func (s *OTPService) Verify(ctx context.Context, phone, code string) (bool, error) {
	key := "otp:" + phone
	stored, err := s.rdb.Get(ctx, key).Result()
	if err == redis.Nil {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("get OTP: %w", err)
	}
	if stored != code {
		return false, nil
	}
	s.rdb.Del(ctx, key)
	return true, nil
}

func (s *OTPService) SetCooldown(ctx context.Context, phone string) error {
	key := "otp_cooldown:" + phone
	return s.rdb.Set(ctx, key, "1", 60*time.Second).Err()
}

func (s *OTPService) HasCooldown(ctx context.Context, phone string) bool {
	key := "otp_cooldown:" + phone
	exists, _ := s.rdb.Exists(ctx, key).Result()
	return exists > 0
}

func generateCode(length int) string {
	code := ""
	for i := 0; i < length; i++ {
		n, _ := rand.Int(rand.Reader, big.NewInt(10))
		code += fmt.Sprintf("%d", n.Int64())
	}
	return code
}
