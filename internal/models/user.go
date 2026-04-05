package models

import "time"

type Role string

const (
	RoleUser  Role = "user"
	RoleAdmin Role = "admin"
)

type Language string

const (
	LangUzbek   Language = "uz"
	LangRussian Language = "ru"
	LangEnglish Language = "en"
)

type User struct {
	ID        string    `json:"id"`
	Phone     string    `json:"phone"`
	Role      Role      `json:"role"`
	Language  Language  `json:"language"`
	FullName  string    `json:"full_name,omitempty"`
	AvatarURL string    `json:"avatar_url,omitempty"`
	FcmToken  string    `json:"fcm_token,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
