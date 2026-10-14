-- Schema of the sales domain. Flyway creates it too (schemas = ["sales"] in flyway.toml) so that its
-- control table has a home; this file keeps the schema in the versioned history.
CREATE SCHEMA IF NOT EXISTS sales;
