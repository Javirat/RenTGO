package repository

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type AdminRepository struct {
	db *pgxpool.Pool
}

func NewAdminRepository(db *pgxpool.Pool) *AdminRepository {
	return &AdminRepository{db: db}
}

// ── Dashboard Stats ──

type DashboardStats struct {
	TotalUsers       int `json:"total_users"`
	TotalRegularUsers int `json:"total_regular_users"`
	TotalAdmins       int `json:"total_admins"`
	TotalProperties  int `json:"total_properties"`
	ActiveProperties int `json:"active_properties"`
	TotalHouses      int `json:"total_houses"`
	TotalCars        int `json:"total_cars"`
	TotalViews       int `json:"total_views"`
	TotalMessages    int `json:"total_messages"`
	TotalConversations int `json:"total_conversations"`
}

func (r *AdminRepository) GetDashboardStats(ctx context.Context) (*DashboardStats, error) {
	var s DashboardStats

	err := r.db.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE role != 'admin'`).Scan(&s.TotalUsers)
	if err != nil {
		return nil, err
	}
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE role = 'user'`).Scan(&s.TotalRegularUsers)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE role = 'admin'`).Scan(&s.TotalAdmins)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM properties`).Scan(&s.TotalProperties)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM properties WHERE is_active = TRUE`).Scan(&s.ActiveProperties)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM properties WHERE category = 'house'`).Scan(&s.TotalHouses)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM properties WHERE category = 'car'`).Scan(&s.TotalCars)
	r.db.QueryRow(ctx, `SELECT COALESCE(SUM(views_count), 0) FROM properties`).Scan(&s.TotalViews)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM messages`).Scan(&s.TotalMessages)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM conversations`).Scan(&s.TotalConversations)

	return &s, nil
}

// ── Users Management ──

type UserListFilter struct {
	Search   string
	Role     string
	Page     int
	PageSize int
}

func (r *AdminRepository) ListUsers(ctx context.Context, f UserListFilter) ([]models.User, int, error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if f.Search != "" {
		conditions = append(conditions, fmt.Sprintf("(phone ILIKE $%d OR COALESCE(full_name,'') ILIKE $%d)", argIdx, argIdx))
		args = append(args, "%"+f.Search+"%")
		argIdx++
	}
	if f.Role != "" {
		conditions = append(conditions, fmt.Sprintf("role = $%d", argIdx))
		args = append(args, f.Role)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = " WHERE " + strings.Join(conditions, " AND ")
	}

	var total int
	r.db.QueryRow(ctx, "SELECT COUNT(*) FROM users"+where, args...).Scan(&total)

	if f.Page < 1 {
		f.Page = 1
	}
	if f.PageSize < 1 || f.PageSize > 50 {
		f.PageSize = 20
	}
	offset := (f.Page - 1) * f.PageSize

	query := `SELECT id, phone, role, language, COALESCE(full_name,''), COALESCE(avatar_url,''), created_at, updated_at
		FROM users` + where + ` ORDER BY created_at DESC LIMIT ` + strconv.Itoa(f.PageSize) + ` OFFSET ` + strconv.Itoa(offset)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var u models.User
		if err := rows.Scan(&u.ID, &u.Phone, &u.Role, &u.Language, &u.FullName, &u.AvatarURL, &u.CreatedAt, &u.UpdatedAt); err != nil {
			return nil, 0, err
		}
		users = append(users, u)
	}
	return users, total, nil
}

func (r *AdminRepository) UpdateUserRole(ctx context.Context, userID string, role models.Role) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2`, role, userID)
	return err
}

