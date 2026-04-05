-- Migration: Remove renter/landlord role distinction
-- All non-admin users become landlords (can both browse and create listings)
-- Run this on existing database after deploying the new code.

UPDATE users SET role = 'landlord' WHERE role = 'renter';

-- Update default for new users
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'landlord';
