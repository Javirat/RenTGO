package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/MuhammadYahyo/RenTGO/internal/chat/service"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type ChatHandler struct {
	chatSvc *service.ChatService
}

func NewChatHandler(cs *service.ChatService) *ChatHandler {
	return &ChatHandler{chatSvc: cs}
}

type StartConversationRequest struct {
	PropertyID string `json:"property_id" binding:"required"`
	LandlordID string `json:"landlord_id" binding:"required"`
}

type SendMessageRequest struct {
	Text string `json:"text" binding:"required"`
}

// StartConversation creates or returns existing conversation
// POST /chat/conversations
func (h *ChatHandler) StartConversation(c *gin.Context) {
	userID := c.GetString("user_id")

	var req StartConversationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	conv, err := h.chatSvc.StartConversation(c.Request.Context(), req.PropertyID, userID, req.LandlordID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, conv)
}

// ListConversations returns all conversations for the current user
// GET /chat/conversations
func (h *ChatHandler) ListConversations(c *gin.Context) {
	userID := c.GetString("user_id")

	convos, err := h.chatSvc.ListConversations(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list conversations"})
		return
	}

	if convos == nil {
		convos = []models.Conversation{}
	}

	c.JSON(http.StatusOK, convos)
}

// SendMessage sends a message in a conversation
// POST /chat/conversations/:id/messages
func (h *ChatHandler) SendMessage(c *gin.Context) {
	userID := c.GetString("user_id")
	convID := c.Param("id")

	var req SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg, err := h.chatSvc.SendMessage(c.Request.Context(), convID, userID, req.Text)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, msg)
}

// GetMessages returns messages for a conversation
// GET /chat/conversations/:id/messages
func (h *ChatHandler) GetMessages(c *gin.Context) {
	userID := c.GetString("user_id")
	convID := c.Param("id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "30"))

	messages, err := h.chatSvc.GetMessages(c.Request.Context(), convID, userID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	if messages == nil {
		messages = []models.Message{}
	}

	c.JSON(http.StatusOK, messages)
}
