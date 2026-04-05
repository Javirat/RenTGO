package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/MuhammadYahyo/RenTGO/internal/admin/repository"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type AdminHandler struct {
	repo *repository.AdminRepository
}

func NewAdminHandler(repo *repository.AdminRepository) *AdminHandler {
	return &AdminHandler{repo: repo}
}

// ── Dashboard ──

func (h *AdminHandler) GetDashboard(c *gin.Context) {
	stats, err := h.repo.GetDashboardStats(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// ── Users ──

func (h *AdminHandler) ListUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	filter := repository.UserListFilter{
		Search:   c.Query("search"),
		Role:     c.Query("role"),
		Page:     page,
		PageSize: pageSize,
	}

	users, total, err := h.repo.ListUsers(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  users,
		"total": total,
		"page":  page,
	})
}

type UpdateRoleRequest struct {
	Role string `json:"role" binding:"required"`
}

func (h *AdminHandler) UpdateUserRole(c *gin.Context) {
	userID := c.Param("id")
	var req UpdateRoleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "role is required"})
		return
	}

	role := models.Role(req.Role)
	if role != models.RoleUser && role != models.RoleAdmin {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid role"})
		return
	}

	if err := h.repo.UpdateUserRole(c.Request.Context(), userID, role); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update role"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "role updated"})
}

func (h *AdminHandler) DeleteUser(c *gin.Context) {
	userID := c.Param("id")

	// Don't allow deleting yourself
	currentUserID := c.GetString("user_id")
	if userID == currentUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot delete yourself"})
		return
	}

	if err := h.repo.DeleteUser(c.Request.Context(), userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete user"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "user deleted"})
}

// ── Properties ──

func (h *AdminHandler) ListProperties(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	filter := repository.PropertyListFilter{
		Search:   c.Query("search"),
		Category: c.Query("category"),
		Status:   c.Query("status"),
		Page:     page,
		PageSize: pageSize,
	}

	if active := c.Query("is_active"); active != "" {
		val := active == "true"
		filter.IsActive = &val
	}

	properties, total, err := h.repo.ListAllProperties(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list properties"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  properties,
		"total": total,
		"page":  page,
	})
}

type ToggleActiveRequest struct {
	IsActive bool `json:"is_active"`
}

func (h *AdminHandler) TogglePropertyActive(c *gin.Context) {
	propID := c.Param("id")
	var req ToggleActiveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "is_active is required"})
		return
	}

	if err := h.repo.TogglePropertyActive(c.Request.Context(), propID, req.IsActive); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update property"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "property updated"})
}

func (h *AdminHandler) DeleteProperty(c *gin.Context) {
	propID := c.Param("id")
	if err := h.repo.DeleteProperty(c.Request.Context(), propID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete property"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "property deleted"})
}

func (h *AdminHandler) UpdatePropertyStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Status != "approved" && req.Status != "rejected" && req.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid status"})
		return
	}
	if err := h.repo.UpdatePropertyStatus(c.Request.Context(), id, req.Status); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update status"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "status updated"})
}

// ── Directories ──

func (h *AdminHandler) ListDirectories(c *gin.Context) {
	dirType := c.Query("type")
	if dirType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "type is required"})
		return
	}
	dirs, err := h.repo.ListDirectories(c.Request.Context(), dirType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list directories"})
		return
	}
	if dirs == nil {
		dirs = []models.Directory{}
	}
	c.JSON(http.StatusOK, dirs)
}

func (h *AdminHandler) CreateDirectory(c *gin.Context) {
	var req struct {
		Type        string `json:"type" binding:"required"`
		Value       string `json:"value" binding:"required"`
		ValueUz     string `json:"value_uz"`
		ValueRu     string `json:"value_ru"`
		ValueEn     string `json:"value_en"`
		ParentValue string `json:"parent_value"`
		SortOrder   int    `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	d := &models.Directory{Type: req.Type, Value: req.Value, ValueUz: req.ValueUz, ValueRu: req.ValueRu,
		ValueEn: req.ValueEn, ParentValue: req.ParentValue, SortOrder: req.SortOrder}
	if err := h.repo.CreateDirectory(c.Request.Context(), d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create directory entry"})
		return
	}
	c.JSON(http.StatusCreated, d)
}

func (h *AdminHandler) UpdateDirectory(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Value       string `json:"value"`
		ValueUz     string `json:"value_uz"`
		ValueRu     string `json:"value_ru"`
		ValueEn     string `json:"value_en"`
		ParentValue string `json:"parent_value"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	d := &models.Directory{ID: id, Value: req.Value, ValueUz: req.ValueUz, ValueRu: req.ValueRu,
		ValueEn: req.ValueEn, ParentValue: req.ParentValue}
	if err := h.repo.UpdateDirectory(c.Request.Context(), d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "updated"})
}

func (h *AdminHandler) DeleteDirectory(c *gin.Context) {
	id := c.Param("id")
	if err := h.repo.DeleteDirectory(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete directory entry"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}

// ── Conversations ──

func (h *AdminHandler) ListAllConversations(c *gin.Context) {
	convos, err := h.repo.ListAllConversations(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list conversations"})
		return
	}
	c.JSON(http.StatusOK, convos)
}

func (h *AdminHandler) GetConversationMessages(c *gin.Context) {
	id := c.Param("id")
	messages, err := h.repo.GetConversationMessages(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get messages"})
		return
	}
	c.JSON(http.StatusOK, messages)
}
