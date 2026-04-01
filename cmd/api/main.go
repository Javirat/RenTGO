package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"github.com/MuhammadYahyo/RenTGO/internal/auth"
	authHandler "github.com/MuhammadYahyo/RenTGO/internal/auth/handler"
	authRepo "github.com/MuhammadYahyo/RenTGO/internal/auth/repository"
	authService "github.com/MuhammadYahyo/RenTGO/internal/auth/service"
	propHandler "github.com/MuhammadYahyo/RenTGO/internal/property/handler"
	propRepo "github.com/MuhammadYahyo/RenTGO/internal/property/repository"
	propService "github.com/MuhammadYahyo/RenTGO/internal/property/service"
	"github.com/MuhammadYahyo/RenTGO/internal/storage"
	"github.com/MuhammadYahyo/RenTGO/pkg/config"
	"github.com/MuhammadYahyo/RenTGO/pkg/database"
	redispkg "github.com/MuhammadYahyo/RenTGO/pkg/redis"
)

func main() {
	cfg := config.Load()

	// Database
	db, err := database.NewPostgres(cfg.Postgres)
	if err != nil {
		log.Fatalf("postgres: %v", err)
	}
	defer db.Close()

	// Redis
	rdb, err := redispkg.NewRedis(cfg.Redis)
	if err != nil {
		log.Fatalf("redis: %v", err)
	}
	defer rdb.Close()

	// MinIO
	storageSvc, err := storage.NewStorageService(cfg.MinIO)
	if err != nil {
		log.Printf("[WARN] minio: %v (image features will be unavailable)", err)
	}

	// Auth wiring
	userRepo := authRepo.NewUserRepository(db)
	otpSvc := authService.NewOTPService(rdb, cfg.OTP)
	jwtSvc := authService.NewJWTService(cfg.JWT)
	authSvc := authService.NewAuthService(userRepo, otpSvc, jwtSvc)
	authH := authHandler.NewAuthHandler(authSvc)

	// Property wiring
	propertyRepo := propRepo.NewPropertyRepository(db)
	propertySvc := propService.NewPropertyService(propertyRepo)
	propertyH := propHandler.NewPropertyHandler(propertySvc, storageSvc)

	// Router
	r := gin.Default()
	r.Use(auth.LanguageMiddleware())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Auth routes (public)
	authGroup := r.Group("/api/v1/auth")
	{
		authGroup.POST("/send-otp", authH.SendOTP)
		authGroup.POST("/verify-otp", authH.VerifyOTP)
	}

	// Auth routes (protected)
	authProtected := r.Group("/api/v1/auth")
	authProtected.Use(auth.JWTMiddleware(jwtSvc))
	{
		authProtected.GET("/profile", authH.GetProfile)
		authProtected.PUT("/profile", authH.UpdateProfile)
	}

	// Property routes (public)
	propPublic := r.Group("/api/v1/properties")
	{
		propPublic.GET("", propertyH.ListProperties)
		propPublic.GET("/:id", propertyH.GetProperty)
	}

	// Property routes (protected)
	propProtected := r.Group("/api/v1/properties")
	propProtected.Use(auth.JWTMiddleware(jwtSvc))
	{
		propProtected.POST("", propertyH.CreateProperty)
		propProtected.GET("/my", propertyH.MyProperties)
		propProtected.PUT("/:id", propertyH.UpdateProperty)
		propProtected.DELETE("/:id", propertyH.DeleteProperty)
		propProtected.POST("/:id/images", propertyH.UploadImage)
		propProtected.DELETE("/:id/images/:imageId", propertyH.DeleteImage)
		propProtected.GET("/upload-url", propertyH.GetUploadURL)
	}

	log.Printf("RenTGO API starting on :%s", cfg.App.Port)
	if err := r.Run(":" + cfg.App.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
