package models

import "time"

type Category string

const (
	CategoryHouse Category = "house"
	CategoryCar   Category = "car"
)

type Property struct {
	ID          string    `json:"id"`
	OwnerID     string    `json:"owner_id"`
	Title       string    `json:"title"`
	Description string    `json:"description,omitempty"`
	Price       float64   `json:"price"`
	Rooms       int       `json:"rooms,omitempty"`
	Capacity    int       `json:"capacity,omitempty"`
	Region      string    `json:"region,omitempty"`
	Address     string    `json:"address,omitempty"`
	Lat         float64   `json:"lat,omitempty"`
	Lng         float64   `json:"lng,omitempty"`
	Category    Category  `json:"category"`
	HasCCTV     bool      `json:"has_cctv"`
	ViewsCount  int       `json:"views_count"`
	IsActive    bool      `json:"is_active"`
	Images      []Image   `json:"images,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Image struct {
	ID         string    `json:"id"`
	PropertyID string    `json:"property_id"`
	MinioURL   string    `json:"minio_url"`
	IsPrimary  bool      `json:"is_primary"`
	CreatedAt  time.Time `json:"created_at"`
}

type PropertyFilter struct {
	Category string  `json:"category,omitempty"`
	Region   string  `json:"region,omitempty"`
	MinPrice float64 `json:"min_price,omitempty"`
	MaxPrice float64 `json:"max_price,omitempty"`
	Rooms    int     `json:"rooms,omitempty"`
	Page     int     `json:"page"`
	PageSize int     `json:"page_size"`
}
