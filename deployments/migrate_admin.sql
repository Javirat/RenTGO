-- Migration: Add admin role
-- Run this on existing database to add admin role support

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('renter', 'landlord', 'admin'));

-- To make a user admin (replace phone number):
-- UPDATE users SET role = 'admin' WHERE phone = '+998XXXXXXXXX';
