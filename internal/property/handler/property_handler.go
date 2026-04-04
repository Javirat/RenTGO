package handler

import (
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/MuhammadYahyo/RenTGO/internal/models"
	"github.com/MuhammadYahyo/RenTGO/internal/property/service"
	storagesvc "github.com/MuhammadYahyo/RenTGO/internal/storage"
)

type PropertyHandler struct {
	propertySvc *service.PropertyService
	storageSvc  *storagesvc.StorageService
}

func NewPropertyHandler(ps *service.PropertyService, ss *storagesvc.StorageService) *PropertyHandler {
	return &PropertyHandler{propertySvc: ps, storageSvc: ss}
}

type CreatePropertyRequest struct {
	Title       string  `json:"title" binding:"required"`
	Description string  `json:"description"`
	Price       float64 `json:"price" binding:"required"`
	Rooms       int     `json:"rooms"`
	Capacity    int     `json:"capacity"`
	Region      string  `json:"region"`
	Address     string  `json:"address"`
	Lat         float64 `json:"lat"`
	Lng         float64 `json:"lng"`
	Category    string  `json:"category" binding:"required"`
	HasCCTV     bool    `json:"has_cctv"`
}

type UpdatePropertyRequest struct {
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	Rooms       int     `json:"rooms"`
	Capacity    int     `json:"capacity"`
	Region      string  `json:"region"`
	Address     string  `json:"address"`
	Lat         float64 `json:"lat"`
	Lng         float64 `json:"lng"`
	Category    string  `json:"category"`
	HasCCTV     bool    `json:"has_cctv"`
	IsActive    bool    `json:"is_active"`
}

// CreateProperty godoc
// @Summary Create a new property listing
// @Tags properties
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body CreatePropertyRequest true "Property data"
// @Success 201 {object} models.Property
// @Router /properties [post]
func (h *PropertyHandler) CreateProperty(c *gin.Context) {
	ownerID := c.GetString("user_id")
	role := c.GetString("user_role")
	if role != "landlord" {
		c.JSON(http.StatusForbidden, gin.H{"error": "only landlords can create listings"})
		return
	}

	var req CreatePropertyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	p := &models.Property{
		OwnerID:     ownerID,
		Title:       req.Title,
		Description: req.Description,
		Price:       req.Price,
		Rooms:       req.Rooms,
		Capacity:    req.Capacity,
		Region:      req.Region,
		Address:     req.Address,
		Lat:         req.Lat,
		Lng:         req.Lng,
		Category:    models.Category(req.Category),
		HasCCTV:     req.HasCCTV,
		IsActive:    true,
	}

	if err := h.propertySvc.Create(c.Request.Context(), p); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create property"})
		return
	}

	c.JSON(http.StatusCreated, p)
}

// GetProperty godoc
// @Summary Get property by ID
// @Tags properties
// @Produce json
// @Param id path string true "Property ID"
// @Success 200 {object} models.Property
// @Router /properties/{id} [get]
func (h *PropertyHandler) GetProperty(c *gin.Context) {
	id := c.Param("id")
	p, err := h.propertySvc.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "property not found"})
		return
	}
	c.JSON(http.StatusOK, p)
}

// ListProperties godoc
// @Summary List properties with filters
// @Tags properties
// @Produce json
// @Param category query string false "Filter by category (house/car)"
// @Param region query string false "Filter by region"
// @Param min_price query number false "Minimum price"
// @Param max_price query number false "Maximum price"
// @Param rooms query int false "Number of rooms"
// @Param page query int false "Page number"
// @Param page_size query int false "Page size"
// @Success 200 {object} map[string]interface{}
// @Router /properties [get]
func (h *PropertyHandler) ListProperties(c *gin.Context) {
	f := models.PropertyFilter{
		Category: c.Query("category"),
		Region:   c.Query("region"),
	}

	if v := c.Query("min_price"); v != "" {
		f.MinPrice, _ = strconv.ParseFloat(v, 64)
	}
	if v := c.Query("max_price"); v != "" {
		f.MaxPrice, _ = strconv.ParseFloat(v, 64)
	}
	if v := c.Query("rooms"); v != "" {
		f.Rooms, _ = strconv.Atoi(v)
	}
	f.Page, _ = strconv.Atoi(c.DefaultQuery("page", "1"))
	f.PageSize, _ = strconv.Atoi(c.DefaultQuery("page_size", "20"))

	properties, total, err := h.propertySvc.List(c.Request.Context(), f)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list properties"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  properties,
		"total": total,
		"page":  f.Page,
	})
}

