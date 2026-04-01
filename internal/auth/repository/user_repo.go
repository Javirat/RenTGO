package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type UserRepository struct {
	db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) FindByPhone(ctx context.Context, phone string) (*models.User, error) {
	var u models.User
	err := r.db.QueryRow(ctx,
		`SELECT id, phone, role, language, COALESCE(full_name,''), COALESCE(avatar_url,''), created_at, updated_at
		 FROM users WHERE phone = $1`, phone).
		Scan(&u.ID, &u.Phone, &u.Role, &u.Language, &u.FullName, &u.AvatarURL, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	var u models.User
	err := r.db.QueryRow(ctx,
		`SELECT id, phone, role, language, COALESCE(full_name,''), COALESCE(avatar_url,''), created_at, updated_at
		 FROM users WHERE id = $1`, id).
		Scan(&u.ID, &u.Phone, &u.Role, &u.Language, &u.FullName, &u.AvatarURL, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserRepository) Create(ctx context.Context, phone string, role models.Role, lang models.Language) (*models.User, error) {
	var u models.User
	err := r.db.QueryRow(ctx,
		`INSERT INTO users (phone, role, language) VALUES ($1, $2, $3)
		 RETURNING id, phone, role, language, COALESCE(full_name,''), COALESCE(avatar_url,''), created_at, updated_at`,
		phone, role, lang).
		Scan(&u.ID, &u.Phone, &u.Role, &u.Language, &u.FullName, &u.AvatarURL, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}
	return &u, nil
}

func (r *UserRepository) Update(ctx context.Context, u *models.User) error {
	_, err := r.db.Exec(ctx,
		`UPDATE users SET full_name=$1, avatar_url=$2, language=$3, role=$4, updated_at=NOW() WHERE id=$5`,
		u.FullName, u.AvatarURL, u.Language, u.Role, u.ID)
	return err
}
