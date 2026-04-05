package main

import (
	"context"
	"log"
	"os"

	"github.com/gin-gonic/gin"

	adminHandlerPkg "github.com/MuhammadYahyo/RenTGO/internal/admin/handler"
	adminRepo "github.com/MuhammadYahyo/RenTGO/internal/admin/repository"
	"github.com/MuhammadYahyo/RenTGO/internal/auth"
	authHandler "github.com/MuhammadYahyo/RenTGO/internal/auth/handler"
	authRepo "github.com/MuhammadYahyo/RenTGO/internal/auth/repository"
	authService "github.com/MuhammadYahyo/RenTGO/internal/auth/service"
	chatHandlerPkg "github.com/MuhammadYahyo/RenTGO/internal/chat/handler"
	chatRepo "github.com/MuhammadYahyo/RenTGO/internal/chat/repository"
	chatService "github.com/MuhammadYahyo/RenTGO/internal/chat/service"
	"github.com/MuhammadYahyo/RenTGO/internal/models"
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

	// Auto-migrate new columns
	migrateSQL := `
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS floor INTEGER;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS total_floors INTEGER;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS furnished BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS renovation VARCHAR(20);
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS balcony BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS parking BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS wifi BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS washer BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS conditioner BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS fridge BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS tv BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_brand VARCHAR(100);
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_year INTEGER;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_transmission VARCHAR(20);
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_fuel VARCHAR(20);
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_mileage INTEGER;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_color VARCHAR(50);
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_ac BOOLEAN DEFAULT FALSE;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS car_seats INTEGER;
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending';
		ALTER TABLE properties ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'UZS';
		CREATE TABLE IF NOT EXISTS directories (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			type VARCHAR(50) NOT NULL,
			value VARCHAR(255) NOT NULL,
			value_uz VARCHAR(255),
			value_ru VARCHAR(255),
			value_en VARCHAR(255),
			parent_value VARCHAR(255),
			sort_order INTEGER DEFAULT 0,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			UNIQUE(type, value)
		);
		ALTER TABLE directories ADD COLUMN IF NOT EXISTS value_uz VARCHAR(255);
		ALTER TABLE directories ADD COLUMN IF NOT EXISTS value_ru VARCHAR(255);
		ALTER TABLE directories ADD COLUMN IF NOT EXISTS value_en VARCHAR(255);
		-- Seed car brands
		INSERT INTO directories (type, value, sort_order) VALUES
			('car_brand','Chevrolet',1),('car_brand','Toyota',2),('car_brand','Hyundai',3),('car_brand','Kia',4),
			('car_brand','Daewoo',5),('car_brand','BMW',6),('car_brand','Mercedes-Benz',7),('car_brand','Audi',8),
			('car_brand','Volkswagen',9),('car_brand','Honda',10),('car_brand','Nissan',11),('car_brand','Mazda',12),
			('car_brand','Ford',13),('car_brand','Lexus',14),('car_brand','Mitsubishi',15),('car_brand','Subaru',16),
			('car_brand','Peugeot',17),('car_brand','Renault',18),('car_brand','Skoda',19),('car_brand','Opel',20),
			('car_brand','Lada (VAZ)',21),('car_brand','BYD',22),('car_brand','Chery',23),('car_brand','Haval',24),
			('car_brand','Geely',25),('car_brand','Jetour',26),('car_brand','Changan',27)
		ON CONFLICT (type,value) DO NOTHING;
		-- Seed car colors
		INSERT INTO directories (type, value, sort_order) VALUES
			('car_color','white',1),('car_color','black',2),('car_color','silver',3),('car_color','grey',4),
			('car_color','red',5),('car_color','blue',6),('car_color','green',7),('car_color','yellow',8),
			('car_color','brown',9),('car_color','beige',10),('car_color','orange',11),('car_color','purple',12)
		ON CONFLICT (type,value) DO NOTHING;
		-- Seed regions and districts
		INSERT INTO directories (type, value, sort_order) VALUES
			('region','Toshkent shahri',1),('region','Toshkent viloyati',2),('region','Samarqand',3),
			('region','Buxoro',4),('region','Farg''ona',5),('region','Andijon',6),('region','Namangan',7),
			('region','Qashqadaryo',8),('region','Surxondaryo',9),('region','Navoiy',10),('region','Xorazm',11),
			('region','Jizzax',12),('region','Sirdaryo',13),('region','Qoraqalpog''iston',14)
		ON CONFLICT (type,value) DO NOTHING;
		INSERT INTO directories (type, value, parent_value, sort_order) VALUES
			('district','Chilonzor','Toshkent shahri',1),('district','Yunusobod','Toshkent shahri',2),
			('district','Mirzo Ulugbek','Toshkent shahri',3),('district','Sergeli','Toshkent shahri',4),
			('district','Yakkasaroy','Toshkent shahri',5),('district','Shayxontohur','Toshkent shahri',6),
			('district','Olmazor','Toshkent shahri',7),('district','Mirobod','Toshkent shahri',8),
			('district','Uchtepa','Toshkent shahri',9),('district','Bektemir','Toshkent shahri',10),
			('district','Yashnobod','Toshkent shahri',11),
			('district','Chirchiq','Toshkent viloyati',1),('district','Olmaliq','Toshkent viloyati',2),
			('district','Angren','Toshkent viloyati',3),('district','Nurafshon','Toshkent viloyati',4),
			('district','Samarqand shahri','Samarqand',1),('district','Urgut','Samarqand',2),
			('district','Buxoro shahri','Buxoro',1),('district','Kogon','Buxoro',2),
			('district','Farg''ona shahri','Farg''ona',1),('district','Marg''ilon','Farg''ona',2),('district','Qo''qon','Farg''ona',3),
			('district','Andijon shahri','Andijon',1),('district','Asaka','Andijon',2),
			('district','Namangan shahri','Namangan',1),('district','Chortoq','Namangan',2),
			('district','Qarshi','Qashqadaryo',1),('district','Shahrisabz','Qashqadaryo',2),
			('district','Termiz','Surxondaryo',1),('district','Denov','Surxondaryo',2),
			('district','Navoiy shahri','Navoiy',1),('district','Zarafshon','Navoiy',2),
			('district','Urganch','Xorazm',1),('district','Xiva','Xorazm',2),
			('district','Jizzax shahri','Jizzax',1),('district','Guliston','Sirdaryo',1),
			('district','Nukus','Qoraqalpog''iston',1),('district','Mo''ynoq','Qoraqalpog''iston',2)
		ON CONFLICT (type,value) DO NOTHING;
		ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
		UPDATE users SET role='user' WHERE role IN ('renter', 'landlord');
		ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'admin'));
		ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user';
		ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
	`
	if _, err := db.Exec(context.Background(), migrateSQL); err != nil {
		log.Printf("[WARN] auto-migrate: %v", err)
	} else {
		log.Println("Auto-migrate: property features columns OK")
	}

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
	smsSvc := authService.NewSMSService(authService.EskizConfig{
		Email:    cfg.Eskiz.Email,
		Password: cfg.Eskiz.Password,
	})
	tgSvc := authService.NewTelegramService(cfg.Telegram.BotToken, rdb)

	// Firebase Phone Auth
	var fbVerifier *authService.FirebaseVerifier
	firebaseProjectID := os.Getenv("FIREBASE_PROJECT_ID")
	if firebaseProjectID != "" {
		fbVerifier = authService.NewFirebaseVerifier(firebaseProjectID)
		log.Printf("Firebase Phone Auth enabled (project: %s)", firebaseProjectID)
	} else {
		log.Println("[WARN] FIREBASE_PROJECT_ID not set, Firebase auth disabled")
	}

	authSvc := authService.NewAuthService(userRepo, otpSvc, jwtSvc, smsSvc, tgSvc, fbVerifier)

	// Start Telegram bot polling in background (fallback)
	go tgSvc.StartPolling(context.Background())
	authH := authHandler.NewAuthHandler(authSvc)

	// Property wiring
	propertyRepo := propRepo.NewPropertyRepository(db)
	propertySvc := propService.NewPropertyService(propertyRepo)
	propertyH := propHandler.NewPropertyHandler(propertySvc, storageSvc)

	// Chat wiring
	chatRepository := chatRepo.NewChatRepository(db)
	chatSvc := chatService.NewChatService(chatRepository)
	chatH := chatHandlerPkg.NewChatHandler(chatSvc)

	// Admin wiring
	adminRepository := adminRepo.NewAdminRepository(db)
	adminH := adminHandlerPkg.NewAdminHandler(adminRepository)

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
		authGroup.POST("/firebase-login", authH.FirebaseLogin)
	}

	// Auth routes (protected)
	authProtected := r.Group("/api/v1/auth")
	authProtected.Use(auth.JWTMiddleware(jwtSvc))
	{
		authProtected.GET("/profile", authH.GetProfile)
		authProtected.PUT("/profile", authH.UpdateProfile)
		authProtected.POST("/fcm-token", authH.RegisterFcmToken)
	}

	// Image proxy (public)
	r.GET("/images/*path", propertyH.ServeImage)

	// Directories (public read)
	r.GET("/api/v1/directories", adminH.ListDirectories)

	// Property routes — static routes (/my, /upload-url) MUST be separate from param routes (/:id)
	propGroup := r.Group("/api/v1/properties")
	{
		propGroup.GET("", auth.OptionalJWTMiddleware(jwtSvc), propertyH.ListProperties)
		propGroup.POST("", auth.JWTMiddleware(jwtSvc), propertyH.CreateProperty)
	}
	// Static sub-paths must be registered before parameterized ones
	r.GET("/api/v1/properties/my", auth.JWTMiddleware(jwtSvc), propertyH.MyProperties)
	r.GET("/api/v1/properties/upload-url", auth.JWTMiddleware(jwtSvc), propertyH.GetUploadURL)
	propGroup2 := r.Group("/api/v1/properties")
	{
		propGroup2.GET("/:id", propertyH.GetProperty)
		propGroup2.PUT("/:id", auth.JWTMiddleware(jwtSvc), propertyH.UpdateProperty)
		propGroup2.DELETE("/:id", auth.JWTMiddleware(jwtSvc), propertyH.DeleteProperty)
		propGroup2.POST("/:id/images", auth.JWTMiddleware(jwtSvc), propertyH.UploadImage)
		propGroup2.DELETE("/:id/images/:imageId", auth.JWTMiddleware(jwtSvc), propertyH.DeleteImage)
	}

	// Chat routes (protected)
	chatProtected := r.Group("/api/v1/chat")
	chatProtected.Use(auth.JWTMiddleware(jwtSvc))
	{
		chatProtected.POST("/conversations", chatH.StartConversation)
		chatProtected.GET("/conversations", chatH.ListConversations)
		chatProtected.POST("/conversations/:id/messages", chatH.SendMessage)
		chatProtected.GET("/conversations/:id/messages", chatH.GetMessages)
	}

	// Admin routes (protected, admin only)
	adminGroup := r.Group("/api/v1/admin")
	adminGroup.Use(auth.JWTMiddleware(jwtSvc), auth.RoleMiddleware(models.RoleAdmin))
	{
		adminGroup.GET("/dashboard", adminH.GetDashboard)
		adminGroup.GET("/users", adminH.ListUsers)
		adminGroup.PUT("/users/:id/role", adminH.UpdateUserRole)
		adminGroup.DELETE("/users/:id", adminH.DeleteUser)
		adminGroup.GET("/properties", adminH.ListProperties)
		adminGroup.PUT("/properties/:id/active", adminH.TogglePropertyActive)
		adminGroup.DELETE("/properties/:id", adminH.DeleteProperty)
		adminGroup.PUT("/properties/:id/status", adminH.UpdatePropertyStatus)
		adminGroup.GET("/directories", adminH.ListDirectories)
		adminGroup.POST("/directories", adminH.CreateDirectory)
		adminGroup.PUT("/directories/:id", adminH.UpdateDirectory)
		adminGroup.DELETE("/directories/:id", adminH.DeleteDirectory)
		adminGroup.GET("/conversations", adminH.ListAllConversations)
		adminGroup.GET("/conversations/:id/messages", adminH.GetConversationMessages)
	}

	log.Printf("RenTGO API starting on :%s", cfg.App.Port)
	if err := r.Run(":" + cfg.App.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
