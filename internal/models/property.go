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
	OwnerName   string    `json:"owner_name,omitempty"`
	OwnerPhone  string    `json:"owner_phone,omitempty"`
	Title       string    `json:"title"`
	Description string    `json:"description,omitempty"`
	Price       float64   `json:"price"`
	Currency    string    `json:"currency,omitempty"`
	Rooms       int       `json:"rooms,omitempty"`
	Capacity    int       `json:"capacity,omitempty"`
	Region      string    `json:"region,omitempty"`
	Address     string    `json:"address,omitempty"`
	Lat         float64   `json:"lat,omitempty"`
	Lng         float64   `json:"lng,omitempty"`
	Category    Category  `json:"category"`
	HasCCTV     bool      `json:"has_cctv"`
	// House features
	Floor       int    `json:"floor,omitempty"`
	TotalFloors int    `json:"total_floors,omitempty"`
	Furnished   bool   `json:"furnished"`
	Renovation  string `json:"renovation,omitempty"`
	Balcony     bool   `json:"balcony"`
	Parking     bool   `json:"parking"`
	Wifi        bool   `json:"wifi"`
	Washer      bool   `json:"washer"`
	Conditioner bool   `json:"conditioner"`
	Fridge      bool   `json:"fridge"`
	TV          bool   `json:"tv"`
	// Car features
	CarBrand        string `json:"car_brand,omitempty"`
	CarYear         int    `json:"car_year,omitempty"`
	CarTransmission string `json:"car_transmission,omitempty"`
	CarFuel         string `json:"car_fuel,omitempty"`
	CarMileage      int    `json:"car_mileage,omitempty"`
	CarColor        string `json:"car_color,omitempty"`
	CarAC           bool   `json:"car_ac"`
	CarSeats        int    `json:"car_seats,omitempty"`
	// Meta
	ViewsCount int       `json:"views_count"`
	IsActive   bool      `json:"is_active"`
	Status     string    `json:"status"`
	Images     []Image   `json:"images,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type Image struct {
	ID         string    `json:"id"`
	PropertyID string    `json:"property_id"`
	MinioURL   string    `json:"minio_url"`
	IsPrimary  bool      `json:"is_primary"`
	CreatedAt  time.Time `json:"created_at"`
}

type PropertyFilter struct {
	Search   string  `json:"search,omitempty"`
	Category string  `json:"category,omitempty"`
	Region   string  `json:"region,omitempty"`
	MinPrice float64 `json:"min_price,omitempty"`
	MaxPrice float64 `json:"max_price,omitempty"`
	Rooms    int     `json:"rooms,omitempty"`
	OwnerID  string  `json:"owner_id,omitempty"`
	Page     int     `json:"page"`
	PageSize int     `json:"page_size"`
}
