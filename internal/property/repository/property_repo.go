package repository

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type PropertyRepository struct {
	db *pgxpool.Pool
}

func NewPropertyRepository(db *pgxpool.Pool) *PropertyRepository {
	return &PropertyRepository{db: db}
}

func (r *PropertyRepository) Create(ctx context.Context, p *models.Property) error {
	return r.db.QueryRow(ctx,
		`INSERT INTO properties (owner_id, title, description, price, currency, rooms, capacity, region, address, lat, lng, category, has_cctv,
		 floor, total_floors, furnished, renovation, balcony, parking, wifi, washer, conditioner, fridge, tv,
		 car_brand, car_year, car_transmission, car_fuel, car_mileage, car_color, car_ac, car_seats, status)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,'pending')
		 RETURNING id, created_at, updated_at`,
		p.OwnerID, p.Title, p.Description, p.Price, p.Currency, p.Rooms, p.Capacity,
		p.Region, p.Address, p.Lat, p.Lng, p.Category, p.HasCCTV,
		p.Floor, p.TotalFloors, p.Furnished, p.Renovation, p.Balcony, p.Parking, p.Wifi, p.Washer, p.Conditioner, p.Fridge, p.TV,
		p.CarBrand, p.CarYear, p.CarTransmission, p.CarFuel, p.CarMileage, p.CarColor, p.CarAC, p.CarSeats,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)
}

// columns shared by GetByID and detail queries
const detailCols = `p.id, p.owner_id, COALESCE(u.full_name,''), COALESCE(u.phone,''),
	p.title, COALESCE(p.description,''), p.price, COALESCE(p.currency,'UZS'), COALESCE(p.rooms,0), COALESCE(p.capacity,0),
	COALESCE(p.region,''), COALESCE(p.address,''), COALESCE(p.lat,0), COALESCE(p.lng,0),
	p.category, p.has_cctv,
	COALESCE(p.floor,0), COALESCE(p.total_floors,0), COALESCE(p.furnished,false), COALESCE(p.renovation,''),
	COALESCE(p.balcony,false), COALESCE(p.parking,false), COALESCE(p.wifi,false), COALESCE(p.washer,false),
	COALESCE(p.conditioner,false), COALESCE(p.fridge,false), COALESCE(p.tv,false),
	COALESCE(p.car_brand,''), COALESCE(p.car_year,0), COALESCE(p.car_transmission,''), COALESCE(p.car_fuel,''),
	COALESCE(p.car_mileage,0), COALESCE(p.car_color,''), COALESCE(p.car_ac,false), COALESCE(p.car_seats,0),
	p.views_count, p.is_active, COALESCE(p.status,'pending'), p.created_at, p.updated_at`

func scanDetail(scan func(dest ...any) error, p *models.Property) error {
	return scan(
		&p.ID, &p.OwnerID, &p.OwnerName, &p.OwnerPhone,
		&p.Title, &p.Description, &p.Price, &p.Currency, &p.Rooms, &p.Capacity,
		&p.Region, &p.Address, &p.Lat, &p.Lng, &p.Category, &p.HasCCTV,
		&p.Floor, &p.TotalFloors, &p.Furnished, &p.Renovation,
		&p.Balcony, &p.Parking, &p.Wifi, &p.Washer, &p.Conditioner, &p.Fridge, &p.TV,
		&p.CarBrand, &p.CarYear, &p.CarTransmission, &p.CarFuel, &p.CarMileage, &p.CarColor, &p.CarAC, &p.CarSeats,
		&p.ViewsCount, &p.IsActive, &p.Status, &p.CreatedAt, &p.UpdatedAt,
	)
}

func (r *PropertyRepository) GetByID(ctx context.Context, id string) (*models.Property, error) {
	var p models.Property
	row := r.db.QueryRow(ctx,
		`SELECT `+detailCols+` FROM properties p LEFT JOIN users u ON u.id = p.owner_id WHERE p.id = $1`, id)
	if err := scanDetail(row.Scan, &p); err != nil {
		return nil, err
	}

	images, err := r.GetImages(ctx, id)
	if err == nil {
		p.Images = images
	}

	return &p, nil
}

