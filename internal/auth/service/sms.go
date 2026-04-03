package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"sync"
	"time"
)

type EskizConfig struct {
	Email    string
	Password string
}

type SMSService struct {
	cfg   EskizConfig
	token string
	mu    sync.RWMutex
}

const eskizBaseURL = "https://notify.eskiz.uz/api"

func NewSMSService(cfg EskizConfig) *SMSService {
	s := &SMSService{cfg: cfg}
	if cfg.Email != "" && cfg.Password != "" {
		if err := s.authenticate(); err != nil {
			log.Printf("[SMS] failed to authenticate with Eskiz: %v", err)
		}
	}
	return s
}

func (s *SMSService) IsConfigured() bool {
	return s.cfg.Email != "" && s.cfg.Password != ""
}

func (s *SMSService) Send(phone, message string) error {
	if !s.IsConfigured() {
		return fmt.Errorf("SMS service not configured")
	}

	s.mu.RLock()
	token := s.token
	s.mu.RUnlock()

	err := s.sendRequest(token, phone, message)
	if err != nil {
		// Token may have expired, try to re-authenticate once
		if authErr := s.authenticate(); authErr != nil {
			return fmt.Errorf("SMS auth failed: %w", authErr)
		}
		s.mu.RLock()
		token = s.token
		s.mu.RUnlock()
		err = s.sendRequest(token, phone, message)
	}
	return err
}

func (s *SMSService) sendRequest(token, phone, message string) error {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	writer.WriteField("mobile_phone", phone)
	writer.WriteField("message", message)
	writer.WriteField("from", "4546")
	writer.Close()

	req, err := http.NewRequest("POST", eskizBaseURL+"/message/sms/send", body)
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("send SMS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusUnauthorized {
		return fmt.Errorf("unauthorized")
	}

	if resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("eskiz API error (status %d): %s", resp.StatusCode, string(respBody))
	}

	log.Printf("[SMS] OTP sent to %s", phone)
	return nil
}

func (s *SMSService) authenticate() error {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	writer.WriteField("email", s.cfg.Email)
	writer.WriteField("password", s.cfg.Password)
	writer.Close()

	req, err := http.NewRequest("POST", eskizBaseURL+"/auth/login", body)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("eskiz auth request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("eskiz auth failed (status %d): %s", resp.StatusCode, string(respBody))
	}

	var result struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return fmt.Errorf("decode auth response: %w", err)
	}

	s.mu.Lock()
	s.token = result.Data.Token
	s.mu.Unlock()

	log.Printf("[SMS] authenticated with Eskiz successfully")
	return nil
}
