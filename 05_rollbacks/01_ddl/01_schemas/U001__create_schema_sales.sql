-- Drops everything in the schema, including Flyway's control table. The rebuild check deletes that
-- table before running this (Annex J, J.6).
DROP SCHEMA IF EXISTS sales CASCADE;
