package service

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	firebaseCertsURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
	firebaseIssuer   = "https://securetoken.google.com/"
)

type FirebaseVerifier struct {
	projectID string
	keys      map[string]*rsa.PublicKey
	mu        sync.RWMutex
	lastFetch time.Time
}

func NewFirebaseVerifier(projectID string) *FirebaseVerifier {
	fv := &FirebaseVerifier{projectID: projectID}
	if err := fv.fetchKeys(); err != nil {
		log.Printf("[Firebase] failed to fetch initial keys: %v", err)
	}
	return fv
}

func (fv *FirebaseVerifier) fetchKeys() error {
	resp, err := http.Get(firebaseCertsURL)
	if err != nil {
		return fmt.Errorf("fetch firebase certs: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read firebase certs body: %w", err)
	}

	var certs map[string]string
	if err := json.Unmarshal(body, &certs); err != nil {
		return fmt.Errorf("decode firebase certs: %w", err)
	}

	keys := make(map[string]*rsa.PublicKey)
	for kid, certPEM := range certs {
		block, _ := pem.Decode([]byte(certPEM))
		if block == nil {
			continue
		}
		cert, err := x509.ParseCertificate(block.Bytes)
		if err != nil {
			continue
		}
		rsaKey, ok := cert.PublicKey.(*rsa.PublicKey)
		if !ok {
			continue
		}
		keys[kid] = rsaKey
	}

	fv.mu.Lock()
	fv.keys = keys
	fv.lastFetch = time.Now()
	fv.mu.Unlock()

	log.Printf("[Firebase] fetched %d public keys", len(keys))
	return nil
}

func (fv *FirebaseVerifier) getKey(kid string) (*rsa.PublicKey, error) {
	fv.mu.RLock()
	key, ok := fv.keys[kid]
	age := time.Since(fv.lastFetch)
	fv.mu.RUnlock()

	if ok {
		return key, nil
	}

	// Refresh keys if stale (older than 1 hour) or key not found
	if age > time.Hour || !ok {
		if err := fv.fetchKeys(); err != nil {
			return nil, err
		}
		fv.mu.RLock()
		key, ok = fv.keys[kid]
		fv.mu.RUnlock()
		if ok {
			return key, nil
		}
	}

	return nil, fmt.Errorf("firebase key %s not found", kid)
}

// VerifyIDToken verifies a Firebase ID token and returns the phone number.
func (fv *FirebaseVerifier) VerifyIDToken(tokenString string) (string, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		kid, ok := token.Header["kid"].(string)
		if !ok {
			return nil, fmt.Errorf("no kid in token header")
		}
		return fv.getKey(kid)
	})
	if err != nil {
		return "", fmt.Errorf("verify firebase token: %w", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return "", fmt.Errorf("invalid firebase token claims")
	}

	// Verify issuer
	issuer, _ := claims["iss"].(string)
	expectedIssuer := firebaseIssuer + fv.projectID
	if issuer != expectedIssuer {
		return "", fmt.Errorf("invalid issuer: got %s, want %s", issuer, expectedIssuer)
	}

	// Verify audience
	aud, _ := claims["aud"].(string)
	if aud != fv.projectID {
		return "", fmt.Errorf("invalid audience: got %s, want %s", aud, fv.projectID)
	}

	// Extract phone number
	phone, _ := claims["phone_number"].(string)
	if phone == "" {
		return "", fmt.Errorf("no phone_number in firebase token")
	}

	return phone, nil
}
