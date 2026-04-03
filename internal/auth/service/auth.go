package service

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"

	"github.com/MuhammadYahyo/RenTGO/internal/auth/repository"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type AuthService struct {
	userRepo *repository.UserRepository
	otp      *OTPService
	jwt      *JWTService
	sms      *SMSService
	telegram *TelegramService
}

func NewAuthService(repo *repository.UserRepository, otp *OTPService, jwt *JWTService, sms *SMSService, tg *TelegramService) *AuthService {
	return &AuthService{userRepo: repo, otp: otp, jwt: jwt, sms: sms, telegram: tg}
}

func (s *AuthService) SendOTP(ctx context.Context, phone string) (string, error) {
	if s.otp.HasCooldown(ctx, phone) {
		return "", fmt.Errorf("please wait before requesting a new OTP")
	}

	code, err := s.otp.Generate(ctx, phone)
	if err != nil {
		return "", err
	}

	sent := false

	// Try Telegram first (free)
	if s.telegram != nil && s.telegram.IsConfigured() {
		if err := s.telegram.SendOTP(phone, code); err != nil {
			log.Printf("[TG] failed to send OTP to %s: %v", phone, err)
		} else {
			sent = true
		}
	}

	// Fallback to SMS if Telegram didn't work
	if !sent && s.sms != nil && s.sms.IsConfigured() {
		message := fmt.Sprintf("RenTGO: Sizning tasdiqlash kodingiz: %s", code)
		if err := s.sms.Send(phone, message); err != nil {
			log.Printf("[SMS] failed to send OTP to %s: %v", phone, err)
		} else {
			sent = true
		}
	}

	if !sent {
		log.Printf("[OTP] Phone: %s, Code: %s (no delivery channel available)", phone, code)
	}

	return code, s.otp.SetCooldown(ctx, phone)
}

func (s *AuthService) VerifyOTP(ctx context.Context, phone, code string, role models.Role, lang models.Language) (string, *models.User, bool, error) {
	ok, err := s.otp.Verify(ctx, phone, code)
	if err != nil {
		return "", nil, false, err
	}
	if !ok {
		return "", nil, false, fmt.Errorf("invalid or expired OTP")
	}

	isNew := false
	user, err := s.userRepo.FindByPhone(ctx, phone)
	if err != nil {
		if err == pgx.ErrNoRows {
			user, err = s.userRepo.Create(ctx, phone, role, lang)
			if err != nil {
				return "", nil, false, fmt.Errorf("create user: %w", err)
			}
			isNew = true
		} else {
			return "", nil, false, err
		}
	}

	token, err := s.jwt.GenerateToken(user)
	if err != nil {
		return "", nil, false, fmt.Errorf("generate token: %w", err)
	}

	return token, user, isNew, nil
}

func (s *AuthService) GetProfile(ctx context.Context, userID string) (*models.User, error) {
	return s.userRepo.FindByID(ctx, userID)
}

func (s *AuthService) UpdateProfile(ctx context.Context, user *models.User) error {
	return s.userRepo.Update(ctx, user)
}
