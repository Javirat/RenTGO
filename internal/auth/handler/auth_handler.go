package handler

import (
	"net/http"
	"os"
	"regexp"

	"github.com/gin-gonic/gin"

	"github.com/MuhammadYahyo/RenTGO/internal/auth/service"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

type FirebaseLoginRequest struct {
	FirebaseToken string `json:"firebase_token" binding:"required"`
	Language      string `json:"language"`
}

var phoneRegex = regexp.MustCompile(`^\+998\d{9}$`)

type AuthHandler struct {
	authSvc *service.AuthService
	devMode bool
}

func NewAuthHandler(authSvc *service.AuthService) *AuthHandler {
	return &AuthHandler{
		authSvc: authSvc,
		devMode: os.Getenv("APP_ENV") != "production",
	}
}

type SendOTPRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type VerifyOTPRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Code     string `json:"code" binding:"required"`
	Role     string `json:"role"`
	Language string `json:"language"`
}

type UpdateProfileRequest struct {
	FullName  string `json:"full_name"`
	AvatarURL string `json:"avatar_url"`
	Language  string `json:"language"`
	Role      string `json:"role"`
}

// SendOTP godoc
// @Summary Send OTP to phone number
// @Tags auth
// @Accept json
// @Produce json
// @Param body body SendOTPRequest true "Phone number"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Router /auth/send-otp [post]
func (h *AuthHandler) SendOTP(c *gin.Context) {
	var req SendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "phone is required"})
		return
	}

	if !phoneRegex.MatchString(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid phone format, use +998XXXXXXXXX"})
		return
	}

	code, err := h.authSvc.SendOTP(c.Request.Context(), req.Phone)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resp := gin.H{"message": "OTP sent"}
	if h.devMode {
		resp["code"] = code // only in development mode
	}
	c.JSON(http.StatusOK, resp)
}

// VerifyOTP godoc
// @Summary Verify OTP and get JWT
// @Tags auth
// @Accept json
// @Produce json
// @Param body body VerifyOTPRequest true "OTP verification"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Router /auth/verify-otp [post]
func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var req VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "phone and code are required"})
		return
	}

	role := models.RoleUser
	lang := models.LangUzbek
	switch req.Language {
	case "ru":
		lang = models.LangRussian
	case "en":
		lang = models.LangEnglish
	}

	token, user, isNew, err := h.authSvc.VerifyOTP(c.Request.Context(), req.Phone, req.Code, role, lang)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":  token,
		"user":   user,
		"is_new": isNew,
	})
}

// FirebaseLogin verifies a Firebase ID token and creates/logs in the user
func (h *AuthHandler) FirebaseLogin(c *gin.Context) {
	var req FirebaseLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "firebase_token is required"})
		return
	}

	lang := models.LangUzbek
	switch req.Language {
	case "ru":
		lang = models.LangRussian
	case "en":
		lang = models.LangEnglish
	}

	token, user, isNew, err := h.authSvc.FirebaseLogin(c.Request.Context(), req.FirebaseToken, lang)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":  token,
		"user":   user,
		"is_new": isNew,
	})
}

// RegisterFcmToken saves the user's FCM push notification token
func (h *AuthHandler) RegisterFcmToken(c *gin.Context) {
	userID := c.GetString("user_id")
	var req struct {
		FcmToken string `json:"fcm_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "fcm_token is required"})
		return
	}
	if err := h.authSvc.SaveFcmToken(c.Request.Context(), userID, req.FcmToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save token"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "token saved"})
}

// GetProfile godoc
// @Summary Get current user profile
// @Tags auth
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.User
// @Router /auth/profile [get]
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID := c.GetString("user_id")
	user, err := h.authSvc.GetProfile(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

// UpdateProfile godoc
// @Summary Update user profile
// @Tags auth
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body UpdateProfileRequest true "Profile data"
// @Success 200 {object} map[string]string
// @Router /auth/profile [put]
func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	userID := c.GetString("user_id")
	user, err := h.authSvc.GetProfile(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	if req.FullName != "" {
		user.FullName = req.FullName
	}
	if req.AvatarURL != "" {
		user.AvatarURL = req.AvatarURL
	}
	if req.Language != "" {
		user.Language = models.Language(req.Language)
	}
	if req.Role != "" {
		// Only admins can change roles, and only to valid values
		requestingUserID := c.GetString("user_id")
		requestingUser, _ := h.authSvc.GetProfile(c.Request.Context(), requestingUserID)
		newRole := models.Role(req.Role)
		if requestingUser != nil && requestingUser.Role == models.RoleAdmin && (newRole == models.RoleUser || newRole == models.RoleAdmin) {
			user.Role = newRole
		}
	}

	if err := h.authSvc.UpdateProfile(c.Request.Context(), user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update profile"})
		return
	}

	// Return new token so role change takes effect immediately
	token, err := h.authSvc.GenerateToken(user)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"message": "profile updated"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "profile updated", "token": token})
}
