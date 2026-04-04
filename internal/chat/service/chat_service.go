package service

import (
	"context"
	"fmt"

	"github.com/MuhammadYahyo/RenTGO/internal/chat/repository"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type ChatService struct {
	repo *repository.ChatRepository
}

func NewChatService(repo *repository.ChatRepository) *ChatService {
	return &ChatService{repo: repo}
}

func (s *ChatService) StartConversation(ctx context.Context, propertyID, renterID, landlordID string) (*models.Conversation, error) {
	if renterID == landlordID {
		return nil, fmt.Errorf("cannot message yourself")
	}
	return s.repo.GetOrCreateConversation(ctx, propertyID, renterID, landlordID)
}

func (s *ChatService) ListConversations(ctx context.Context, userID string) ([]models.Conversation, error) {
	return s.repo.ListConversations(ctx, userID)
}

func (s *ChatService) SendMessage(ctx context.Context, conversationID, senderID, text string) (*models.Message, error) {
	conv, err := s.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, fmt.Errorf("conversation not found")
	}
	if conv.RenterID != senderID && conv.LandlordID != senderID {
		return nil, fmt.Errorf("not authorized")
	}

	msg := &models.Message{
		ConversationID: conversationID,
		SenderID:       senderID,
		Text:           text,
	}
	if err := s.repo.SendMessage(ctx, msg); err != nil {
		return nil, err
	}
	return msg, nil
}

func (s *ChatService) GetMessages(ctx context.Context, conversationID, userID string, page, pageSize int) ([]models.Message, error) {
	conv, err := s.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, fmt.Errorf("conversation not found")
	}
	if conv.RenterID != userID && conv.LandlordID != userID {
		return nil, fmt.Errorf("not authorized")
	}

	_ = s.repo.MarkAsRead(ctx, conversationID, userID)
	return s.repo.GetMessages(ctx, conversationID, page, pageSize)
}
