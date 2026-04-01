package service

import (
	"context"
	"fmt"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
	"github.com/MuhammadYahyo/RenTGO/internal/property/repository"
)

type PropertyService struct {
	repo *repository.PropertyRepository
}

func NewPropertyService(repo *repository.PropertyRepository) *PropertyService {
	return &PropertyService{repo: repo}
}

func (s *PropertyService) Create(ctx context.Context, p *models.Property) error {
	return s.repo.Create(ctx, p)
}

func (s *PropertyService) GetByID(ctx context.Context, id string) (*models.Property, error) {
	p, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	_ = s.repo.IncrementViews(ctx, id)
	return p, nil
}

func (s *PropertyService) Update(ctx context.Context, p *models.Property) error {
	return s.repo.Update(ctx, p)
}

func (s *PropertyService) Delete(ctx context.Context, id, ownerID string) error {
	return s.repo.Delete(ctx, id, ownerID)
}

func (s *PropertyService) List(ctx context.Context, f models.PropertyFilter) ([]models.Property, int, error) {
	return s.repo.List(ctx, f)
}

func (s *PropertyService) ListByOwner(ctx context.Context, ownerID string) ([]models.Property, error) {
	return s.repo.ListByOwner(ctx, ownerID)
}

func (s *PropertyService) AddImage(ctx context.Context, img *models.Image, ownerID string) error {
	prop, err := s.repo.GetByID(ctx, img.PropertyID)
	if err != nil {
		return fmt.Errorf("property not found")
	}
	if prop.OwnerID != ownerID {
		return fmt.Errorf("not authorized")
	}
	return s.repo.AddImage(ctx, img)
}

func (s *PropertyService) DeleteImage(ctx context.Context, imageID, ownerID string) error {
	return s.repo.DeleteImage(ctx, imageID, ownerID)
}
