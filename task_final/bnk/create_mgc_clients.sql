-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ КЛИЕНТОВ (MGC CLIENTS)
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем таблицу mgc_clients
CREATE TABLE tbg.mgc_clients (
    -- Уникальный идентификатор клиента (связь с crp_agreements.main_client_id)
    client_id BIGSERIAL PRIMARY KEY,
    
    -- Основные реквизиты
    name_cyr VARCHAR(255) NOT NULL,           -- Наименование на кириллице
    is_resident BOOLEAN,                      -- Признак резидента
    tax_number VARCHAR(20),                   -- ИНН/Налоговый номер
    last_name VARCHAR(100) NOT NULL,          -- Фамилия
    first_name VARCHAR(100) NOT NULL,         -- Имя
    middle_name VARCHAR(100) NOT NULL,        -- Отчество
    birth_date DATE NOT NULL,                 -- Дата рождения
    death_date DATE,                          -- Дата смерти
    registry_date DATE,                       -- Дата регистрации в системе
    risk_status VARCHAR(20),                  -- Статус риска
    risk_group VARCHAR(50),                   -- Группа риска
    sex CHAR(1) NOT NULL,                     -- Пол (M/F)
    country VARCHAR(100),                     -- Страна
    birth_place VARCHAR(255) NOT NULL,        -- Место рождения
    
    -- Технические поля аудита
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    modified TIMESTAMP,
    modified_by VARCHAR(50),
    
    -- Проверки
    CONSTRAINT valid_dates_check CHECK (
        (death_date IS NULL) OR (death_date >= birth_date)
    ),
    
    CONSTRAINT valid_registry_date CHECK (
        registry_date >= birth_date
    ),
    
    CONSTRAINT valid_sex_check CHECK (
        sex IN ('M', 'F')
    ),
    
    CONSTRAINT valid_risk_status CHECK (
        risk_status IN ('NORMAL', 'MEDIUM', 'HIGH', 'VERY_HIGH', 'BLOCKED')
    )
);

-- Добавляем комментарии к таблице и полям
COMMENT ON TABLE tbg.mgc_clients IS 'Мастер-таблица клиентов (MGC - Master Global Clients). Основная справочная информация о клиентах банка.';

COMMENT ON COLUMN tbg.mgc_clients.client_id IS 'Уникальный идентификатор клиента (суррогатный ключ)';
COMMENT ON COLUMN tbg.mgc_clients.name_cyr IS 'Полное наименование клиента на кириллице';
COMMENT ON COLUMN tbg.mgc_clients.is_resident IS 'Признак резидента';
COMMENT ON COLUMN tbg.mgc_clients.tax_number IS 'Идентификационный номер налогоплательщика';
COMMENT ON COLUMN tbg.mgc_clients.last_name IS 'Фамилия';
COMMENT ON COLUMN tbg.mgc_clients.first_name IS 'Имя';
COMMENT ON COLUMN tbg.mgc_clients.middle_name IS 'Отчество';
COMMENT ON COLUMN tbg.mgc_clients.birth_date IS 'Дата рождения';
COMMENT ON COLUMN tbg.mgc_clients.death_date IS 'Дата смерти';
COMMENT ON COLUMN tbg.mgc_clients.registry_date IS 'Дата регистрации клиента в банке';
COMMENT ON COLUMN tbg.mgc_clients.risk_status IS 'Статус риска клиента: NORMAL, MEDIUM, HIGH, VERY_HIGH, BLOCKED';
COMMENT ON COLUMN tbg.mgc_clients.risk_group IS 'Группа риска';
COMMENT ON COLUMN tbg.mgc_clients.sex IS 'Пол: M - мужской, F - женский';
COMMENT ON COLUMN tbg.mgc_clients.country IS 'Страна гражданства';
COMMENT ON COLUMN tbg.mgc_clients.birth_place IS 'Место рождения';
COMMENT ON COLUMN tbg.mgc_clients.created IS 'Дата и время создания записи';
COMMENT ON COLUMN tbg.mgc_clients.created_by IS 'Пользователь, создавший запись';
COMMENT ON COLUMN tbg.mgc_clients.modified IS 'Дата и время последнего изменения записи';
COMMENT ON COLUMN tbg.mgc_clients.modified_by IS 'Пользователь, изменивший запись последним';

-- Создаем индексы для ускорения часто используемых запросов
CREATE INDEX idx_mgc_clients_tax_number ON tbg.mgc_clients(tax_number);
CREATE INDEX idx_mgc_clients_last_name ON tbg.mgc_clients(last_name);
CREATE INDEX idx_mgc_clients_first_name ON tbg.mgc_clients(first_name);
CREATE INDEX idx_mgc_clients_birth_date ON tbg.mgc_clients(birth_date);
CREATE INDEX idx_mgc_clients_risk_status ON tbg.mgc_clients(risk_status);
CREATE INDEX idx_mgc_clients_registry_date ON tbg.mgc_clients(registry_date);
CREATE INDEX idx_mgc_clients_name_cyr ON tbg.mgc_clients(name_cyr);

-- Создаем триггер для автоматического обновления полей modified и modified_by
CREATE OR REPLACE FUNCTION tbg.update_mgc_clients_audit()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    NEW.modified_by = CURRENT_USER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mgc_clients_update
    BEFORE UPDATE ON tbg.mgc_clients
    FOR EACH ROW
    EXECUTE FUNCTION tbg.update_mgc_clients_audit();

-- Добавляем внешний ключ в таблицу crp_agreements для связи с клиентами
-- (если таблица crp_agreements уже существует)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables 
               WHERE table_schema = 'tbg' AND table_name = 'crp_agreements') THEN
               
        ALTER TABLE tbg.crp_agreements
            ADD CONSTRAINT fk_crp_agreements_main_client 
            FOREIGN KEY (main_client_id) 
            REFERENCES tbg.mgc_clients(client_id);
            
        RAISE NOTICE 'Внешний ключ fk_crp_agreements_main_client добавлен';
    ELSE
        RAISE NOTICE 'Таблица crp_agreements не существует, внешний ключ не добавлен';
    END IF;
END $$;

-- Сообщение об успешном создании
DO $$
BEGIN
    RAISE NOTICE 'Таблица tbg.mgc_clients успешно создана';
END $$;