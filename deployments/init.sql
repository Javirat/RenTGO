-- RenTGO Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),

    language VARCHAR(5) NOT NULL DEFAULT 'uz' CHECK (language IN ('uz', 'ru', 'en')),
    full_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Properties table
CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL,
    rooms INTEGER,
    capacity INTEGER,
    region VARCHAR(100),
    address TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    category VARCHAR(20) NOT NULL DEFAULT 'house' CHECK (category IN ('house', 'car')),
    has_cctv BOOLEAN DEFAULT FALSE,
    -- House features
    floor INTEGER,
    total_floors INTEGER,
    furnished BOOLEAN DEFAULT FALSE,
    renovation VARCHAR(20),
    balcony BOOLEAN DEFAULT FALSE,
    parking BOOLEAN DEFAULT FALSE,
    wifi BOOLEAN DEFAULT FALSE,
    washer BOOLEAN DEFAULT FALSE,
    conditioner BOOLEAN DEFAULT FALSE,
    fridge BOOLEAN DEFAULT FALSE,
    tv BOOLEAN DEFAULT FALSE,
    -- Car features
    car_brand VARCHAR(100),
    car_year INTEGER,
    car_transmission VARCHAR(20),
    car_fuel VARCHAR(20),
    car_mileage INTEGER,
    car_color VARCHAR(50),
    car_ac BOOLEAN DEFAULT FALSE,
    car_seats INTEGER,
    views_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Images table
CREATE TABLE IF NOT EXISTS images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    minio_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    renter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    landlord_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(property_id, renter_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_conversations_renter ON conversations(renter_id);
CREATE INDEX idx_conversations_landlord ON conversations(landlord_id);
CREATE INDEX idx_conversations_last_msg ON conversations(last_message_at DESC);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(conversation_id, created_at);
CREATE INDEX idx_properties_owner ON properties(owner_id);
CREATE INDEX idx_properties_region ON properties(region);
CREATE INDEX idx_properties_category ON properties(category);
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_active ON properties(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_images_property ON images(property_id);