func (r *AdminRepository) DeleteUser(ctx context.Context, userID string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM users WHERE id = $1`, userID)
	return err
}

// ── Properties Management ──

type PropertyListFilter struct {
	Search   string
	Category string
	Status   string
	IsActive *bool
	Page     int
	PageSize int
}

func (r *AdminRepository) ListAllProperties(ctx context.Context, f PropertyListFilter) ([]models.Property, int, error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if f.Search != "" {
		conditions = append(conditions, fmt.Sprintf("(p.title ILIKE $%d OR p.region ILIKE $%d)", argIdx, argIdx))
		args = append(args, "%"+f.Search+"%")
		argIdx++
	}
	if f.Category != "" {
		conditions = append(conditions, fmt.Sprintf("p.category = $%d", argIdx))
		args = append(args, f.Category)
		argIdx++
	}
	if f.Status != "" {
		conditions = append(conditions, fmt.Sprintf("COALESCE(p.status,'pending') = $%d", argIdx))
		args = append(args, f.Status)
		argIdx++
	}
	if f.IsActive != nil {
		conditions = append(conditions, fmt.Sprintf("p.is_active = $%d", argIdx))
		args = append(args, *f.IsActive)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = " WHERE " + strings.Join(conditions, " AND ")
	}

	var total int
	r.db.QueryRow(ctx, "SELECT COUNT(*) FROM properties p"+where, args...).Scan(&total)

	if f.Page < 1 {
		f.Page = 1
	}
	if f.PageSize < 1 || f.PageSize > 50 {
		f.PageSize = 20
	}
	offset := (f.Page - 1) * f.PageSize

	query := `SELECT p.id, p.owner_id, COALESCE(u.full_name,''), COALESCE(u.phone,''),
		p.title, COALESCE(p.description,''), p.price, COALESCE(p.currency,'UZS'), COALESCE(p.rooms,0), COALESCE(p.capacity,0),
		COALESCE(p.region,''), COALESCE(p.address,''), p.category, p.has_cctv,
		COALESCE(p.floor,0), COALESCE(p.total_floors,0), COALESCE(p.furnished,false), COALESCE(p.renovation,''),
		COALESCE(p.balcony,false), COALESCE(p.parking,false), COALESCE(p.wifi,false), COALESCE(p.washer,false),
		COALESCE(p.conditioner,false), COALESCE(p.fridge,false), COALESCE(p.tv,false),
		COALESCE(p.car_brand,''), COALESCE(p.car_year,0), COALESCE(p.car_transmission,''), COALESCE(p.car_fuel,''),
		COALESCE(p.car_mileage,0), COALESCE(p.car_color,''), COALESCE(p.car_ac,false), COALESCE(p.car_seats,0),
		p.views_count, p.is_active, COALESCE(p.status,'pending'), p.created_at
		FROM properties p LEFT JOIN users u ON u.id = p.owner_id` + where +
		` ORDER BY p.created_at DESC LIMIT ` + strconv.Itoa(f.PageSize) + ` OFFSET ` + strconv.Itoa(offset)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var properties []models.Property
	for rows.Next() {
		var p models.Property
		if err := rows.Scan(&p.ID, &p.OwnerID, &p.OwnerName, &p.OwnerPhone,
			&p.Title, &p.Description, &p.Price, &p.Currency, &p.Rooms, &p.Capacity,
			&p.Region, &p.Address, &p.Category, &p.HasCCTV,
			&p.Floor, &p.TotalFloors, &p.Furnished, &p.Renovation,
			&p.Balcony, &p.Parking, &p.Wifi, &p.Washer, &p.Conditioner, &p.Fridge, &p.TV,
			&p.CarBrand, &p.CarYear, &p.CarTransmission, &p.CarFuel, &p.CarMileage, &p.CarColor, &p.CarAC, &p.CarSeats,
			&p.ViewsCount, &p.IsActive, &p.Status, &p.CreatedAt); err != nil {
			return nil, 0, err
		}
		properties = append(properties, p)
	}
	return properties, total, nil
}

func (r *AdminRepository) TogglePropertyActive(ctx context.Context, propertyID string, active bool) error {
	_, err := r.db.Exec(ctx, `UPDATE properties SET is_active = $1, updated_at = NOW() WHERE id = $2`, active, propertyID)
	return err
}

func (r *AdminRepository) DeleteProperty(ctx context.Context, propertyID string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM properties WHERE id = $1`, propertyID)
	return err
}

// ── Directories ──

