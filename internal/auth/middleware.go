package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/MuhammadYahyo/RenTGO/internal/auth/service"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
)

// JWTMiddleware validates the Bearer token and sets user_id, user_role in context.
func JWTMiddleware(jwtSvc *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" || !strings.HasPrefix(header, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing or invalid authorization header"})
			return
		}

		tokenStr := strings.TrimPrefix(header, "Bearer ")
		claims, err := jwtSvc.ValidateToken(tokenStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("user_role", string(claims.Role))
		c.Set("user_phone", claims.Phone)
		c.Next()
	}
}

// RoleMiddleware restricts access to specific roles.
func RoleMiddleware(roles ...models.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := models.Role(c.GetString("user_role"))
		for _, r := range roles {
			if userRole == r {
				c.Next()
				return
			}
		}
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "insufficient permissions"})
	}
}

// OptionalJWTMiddleware extracts user_id from token if present, but doesn't block.
func OptionalJWTMiddleware(jwtSvc *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header != "" && strings.HasPrefix(header, "Bearer ") {
			tokenStr := strings.TrimPrefix(header, "Bearer ")
			if claims, err := jwtSvc.ValidateToken(tokenStr); err == nil {
				c.Set("user_id", claims.UserID)
				c.Set("user_role", string(claims.Role))
				c.Set("user_phone", claims.Phone)
			}
		}
		c.Next()
	}
}

// LanguageMiddleware detects the Accept-Language header and sets it in context.
func LanguageMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		lang := c.GetHeader("Accept-Language")
		switch lang {
		case "ru", "en", "uz":
			c.Set("language", lang)
		default:
			c.Set("language", "uz")
		}
		c.Next()
	}
}