// UpdateProperty godoc
// @Summary Update a property listing
// @Tags properties
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Property ID"
// @Param body body UpdatePropertyRequest true "Updated property data"
// @Success 200 {object} map[string]string
// @Router /properties/{id} [put]
func (h *PropertyHandler) UpdateProperty(c *gin.Context) {
	ownerID := c.GetString("user_id")
	id := c.Param("id")

	var req UpdatePropertyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	p := &models.Property{
		ID:          id,
		OwnerID:     ownerID,
		Title:       req.Title,
		Description: req.Description,
		Price:       req.Price,
		Rooms:       req.Rooms,
		Capacity:    req.Capacity,
		Region:      req.Region,
		Address:     req.Address,
		Lat:         req.Lat,
		Lng:         req.Lng,
		Category:    models.Category(req.Category),
		HasCCTV:     req.HasCCTV,
		IsActive:    req.IsActive,
	}

	if err := h.propertySvc.Update(c.Request.Context(), p); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update property"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "property updated"})
}

// DeleteProperty godoc
// @Summary Delete a property listing
// @Tags properties
// @Security BearerAuth
// @Param id path string true "Property ID"
// @Success 200 {object} map[string]string
// @Router /properties/{id} [delete]
func (h *PropertyHandler) DeleteProperty(c *gin.Context) {
	ownerID := c.GetString("user_id")
	id := c.Param("id")

	if err := h.propertySvc.Delete(c.Request.Context(), id, ownerID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete property"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "property deleted"})
}

// MyProperties godoc
// @Summary List current user's properties
// @Tags properties
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Property
// @Router /properties/my [get]
func (h *PropertyHandler) MyProperties(c *gin.Context) {
	ownerID := c.GetString("user_id")
	properties, err := h.propertySvc.ListByOwner(c.Request.Context(), ownerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list properties"})
		return
	}
	c.JSON(http.StatusOK, properties)
}

// UploadImage godoc
// @Summary Upload image for a property
// @Tags properties
// @Security BearerAuth
// @Accept multipart/form-data
// @Produce json
// @Param id path string true "Property ID"
// @Param file formance file true "Image file"
// @Param is_primary formData bool false "Set as primary image"
// @Success 201 {object} models.Image
// @Router /properties/{id}/images [post]
func (h *PropertyHandler) UploadImage(c *gin.Context) {
	ownerID := c.GetString("user_id")
	propertyID := c.Param("id")

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
		return
	}
	defer file.Close()

	url, err := h.storageSvc.Upload(c.Request.Context(), file, header)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to upload image"})
		return
	}

	isPrimary := c.PostForm("is_primary") == "true"
	img := &models.Image{
		PropertyID: propertyID,
		MinioURL:   url,
		IsPrimary:  isPrimary,
	}

	if err := h.propertySvc.AddImage(c.Request.Context(), img, ownerID); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, img)
}

// DeleteImage godoc
// @Summary Delete a property image
// @Tags properties
// @Security BearerAuth
// @Param id path string true "Property ID"
// @Param imageId path string true "Image ID"
// @Success 200 {object} map[string]string
// @Router /properties/{id}/images/{imageId} [delete]
func (h *PropertyHandler) DeleteImage(c *gin.Context) {
	ownerID := c.GetString("user_id")
	imageID := c.Param("imageId")

	if err := h.propertySvc.DeleteImage(c.Request.Context(), imageID, ownerID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete image"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "image deleted"})
}

// GetUploadURL godoc
// @Summary Get pre-signed upload URL
// @Tags properties
// @Security BearerAuth
// @Produce json
// @Param filename query string true "File name"
// @Success 200 {object} map[string]string
// @Router /properties/upload-url [get]
func (h *PropertyHandler) GetUploadURL(c *gin.Context) {
	filename := c.Query("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "filename is required"})
		return
	}

	url, err := h.storageSvc.GetPresignedUploadURL(c.Request.Context(), filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate upload URL"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"upload_url": url})
}

// ServeImage serves an image from MinIO storage
// GET /images/*path
func (h *PropertyHandler) ServeImage(c *gin.Context) {
	path := c.Param("path")
	if path == "" || h.storageSvc == nil {
		c.Status(http.StatusNotFound)
		return
	}

	reader, contentType, err := h.storageSvc.GetObject(c.Request.Context(), path)
	if err != nil {
		c.Status(http.StatusNotFound)
		return
	}
	defer reader.Close()

	if contentType == "" {
		if strings.HasSuffix(path, ".jpg") || strings.HasSuffix(path, ".jpeg") {
			contentType = "image/jpeg"
		} else if strings.HasSuffix(path, ".png") {
			contentType = "image/png"
		} else {
			contentType = "application/octet-stream"
		}
	}

	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=86400")
	c.Status(http.StatusOK)
	io.Copy(c.Writer, reader)
}