func (r *PropertyRepository) Update(ctx context.Context, p *models.Property) error {
	_, err := r.db.Exec(ctx,
		`UPDATE properties SET title=$1, description=$2, price=$3, currency=$4, rooms=$5, capacity=$6,
		 region=$7, address=$8, lat=$9, lng=$10, category=$11, has_cctv=$12, is_active=$13,
		 floor=$14, total_floors=$15, furnished=$16, renovation=$17, balcony=$18, parking=$19,
		 wifi=$20, washer=$21, conditioner=$22, fridge=$23, tv=$24,
		 car_brand=$25, car_year=$26, car_transmission=$27, car_fuel=$28, car_mileage=$29, car_color=$30, car_ac=$31, car_seats=$32,
		 status=$33, updated_at=NOW()
		 WHERE id=$34 AND owner_id=$35`,
		p.Title, p.Description, p.Price, p.Currency, p.Rooms, p.Capacity,
		p.Region, p.Address, p.Lat, p.Lng, p.Category, p.HasCCTV, p.IsActive,
		p.Floor, p.TotalFloors, p.Furnished, p.Renovation, p.Balcony, p.Parking,
		p.Wifi, p.Washer, p.Conditioner, p.Fridge, p.TV,
		p.CarBrand, p.CarYear, p.CarTransmission, p.CarFuel, p.CarMileage, p.CarColor, p.CarAC, p.CarSeats,
		p.Status, p.ID, p.OwnerID)
	return err
}

