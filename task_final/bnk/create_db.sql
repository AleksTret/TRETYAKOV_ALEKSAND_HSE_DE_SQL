-- ============================================
-- СКРИПТ СОЗДАНИЯ БАЗЫ BNK И СХЕМЫ TBG
-- ВНИМАНИЕ: УДАЛИТ СУЩЕСТВУЮЩУЮ БАЗУ BNK СО ВСЕМИ ДАННЫМИ!
-- ============================================

-- 1. Проверяем, существует ли база BNK
-- 2. Если существует - завершаем все соединения и удаляем
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_database WHERE datname = 'bnk') THEN
        -- Завершаем все активные соединения к базе bnk
        EXECUTE (
            SELECT 'SELECT pg_terminate_backend(' || pid || ') FROM pg_stat_activity WHERE datname = ''bnk'' AND pid <> pg_backend_pid()'
        );
        
        -- Удаляем базу
        DROP DATABASE bnk;
        RAISE NOTICE 'База BNK удалена';
    ELSE
        RAISE NOTICE 'База BNK не существует, создаем новую';
    END IF;
END $$;

-- 3. Создаем базу данных BNK с полными параметрами
CREATE DATABASE bnk
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'ru_RU.UTF-8'
    LC_CTYPE = 'ru_RU.UTF-8'
    CONNECTION LIMIT = 100
    TEMPLATE = template0; 

COMMENT ON DATABASE bnk IS 'Основная банковская база данных';

\echo 'База BNK создана'

-- 4. Подключаемся к базе BNK
\c bnk

-- 5. Удаляем схему TBG если существует (с каскадом)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.schemata WHERE schema_name = 'tbg') THEN
        DROP SCHEMA tbg CASCADE;
    END IF;
END $$;

-- 6. Создаем схему TBG
CREATE SCHEMA tbg
    AUTHORIZATION postgres;

COMMENT ON SCHEMA tbg IS 'Схема транзакционного банкинга (Transaction Banking Group)';

\echo 'Схема TBG создана'

-- 7. Устанавливаем пути поиска
ALTER DATABASE bnk SET search_path TO tbg;
SET search_path TO tbg;

\echo 'Search_path установлен: tbg'