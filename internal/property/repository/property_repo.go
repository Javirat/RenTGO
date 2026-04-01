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
		`INSERT INTO properties (owner_id, title, description, price, rooms, capacity, region, address, lat, lng, category, has_cctv)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
		 RETURNING id, created_at, updated_at`,
		p.OwnerID, p.Title, p.Description, p.Price, p.Rooms, p.Capacity,
		p.Region, p.Address, p.Lat, p.Lng, p.Category, p.HasCCTV,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)
}

func (r *PropertyRepository) GetByID(ctx context.Context, id string) (*models.Property, error) {
	var p models.Property
	err := r.db.QueryRow(ctx,
		`SELECT id, owner_id, title, COALESCE(description,''), price, COALESCE(rooms,0), COALESCE(capacity,0),
		        COALESCE(region,''), COALESCE(address,''), COALESCE(lat,0), COALESCE(lng,0),
		        category, has_cctv, views_count, is_active, created_at, updated_at
		 FROM properties WHERE id = $1`, id).
		Scan(&p.ID, &p.OwnerID, &p.Title, &p.Description, &p.Price, &p.Rooms, &p.Capacity,
			&p.Region, &p.Address, &p.Lat, &p.Lng, &p.Category, &p.HasCCTV,
			&p.ViewsCount, &p.IsActive, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
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
		`UPDATE properties SET title=$1, description=$2, price=$3, rooms=$4, capacity=$5,
		 region=$6, address=$7, lat=$8, lng=$9, category=$10, has_cctv=$11, is_active=$12, updated_at=NOW()
		 WHERE id=$13 AND owner_id=$14`,
		p.Title, p.Description, p.Price, p.Rooms, p.Capacity,
		p.Region, p.Address, p.Lat, p.Lng, p.Category, p.HasCCTV, p.IsActive,
		p.ID, p.OwnerID)
	return err
}

func (r *PropertyRepository) Delete(ctx context.Context, id, ownerID string) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM properties WHERE id = $1 AND owner_id = $2`, id, ownerID)
	return err
}

func (r *PropertyRepository) List(ctx context.Context, f models.PropertyFilter) ([]models.Property, int, error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	conditions = append(conditions, "is_active = TRUE")

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

	query := `SELECT id, owner_id, title, COALESCE(description,''), price, COALESCE(rooms,0), COALESCE(capacity,0),
	          COALESCE(region,''), COALESCE(address,''), category, has_cctv, views_count, created_at
	          FROM properties WHERE ` + where +
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
		if err := rows.Scan(&p.ID, &p.OwnerID, &p.Title, &p.Description, &p.Price,
			&p.Rooms, &p.Capacity, &p.Region, &p.Address, &p.Category,
			&p.HasCCTV, &p.ViewsCount, &p.CreatedAt); err != nil {
			return nil, 0, err
		}
		properties = append(properties, p)
	}

	return properties, total, nil
}

func (r *PropertyRepository) IncrementViews(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `UPDATE properties SET views_count = views_count + 1 WHERE id = $1`, id)
	return err
}

func (r *PropertyRepository) ListByOwner(ctx context.Context, ownerID string) ([]models.Property, error) {
	rows, err := r.db.Query(ctx,
		`SELECT id, owner_id, title, COALESCE(description,''), price, COALESCE(rooms,0), COALESCE(capacity,0),
		 COALESCE(region,''), COALESCE(address,''), category, has_cctv, views_count, is_active, created_at
		 FROM properties WHERE owner_id = $1 ORDER BY created_at DESC`, ownerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var properties []models.Property
	for rows.Next() {
		var p models.Property
		if err := rows.Scan(&p.ID, &p.OwnerID, &p.Title, &p.Description, &p.Price,
			&p.Rooms, &p.Capacity, &p.Region, &p.Address, &p.Category,
			&p.HasCCTV, &p.ViewsCount, &p.IsActive, &p.CreatedAt); err != nil {
			return nil, err
		}
		properties = append(properties, p)
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
