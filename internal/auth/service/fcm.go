package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"golang.org/x/oauth2/google"
)

type FCMService struct {
	projectID      string
	credentialsJSON []byte
}

func NewFCMService(projectID string, credentialsJSON []byte) *FCMService {
	if projectID == "" {
		return nil
	}
	return &FCMService{projectID: projectID, credentialsJSON: credentialsJSON}
}

func (f *FCMService) IsConfigured() bool {
	return f != nil && f.projectID != "" && len(f.credentialsJSON) > 0
}

// SendNotification sends a push notification to a specific device via FCM v1 API.
func (f *FCMService) SendNotification(ctx context.Context, fcmToken, title, body string) error {
	if !f.IsConfigured() || fcmToken == "" {
		return nil
	}

	accessToken, err := f.getAccessToken(ctx)
	if err != nil {
		return fmt.Errorf("get access token: %w", err)
	}

	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", f.projectID)

	payload := map[string]interface{}{
		"message": map[string]interface{}{
			"token": fcmToken,
			"notification": map[string]string{
				"title": title,
				"body":  body,
			},
		},
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonData))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("FCM request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(resp.Body)
		log.Printf("[FCM] Error (status %d): %s", resp.StatusCode, string(respBody))
		return fmt.Errorf("FCM error: status %d", resp.StatusCode)
	}

	return nil
}

func (f *FCMService) getAccessToken(ctx context.Context) (string, error) {
	creds, err := google.CredentialsFromJSON(ctx, f.credentialsJSON,
		"https://www.googleapis.com/auth/firebase.messaging")
	if err != nil {
		return "", err
	}
	token, err := creds.TokenSource.Token()
	if err != nil {
		return "", err
	}
	return token.AccessToken, nil
}
