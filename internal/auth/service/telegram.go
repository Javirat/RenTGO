package service

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

type TelegramService struct {
	botToken string
	rdb      *redis.Client
}

func NewTelegramService(botToken string, rdb *redis.Client) *TelegramService {
	return &TelegramService{botToken: botToken, rdb: rdb}
}

func (t *TelegramService) IsConfigured() bool {
	return t.botToken != ""
}

// SendOTP sends an OTP code to a user via Telegram.
func (t *TelegramService) SendOTP(phone, code string) error {
	chatID, err := t.GetChatID(context.Background(), phone)
	if err != nil {
		return fmt.Errorf("telefon raqam Telegram botga ulanmagan. Iltimos, avval @bot ga yozing")
	}

	message := fmt.Sprintf("🔐 RenTGO tasdiqlash kodi: *%s*\n\nKodni hech kimga bermang!", code)
	return t.sendMessage(chatID, message)
}

// GetChatID retrieves the Telegram chat ID for a phone number.
func (t *TelegramService) GetChatID(ctx context.Context, phone string) (int64, error) {
	key := "tg_phone:" + normalizePhone(phone)
	val, err := t.rdb.Get(ctx, key).Result()
	if err != nil {
		return 0, fmt.Errorf("phone not linked to Telegram")
	}
	return strconv.ParseInt(val, 10, 64)
}

// SavePhoneChatID saves the mapping between a phone number and Telegram chat ID.
func (t *TelegramService) SavePhoneChatID(ctx context.Context, phone string, chatID int64) error {
	key := "tg_phone:" + normalizePhone(phone)
	return t.rdb.Set(ctx, key, strconv.FormatInt(chatID, 10), 0).Err()
}

func (t *TelegramService) sendMessage(chatID int64, text string) error {
	apiURL := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", t.botToken)

	data := url.Values{
		"chat_id":    {strconv.FormatInt(chatID, 10)},
		"text":       {text},
		"parse_mode": {"Markdown"},
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.PostForm(apiURL, data)
	if err != nil {
		return fmt.Errorf("telegram API request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("telegram API error (status %d): %s", resp.StatusCode, string(body))
	}

	return nil
}

// StartPolling starts listening for Telegram bot updates (long polling).
// Users send their phone number to the bot to link it with their Telegram account.
func (t *TelegramService) StartPolling(ctx context.Context) {
	if !t.IsConfigured() {
		log.Println("[TG] bot token not configured, skipping polling")
		return
	}

	log.Println("[TG] bot polling started")
	offset := 0

	for {
		select {
		case <-ctx.Done():
			log.Println("[TG] bot polling stopped")
			return
		default:
		}

		updates, newOffset, err := t.getUpdates(offset)
		if err != nil {
			log.Printf("[TG] poll error: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}

		for _, u := range updates {
			t.handleUpdate(ctx, u)
		}

		if newOffset > offset {
			offset = newOffset
		}
	}
}

type tgUpdate struct {
	UpdateID int `json:"update_id"`
	Message  *struct {
		Chat struct {
			ID int64 `json:"id"`
		} `json:"chat"`
		Text    string `json:"text"`
		Contact *struct {
			PhoneNumber string `json:"phone_number"`
		} `json:"contact"`
	} `json:"message"`
}

func (t *TelegramService) getUpdates(offset int) ([]tgUpdate, int, error) {
	apiURL := fmt.Sprintf("https://api.telegram.org/bot%s/getUpdates?offset=%d&timeout=30", t.botToken, offset)

	client := &http.Client{Timeout: 35 * time.Second}
	resp, err := client.Get(apiURL)
	if err != nil {
		return nil, offset, err
	}
	defer resp.Body.Close()

	var result struct {
		OK     bool       `json:"ok"`
		Result []tgUpdate `json:"result"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, offset, err
	}

	maxOffset := offset
	for _, u := range result.Result {
		if u.UpdateID >= maxOffset {
			maxOffset = u.UpdateID + 1
		}
	}

	return result.Result, maxOffset, nil
}

func (t *TelegramService) handleUpdate(ctx context.Context, u tgUpdate) {
	if u.Message == nil {
		return
	}

	chatID := u.Message.Chat.ID

	// User shared contact
	if u.Message.Contact != nil {
		phone := normalizePhone(u.Message.Contact.PhoneNumber)
		if err := t.SavePhoneChatID(ctx, phone, chatID); err != nil {
			log.Printf("[TG] save phone error: %v", err)
			t.sendMessage(chatID, "❌ Xatolik yuz berdi. Qaytadan urinib ko'ring.")
			return
		}
		t.sendMessage(chatID, fmt.Sprintf("✅ Telefon raqamingiz ulandi: +%s\n\nEndi RenTGO ilovasida kirish kodini shu yerda olasiz.", phone))
		return
	}

	// /start command or any text
	text := strings.TrimSpace(u.Message.Text)

	if text == "/start" {
		keyboard := `{"keyboard":[[{"text":"📱 Telefon raqamni yuborish","request_contact":true}]],"resize_keyboard":true,"one_time_keyboard":true}`
		apiURL := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", t.botToken)
		data := url.Values{
			"chat_id":      {strconv.FormatInt(chatID, 10)},
			"text":         {"Salom! 👋\n\nRenTGO ilovasiga kirish uchun telefon raqamingizni yuboring.\n\nPastdagi tugmani bosing 👇"},
			"reply_markup": {keyboard},
		}
		client := &http.Client{Timeout: 10 * time.Second}
		client.PostForm(apiURL, data)
		return
	}

	// User typed a phone number manually
	phone := normalizePhone(text)
	if len(phone) == 12 && strings.HasPrefix(phone, "998") {
		if err := t.SavePhoneChatID(ctx, phone, chatID); err != nil {
			log.Printf("[TG] save phone error: %v", err)
			t.sendMessage(chatID, "❌ Xatolik yuz berdi.")
			return
		}
		t.sendMessage(chatID, fmt.Sprintf("✅ Telefon raqamingiz ulandi: +%s\n\nEndi RenTGO ilovasida kirish kodini shu yerda olasiz.", phone))
		return
	}

	t.sendMessage(chatID, "Telefon raqamingizni yuboring:\n• Tugmani bosing 👇\n• Yoki qo'lda yozing: +998XXXXXXXXX")
}

// normalizePhone removes +, spaces, dashes from phone number.
func normalizePhone(phone string) string {
	phone = strings.ReplaceAll(phone, "+", "")
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")
	return phone
}
