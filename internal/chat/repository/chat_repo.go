package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type ChatRepository struct {
	db *pgxpool.Pool
}

func NewChatRepository(db *pgxpool.Pool) *ChatRepository {
	return &ChatRepository{db: db}
}

func (r *ChatRepository) GetOrCreateConversation(ctx context.Context, propertyID, renterID, landlordID string) (*models.Conversation, error) {
	var c models.Conversation
	err := r.db.QueryRow(ctx,
		`INSERT INTO conversations (property_id, renter_id, landlord_id)
		 VALUES ($1, $2, $3)
		 ON CONFLICT (property_id, renter_id) DO UPDATE SET property_id = conversations.property_id
		 RETURNING id, property_id, renter_id, landlord_id, last_message_at, created_at`,
		propertyID, renterID, landlordID,
	).Scan(&c.ID, &c.PropertyID, &c.RenterID, &c.LandlordID, &c.LastMessageAt, &c.CreatedAt)
	return &c, err
}

func (r *ChatRepository) GetConversationByID(ctx context.Context, id string) (*models.Conversation, error) {
	var c models.Conversation
	err := r.db.QueryRow(ctx,
		`SELECT id, property_id, renter_id, landlord_id, last_message_at, created_at
		 FROM conversations WHERE id = $1`, id,
	).Scan(&c.ID, &c.PropertyID, &c.RenterID, &c.LandlordID, &c.LastMessageAt, &c.CreatedAt)
	return &c, err
}

func (r *ChatRepository) ListConversations(ctx context.Context, userID string) ([]models.Conversation, error) {
	rows, err := r.db.Query(ctx,
		`SELECT c.id, c.property_id, c.renter_id, c.landlord_id, c.last_message_at, c.created_at,
		        COALESCE(p.title, ''),
		        CASE WHEN c.renter_id = $1 THEN COALESCE(u2.full_name, '') ELSE COALESCE(u1.full_name, '') END,
		        CASE WHEN c.renter_id = $1 THEN COALESCE(u2.phone, '') ELSE COALESCE(u1.phone, '') END,
		        COALESCE((SELECT text FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1), ''),
		        (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND sender_id != $1 AND is_read = FALSE)
		 FROM conversations c
		 LEFT JOIN properties p ON p.id = c.property_id
		 LEFT JOIN users u1 ON u1.id = c.renter_id
		 LEFT JOIN users u2 ON u2.id = c.landlord_id
		 WHERE c.renter_id = $1 OR c.landlord_id = $1
		 ORDER BY c.last_message_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var convos []models.Conversation
	for rows.Next() {
		var c models.Conversation
		if err := rows.Scan(&c.ID, &c.PropertyID, &c.RenterID, &c.LandlordID,
			&c.LastMessageAt, &c.CreatedAt, &c.PropertyTitle,
			&c.OtherName, &c.OtherPhone, &c.LastMessage, &c.UnreadCount); err != nil {
			return nil, err
		}
		convos = append(convos, c)
	}
	return convos, nil
}

func (r *ChatRepository) SendMessage(ctx context.Context, msg *models.Message) error {
	err := r.db.QueryRow(ctx,
		`INSERT INTO messages (conversation_id, sender_id, text)
		 VALUES ($1, $2, $3) RETURNING id, created_at`,
		msg.ConversationID, msg.SenderID, msg.Text,
	).Scan(&msg.ID, &msg.CreatedAt)
	if err != nil {
		return err
	}
	_, err = r.db.Exec(ctx,
		`UPDATE conversations SET last_message_at = NOW() WHERE id = $1`, msg.ConversationID)
	return err
}

func (r *ChatRepository) GetMessages(ctx context.Context, conversationID string, page, pageSize int) ([]models.Message, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 30
	}
	offset := (page - 1) * pageSize

	rows, err := r.db.Query(ctx,
		`SELECT id, conversation_id, sender_id, text, is_read, created_at
		 FROM messages WHERE conversation_id = $1
		 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
		conversationID, pageSize, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []models.Message
	for rows.Next() {
		var m models.Message
		if err := rows.Scan(&m.ID, &m.ConversationID, &m.SenderID, &m.Text, &m.IsRead, &m.CreatedAt); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, nil
}

func (r *ChatRepository) MarkAsRead(ctx context.Context, conversationID, userID string) error {
	_, err := r.db.Exec(ctx,
		`UPDATE messages SET is_read = TRUE
		 WHERE conversation_id = $1 AND sender_id != $2 AND is_read = FALSE`,
		conversationID, userID)
	return err
}