func (r *AdminRepository) ListDirectories(ctx context.Context, dirType string) ([]models.Directory, error) {
	rows, err := r.db.Query(ctx,
		`SELECT id, type, value, COALESCE(value_uz,''), COALESCE(value_ru,''), COALESCE(value_en,''),
		        COALESCE(parent_value,''), sort_order, created_at
		 FROM directories WHERE type = $1 ORDER BY sort_order, value`, dirType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var dirs []models.Directory
	for rows.Next() {
		var d models.Directory
		if err := rows.Scan(&d.ID, &d.Type, &d.Value, &d.ValueUz, &d.ValueRu, &d.ValueEn,
			&d.ParentValue, &d.SortOrder, &d.CreatedAt); err != nil {
			return nil, err
		}
		dirs = append(dirs, d)
	}
	return dirs, nil
}

func (r *AdminRepository) CreateDirectory(ctx context.Context, d *models.Directory) error {
	return r.db.QueryRow(ctx,
		`INSERT INTO directories (type, value, value_uz, value_ru, value_en, parent_value, sort_order)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 ON CONFLICT (type, value) DO UPDATE SET value_uz=$3, value_ru=$4, value_en=$5
		 RETURNING id, created_at`,
		d.Type, d.Value, d.ValueUz, d.ValueRu, d.ValueEn, d.ParentValue, d.SortOrder).Scan(&d.ID, &d.CreatedAt)
}

func (r *AdminRepository) UpdateDirectory(ctx context.Context, d *models.Directory) error {
	_, err := r.db.Exec(ctx,
		`UPDATE directories SET value=$1, value_uz=$2, value_ru=$3, value_en=$4, parent_value=$5 WHERE id=$6`,
		d.Value, d.ValueUz, d.ValueRu, d.ValueEn, d.ParentValue, d.ID)
	return err
}

func (r *AdminRepository) DeleteDirectory(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM directories WHERE id = $1`, id)
	return err
}

func (r *AdminRepository) UpdatePropertyStatus(ctx context.Context, propertyID, status string) error {
	_, err := r.db.Exec(ctx, `UPDATE properties SET status = $1, updated_at = NOW() WHERE id = $2`, status, propertyID)
	return err
}

func (r *AdminRepository) ListAllConversations(ctx context.Context) ([]models.Conversation, error) {
	rows, err := r.db.Query(ctx,
		`SELECT c.id, c.property_id, c.renter_id, c.landlord_id, c.last_message_at, c.created_at,
		        COALESCE(p.title, ''),
		        COALESCE(u1.full_name, u1.phone, ''),
		        COALESCE(u2.full_name, u2.phone, ''),
		        COALESCE((SELECT text FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1), ''),
		        (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id)
		 FROM conversations c
		 LEFT JOIN properties p ON p.id = c.property_id
		 LEFT JOIN users u1 ON u1.id = c.renter_id
		 LEFT JOIN users u2 ON u2.id = c.landlord_id
		 ORDER BY c.last_message_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var convos []models.Conversation
	for rows.Next() {
		var c models.Conversation
		var renterName, landlordName string
		if err := rows.Scan(&c.ID, &c.PropertyID, &c.RenterID, &c.LandlordID,
			&c.LastMessageAt, &c.CreatedAt, &c.PropertyTitle,
			&renterName, &landlordName, &c.LastMessage, &c.UnreadCount); err != nil {
			return nil, err
		}
		c.OtherName = renterName + " ↔ " + landlordName
		convos = append(convos, c)
	}
	return convos, nil
}

func (r *AdminRepository) GetConversationMessages(ctx context.Context, conversationID string) ([]models.Message, error) {
	rows, err := r.db.Query(ctx,
		`SELECT m.id, m.conversation_id, m.sender_id, m.text, m.is_read, m.created_at,
		        COALESCE(u.full_name, u.phone, '')
		 FROM messages m
		 LEFT JOIN users u ON u.id = m.sender_id
		 WHERE m.conversation_id = $1
		 ORDER BY m.created_at ASC`, conversationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []models.Message
	for rows.Next() {
		var m models.Message
		var senderName string
		if err := rows.Scan(&m.ID, &m.ConversationID, &m.SenderID, &m.Text, &m.IsRead, &m.CreatedAt, &senderName); err != nil {
			return nil, err
		}
		m.SenderName = senderName
		messages = append(messages, m)
	}
	return messages, nil
}
