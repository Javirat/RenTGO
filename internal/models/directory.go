package models

import "time"

type Directory struct {
	ID          string    `json:"id"`
	Type        string    `json:"type"`
	Value       string    `json:"value"`
	ValueUz     string    `json:"value_uz,omitempty"`
	ValueRu     string    `json:"value_ru,omitempty"`
	ValueEn     string    `json:"value_en,omitempty"`
	ParentValue string    `json:"parent_value,omitempty"`
	SortOrder   int       `json:"sort_order"`
	CreatedAt   time.Time `json:"created_at"`
}
