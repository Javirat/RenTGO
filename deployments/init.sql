-- RenTGO Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'renter' CHECK (role IN ('renter', 'landlord')),
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

-- Indexes
CREATE INDEX idx_properties_owner ON properties(owner_id);
CREATE INDEX idx_properties_region ON properties(region);
CREATE INDEX idx_properties_category ON properties(category);
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_active ON properties(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_images_property ON images(property_id);
