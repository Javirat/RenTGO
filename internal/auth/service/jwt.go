package service

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
	"github.com/MuhammadYahyo/RenTGO/pkg/config"
)

type Claims struct {
	UserID   string      `json:"user_id"`
	Phone    string      `json:"phone"`
	Role     models.Role `json:"role"`
	jwt.RegisteredClaims
}

type JWTService struct {
	config config.JWTConfig
}

func NewJWTService(cfg config.JWTConfig) *JWTService {
	return &JWTService{config: cfg}
}

func (s *JWTService) GenerateToken(user *models.User) (string, error) {
	claims := Claims{
		UserID: user.ID,
		Phone:  user.Phone,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.config.Expiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.config.Secret))
}

func (s *JWTService) ValidateToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(s.config.Secret), nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}