func (r *PropertyRepository) Delete(ctx context.Context, id, ownerID string) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM properties WHERE id = $1 AND owner_id = $2`, id, ownerID)
	return err
}

// columns for list queries (no owner join, no updated_at)
const listCols = `id, owner_id, title, COALESCE(description,''), price, COALESCE(currency,'UZS'), COALESCE(rooms,0), COALESCE(capacity,0),
	COALESCE(region,''), COALESCE(address,''), category, has_cctv,
	COALESCE(floor,0), COALESCE(total_floors,0), COALESCE(furnished,false), COALESCE(renovation,''),
	COALESCE(balcony,false), COALESCE(parking,false), COALESCE(wifi,false), COALESCE(washer,false),
	COALESCE(conditioner,false), COALESCE(fridge,false), COALESCE(tv,false),
	COALESCE(car_brand,''), COALESCE(car_year,0), COALESCE(car_transmission,''), COALESCE(car_fuel,''),
	COALESCE(car_mileage,0), COALESCE(car_color,''), COALESCE(car_ac,false), COALESCE(car_seats,0),
	views_count, COALESCE(status,'pending'), created_at`

func scanList(scan func(dest ...any) error, p *models.Property) error {
	return scan(
		&p.ID, &p.OwnerID, &p.Title, &p.Description, &p.Price, &p.Currency, &p.Rooms, &p.Capacity,
		&p.Region, &p.Address, &p.Category, &p.HasCCTV,
		&p.Floor, &p.TotalFloors, &p.Furnished, &p.Renovation,
		&p.Balcony, &p.Parking, &p.Wifi, &p.Washer, &p.Conditioner, &p.Fridge, &p.TV,
		&p.CarBrand, &p.CarYear, &p.CarTransmission, &p.CarFuel, &p.CarMileage, &p.CarColor, &p.CarAC, &p.CarSeats,
		&p.ViewsCount, &p.Status, &p.CreatedAt,
	)
}

func (r *PropertyRepository) List(ctx context.Context, f models.PropertyFilter) ([]models.Property, int, error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if f.OwnerID != "" {
		// Show approved + own listings (any status)
		conditions = append(conditions, fmt.Sprintf("(is_active = TRUE AND COALESCE(status,'pending') = 'approved' OR owner_id = $%d)", argIdx))
		args = append(args, f.OwnerID)
		argIdx++
	} else {
		conditions = append(conditions, "is_active = TRUE AND COALESCE(status,'pending') = 'approved'")
	}

	if f.Search != "" {
		conditions = append(conditions, fmt.Sprintf("title ILIKE $%d", argIdx))
		args = append(args, "%"+f.Search+"%")
		argIdx++
	}
	if f.Category != "" {
		conditions = append(conditions, fmt.Sprintf("category = $%d", argIdx))
		args = append(args, f.Category)
		argIdx++
	}
	if f.Region != "" {
		conditions = append(conditions, fmt.Sprintf("region ILIKE $%d", argIdx))
		args = append(args, "%"+f.Region+"%")
		argIdx++
	}
	if f.MinPrice > 0 {
		conditions = append(conditions, fmt.Sprintf("price >= $%d", argIdx))
		args = append(args, f.MinPrice)
		argIdx++
	}
	if f.MaxPrice > 0 {
		conditions = append(conditions, fmt.Sprintf("price <= $%d", argIdx))
		args = append(args, f.MaxPrice)
		argIdx++
	}
	if f.Rooms > 0 {
		conditions = append(conditions, fmt.Sprintf("rooms = $%d", argIdx))
		args = append(args, f.Rooms)
		argIdx++
	}

	where := strings.Join(conditions, " AND ")

	// Count
	countQuery := "SELECT COUNT(*) FROM properties WHERE " + where
	var total int
	if err := r.db.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	if f.Page < 1 {
		f.Page = 1
	}
	if f.PageSize < 1 || f.PageSize > 50 {
		f.PageSize = 20
	}
	offset := (f.Page - 1) * f.PageSize

	query := `SELECT ` + listCols + ` FROM properties WHERE ` + where +
		` ORDER BY created_at DESC LIMIT ` + strconv.Itoa(f.PageSize) +
		` OFFSET ` + strconv.Itoa(offset)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var properties []models.Property
	for rows.Next() {
		var p models.Property
		if err := scanList(rows.Scan, &p); err != nil {
			return nil, 0, err
		}
		properties = append(properties, p)
	}

	// Load primary image for each property
	for i := range properties {
		images, err := r.GetImages(ctx, properties[i].ID)
		if err == nil {
			properties[i].Images = images
		}
	}

	return properties, total, nil
}

func (r *PropertyRepository) IncrementViews(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `UPDATE properties SET views_count = views_count + 1 WHERE id = $1`, id)
	return err
}

// listOwnerCols includes is_active
const listOwnerCols = `id, owner_id, title, COALESCE(description,''), price, COALESCE(currency,'UZS'), COALESCE(rooms,0), COALESCE(capacity,0),
	COALESCE(region,''), COALESCE(address,''), category, has_cctv,
	COALESCE(floor,0), COALESCE(total_floors,0), COALESCE(furnished,false), COALESCE(renovation,''),
	COALESCE(balcony,false), COALESCE(parking,false), COALESCE(wifi,false), COALESCE(washer,false),
	COALESCE(conditioner,false), COALESCE(fridge,false), COALESCE(tv,false),
	COALESCE(car_brand,''), COALESCE(car_year,0), COALESCE(car_transmission,''), COALESCE(car_fuel,''),
	COALESCE(car_mileage,0), COALESCE(car_color,''), COALESCE(car_ac,false), COALESCE(car_seats,0),
	views_count, is_active, COALESCE(status,'pending'), created_at`

func scanOwnerList(scan func(dest ...any) error, p *models.Property) error {
	return scan(
		&p.ID, &p.OwnerID, &p.Title, &p.Description, &p.Price, &p.Currency, &p.Rooms, &p.Capacity,
		&p.Region, &p.Address, &p.Category, &p.HasCCTV,
		&p.Floor, &p.TotalFloors, &p.Furnished, &p.Renovation,
		&p.Balcony, &p.Parking, &p.Wifi, &p.Washer, &p.Conditioner, &p.Fridge, &p.TV,
		&p.CarBrand, &p.CarYear, &p.CarTransmission, &p.CarFuel, &p.CarMileage, &p.CarColor, &p.CarAC, &p.CarSeats,
		&p.ViewsCount, &p.IsActive, &p.Status, &p.CreatedAt,
	)
}

func (r *PropertyRepository) ListByOwner(ctx context.Context, ownerID string) ([]models.Property, error) {
	rows, err := r.db.Query(ctx,
		`SELECT `+listOwnerCols+` FROM properties WHERE owner_id = $1 ORDER BY created_at DESC`, ownerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var properties []models.Property
	for rows.Next() {
		var p models.Property
		if err := scanOwnerList(rows.Scan, &p); err != nil {
			return nil, err
		}
		properties = append(properties, p)
	}

	// Load images for each property
	for i := range properties {
		images, err := r.GetImages(ctx, properties[i].ID)
		if err == nil {
			properties[i].Images = images
		}
	}

	return properties, nil
}

// Image operations

func (r *PropertyRepository) AddImage(ctx context.Context, img *models.Image) error {
	return r.db.QueryRow(ctx,
		`INSERT INTO images (property_id, minio_url, is_primary) VALUES ($1, $2, $3) RETURNING id, created_at`,
		img.PropertyID, img.MinioURL, img.IsPrimary).Scan(&img.ID, &img.CreatedAt)
}

func (r *PropertyRepository) GetImages(ctx context.Context, propertyID string) ([]models.Image, error) {
	rows, err := r.db.Query(ctx,
		`SELECT id, property_id, minio_url, is_primary, created_at FROM images WHERE property_id = $1 ORDER BY is_primary DESC`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var images []models.Image
	for rows.Next() {
		var img models.Image
		if err := rows.Scan(&img.ID, &img.PropertyID, &img.MinioURL, &img.IsPrimary, &img.CreatedAt); err != nil {
			return nil, err
		}
		images = append(images, img)
	}
	return images, nil
}

func (r *PropertyRepository) DeleteImage(ctx context.Context, imageID, ownerID string) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM images WHERE id = $1 AND property_id IN (SELECT id FROM properties WHERE owner_id = $2)`,
		imageID, ownerID)
	return err
}
