package storage

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/url"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"

	"github.com/MuhammadYahyo/RenTGO/pkg/config"
)

type StorageService struct {
	client *minio.Client
	bucket string
}

func NewStorageService(cfg config.MinIOConfig) (*StorageService, error) {
	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
	})
	if err != nil {
		return nil, fmt.Errorf("connect to minio: %w", err)
	}

	svc := &StorageService{client: client, bucket: cfg.Bucket}

	// Try to ensure bucket exists, but don't block startup if MinIO is unavailable
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	exists, err := client.BucketExists(ctx, cfg.Bucket)
	if err != nil {
		log.Printf("[WARN] MinIO not available yet: %v (image features disabled until MinIO is up)", err)
		return svc, nil
	}
	if !exists {
		if err := client.MakeBucket(ctx, cfg.Bucket, minio.MakeBucketOptions{}); err != nil {
			log.Printf("[WARN] Could not create bucket: %v", err)
		}
	}

	return svc, nil
}

func (s *StorageService) Upload(ctx context.Context, file io.Reader, header *multipart.FileHeader) (string, error) {
	ext := filepath.Ext(header.Filename)
	objectName := uuid.New().String() + ext

	_, err := s.client.PutObject(ctx, s.bucket, objectName, file, header.Size, minio.PutObjectOptions{
		ContentType: header.Header.Get("Content-Type"),
	})
	if err != nil {
		return "", fmt.Errorf("upload object: %w", err)
	}

	objectURL := fmt.Sprintf("/%s/%s", s.bucket, objectName)
	return objectURL, nil
}

func (s *StorageService) GetPresignedUploadURL(ctx context.Context, filename string) (string, error) {
	ext := filepath.Ext(filename)
	objectName := uuid.New().String() + ext

	presignedURL, err := s.client.PresignedPutObject(ctx, s.bucket, objectName, 15*time.Minute)
	if err != nil {
		return "", fmt.Errorf("presign URL: %w", err)
	}

	return presignedURL.String(), nil
}

func (s *StorageService) GetPresignedDownloadURL(ctx context.Context, objectName string) (string, error) {
	reqParams := make(url.Values)
	presignedURL, err := s.client.PresignedGetObject(ctx, s.bucket, objectName, 1*time.Hour, reqParams)
	if err != nil {
		return "", fmt.Errorf("presign download URL: %w", err)
	}
	return presignedURL.String(), nil
}

func (s *StorageService) Delete(ctx context.Context, objectName string) error {
	return s.client.RemoveObject(ctx, s.bucket, objectName, minio.RemoveObjectOptions{})
}
