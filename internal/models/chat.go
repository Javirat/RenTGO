package models

import "time"

type Conversation struct {
	ID            string    `json:"id"`
	PropertyID    string    `json:"property_id"`
	RenterID      string    `json:"renter_id"`
	LandlordID    string    `json:"landlord_id"`
	LastMessageAt time.Time `json:"last_message_at"`
	CreatedAt     time.Time `json:"created_at"`

	// Joined fields
	PropertyTitle string `json:"property_title,omitempty"`
	OtherName     string `json:"other_name,omitempty"`
	OtherPhone    string `json:"other_phone,omitempty"`
	LastMessage   string `json:"last_message,omitempty"`
	UnreadCount   int    `json:"unread_count"`
}

type Message struct {
	ID             string    `json:"id"`
	ConversationID string    `json:"conversation_id"`
	SenderID       string    `json:"sender_id"`
	Text           string    `json:"text"`
	IsRead         bool      `json:"is_read"`
	CreatedAt      time.Time `json:"created_at"`
}
