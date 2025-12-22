-- ===================================================
-- ХРАНИМАЯ ПРОЦЕДУРА ДЛЯ СОЗДАНИЯ КЛИЕНТА
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем или заменяем процедуру создания клиента
CREATE OR REPLACE PROCEDURE tbg.create_client(
    -- Обязательные параметры
    p_name_cyr VARCHAR(255),        -- Наименование на кириллице
    p_last_name VARCHAR(100),       -- Фамилия
    p_first_name VARCHAR(100),      -- Имя
    p_middle_name VARCHAR(100),     -- Отчество
    p_birth_date DATE,              -- Дата рождения
    p_sex CHAR(1),                  -- Пол (M/F)
    p_birth_place VARCHAR(255),     -- Место рождения
    
    -- Выходной параметр - ID созданного клиента
    OUT p_client_id BIGINT,

    -- Опциональные параметры
    p_is_resident BOOLEAN DEFAULT TRUE,      -- Признак резидента
    p_tax_number VARCHAR(20) DEFAULT NULL,   -- ИНН
    p_death_date DATE DEFAULT NULL,          -- Дата смерти
    p_registry_date DATE DEFAULT NULL,       -- Дата регистрации
    p_risk_status VARCHAR(20) DEFAULT 'NORMAL', -- Статус риска
    p_risk_group VARCHAR(50) DEFAULT NULL,   -- Группа риска
    p_country VARCHAR(100) DEFAULT 'Россия' -- Страна
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_registry_date DATE;
    v_error_message TEXT;
BEGIN
    -- Проверка обязательных параметров
    IF p_name_cyr IS NULL OR p_name_cyr = '' THEN
        RAISE EXCEPTION 'Имя клиента не может быть пустым';
    END IF;
    
    IF p_last_name IS NULL OR p_last_name = '' THEN
        RAISE EXCEPTION 'Фамилия не может быть пустой';
    END IF;
    
    IF p_first_name IS NULL OR p_first_name = '' THEN
        RAISE EXCEPTION 'Имя не может быть пустым';
    END IF;
    
    IF p_birth_date IS NULL THEN
        RAISE EXCEPTION 'Дата рождения обязательна';
    END IF;
    
    IF p_birth_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата рождения не может быть в будущем';
    END IF;
    
    IF p_sex NOT IN ('M', 'F') THEN
        RAISE EXCEPTION 'Пол должен быть M (мужской) или F (женский)';
    END IF;
    
    IF p_birth_place IS NULL OR p_birth_place = '' THEN
        RAISE EXCEPTION 'Место рождения обязательно';
    END IF;
    
    -- Проверка даты смерти
    IF p_death_date IS NOT NULL AND p_death_date < p_birth_date THEN
        RAISE EXCEPTION 'Дата смерти не может быть раньше даты рождения';
    END IF;
    
    -- Проверка статуса риска
    IF p_risk_status NOT IN ('NORMAL', 'MEDIUM', 'HIGH', 'VERY_HIGH', 'BLOCKED') THEN
        RAISE EXCEPTION 'Недопустимый статус риска: %', p_risk_status;
    END IF;
    
    -- Устанавливаем дату регистрации (если не указана - текущая дата)
    IF p_registry_date IS NULL THEN
        v_registry_date := CURRENT_DATE;
    ELSE
        v_registry_date := p_registry_date;
        
        -- Проверка что дата регистрации не раньше даты рождения
        IF v_registry_date < p_birth_date THEN
            RAISE EXCEPTION 'Дата регистрации не может быть раньше даты рождения';
        END IF;
    END IF;
    
    -- Вставляем запись о клиенте
    INSERT INTO tbg.mgc_clients (
        name_cyr,
        is_resident,
        tax_number,
        last_name,
        first_name,
        middle_name,
        birth_date,
        death_date,
        registry_date,
        risk_status,
        risk_group,
        sex,
        country,
        birth_place,
        created,
        created_by,
        modified,
        modified_by
    ) VALUES (
        p_name_cyr,
        p_is_resident,
        p_tax_number,
        p_last_name,
        p_first_name,
        p_middle_name,
        p_birth_date,
        p_death_date,
        v_registry_date,
        p_risk_status,
        p_risk_group,
        p_sex,
        p_country,
        p_birth_place,
        CURRENT_TIMESTAMP,
        CURRENT_USER,
        CURRENT_TIMESTAMP,
        CURRENT_USER
    )
    RETURNING client_id INTO p_client_id;
    
    -- Логирование успешного создания
    RAISE NOTICE 'Клиент успешно создан. ID: %, ФИО: % % %', 
        p_client_id, p_last_name, p_first_name, p_middle_name;
    
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Клиент с таким ИНН уже существует: %', p_tax_number;
    WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE EXCEPTION 'Ошибка проверки данных: %', v_error_message;
    WHEN others THEN
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RAISE EXCEPTION 'Ошибка при создании клиента: %', v_error_message;
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'Процедура создания клиентов успешно созданы';
    RAISE NOTICE 'Используйте: CALL tbg.create_client(...)';
END $$;

-- Примеры использования процедуры
/*
DO $$
DECLARE
    v_client_id BIGINT;
BEGIN
    -- Пример 1: Полный вызов
    CALL tbg.create_client(
        p_name_cyr => 'Иванов Иван Иванович',
        p_last_name => 'Иванов',
        p_first_name => 'Иван',
        p_middle_name => 'Иванович',
        p_birth_date => '1990-05-15',
        p_sex => 'M',
        p_birth_place => 'г. Москва',
        p_tax_number => '771234567890',
        p_country => 'Россия',
        p_risk_status => 'NORMAL',
        p_client_id => v_client_id
    );
    
    RAISE NOTICE 'Создан клиент с ID: %', v_client_id;
END $$;
*/

/*
DO $$
DECLARE
    new_client_id BIGINT;
BEGIN
    CALL tbg.create_client(
        'Сидоров Алексей Владимирович',
        'Сидоров',
        'Алексей',
        'Владимирович',
        '1978-03-10',
        'M',
        'г. Екатеринбург',
        TRUE,           -- is_resident
        '770123456789', -- tax_number
        NULL,           -- death_date
        '2024-01-15',   -- registry_date
        'NORMAL',       -- risk_status
        NULL,           -- risk_group
        'Россия',       -- country
        new_client_id   -- OUT параметр
    );
    
    RAISE NOTICE 'Клиент создан с ID: %', new_client_id;
END $$;
*/