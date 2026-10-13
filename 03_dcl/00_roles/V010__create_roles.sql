-- Roles belong to the whole instance, which is why their names start with the domain. They are NOLOGIN: they
-- carry permissions and no password is ever versioned. The login user, sales_app, is created by
-- amaranta-shop-infra-postgres from a secret (postgres/init/01-instance.sh).
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sales_reader') THEN
        CREATE ROLE sales_reader NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sales_writer') THEN
        CREATE ROLE sales_writer NOLOGIN;
    END IF;
END
$$;
