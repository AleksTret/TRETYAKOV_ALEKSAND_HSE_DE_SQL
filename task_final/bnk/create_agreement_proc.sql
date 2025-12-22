-- ===================================================
-- ХРАНИМАЯ ПРОЦЕДУРА ДЛЯ СОЗДАНИЯ ДОГОВОРА
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

SET search_path TO tbg;

-- Процедура создания нового договора
CREATE OR REPLACE PROCEDURE tbg.create_agreement(
    -- Основные параметры договора
    p_main_client_id BIGINT,               -- ID клиента
    p_productname VARCHAR(100),            -- Тип продукта
    
    -- Выходные параметры
    OUT p_agreement_id BIGINT,             -- ID созданного договора
    OUT p_agreement_num INTEGER,           -- Номер договора

    -- Опциональные параметры
    p_stgeneral VARCHAR(10) DEFAULT 'NEW', -- Статус договора
    p_open_date DATE DEFAULT CURRENT_DATE, -- Дата открытия
    p_close_date DATE DEFAULT NULL,        -- Дата закрытия
    p_pre_close_date DATE DEFAULT NULL,    -- Дата предзакрытия
    p_crlimit NUMERIC(15,2) DEFAULT 0.00,  -- Кредитный лимит
    p_ovdu_cycles INTEGER DEFAULT NULL,    -- Циклы просрочки
    p_next_due_date DATE DEFAULT NULL,     -- Дата следующего платежа
    p_int_rate NUMERIC(5,2) DEFAULT NULL   -- Процентная ставка
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_product_exists BOOLEAN;
    v_client_exists BOOLEAN;
    v_card_exists BOOLEAN;
    v_generated_agreement_num INTEGER;
BEGIN
    -- 1. ПРОВЕРКА ВХОДНЫХ ДАННЫХ
    
    -- Проверка существования клиента
    SELECT EXISTS(SELECT 1 FROM tbg.mgc_clients WHERE client_id = p_main_client_id) 
    INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RAISE EXCEPTION 'Клиент c ID % не существует', p_main_client_id;
    END IF;
    
    -- Проверка существования продукта (обязательное поле)
    IF p_productname IS NULL OR p_productname = '' THEN
        RAISE EXCEPTION 'Тип продукта обязателен для создания договора';
    END IF;

    SELECT EXISTS(SELECT 1 FROM tbg.crp_products WHERE prod_type = p_productname) 
    INTO v_product_exists;
    
    IF NOT v_product_exists THEN
        RAISE EXCEPTION 'Продукт "%" не существует в справочнике. Создайте продукт перед выпуском договора', p_productname;
    END IF;
    
    -- Проверка статуса договора
    IF p_stgeneral NOT IN ('NORM', 'CANC', 'OVDU', 'NEW', 'PEND', 'CLSC', 'SOLD', 'BNRT') THEN
        RAISE EXCEPTION 'Недопустимый статус договора: %', p_stgeneral;
    END IF;
    
    -- Проверка дат
    IF p_close_date IS NOT NULL AND p_close_date < p_open_date THEN
        RAISE EXCEPTION 'Дата закрытия не может быть раньше даты открытия';
    END IF;
    
    IF p_pre_close_date IS NOT NULL AND p_pre_close_date < p_open_date THEN
        RAISE EXCEPTION 'Дата предзакрытия не может быть раньше даты открытия';
    END IF;
    
    IF p_close_date IS NOT NULL AND p_pre_close_date IS NOT NULL AND p_pre_close_date > p_close_date THEN
        RAISE EXCEPTION 'Дата предзакрытия не может быть позже даты закрытия';
    END IF;
    
    IF p_next_due_date IS NOT NULL AND p_next_due_date < p_open_date THEN
        RAISE EXCEPTION 'Дата следующего платежа не может быть раньше даты открытия';
    END IF;
    
    -- Проверка кредитного лимита
    IF p_crlimit < 0 THEN
        RAISE EXCEPTION 'Кредитный лимит не может быть отрицательным';
    END IF;
    
    -- Проверка циклов просрочки
    IF p_ovdu_cycles IS NOT NULL AND p_ovdu_cycles < 0 THEN
        RAISE EXCEPTION 'Количество циклов просрочки не может быть отрицательным';
    END IF;
    
    -- Проверка процентной ставки
    IF p_int_rate IS NOT NULL AND p_int_rate < 0 THEN
        RAISE EXCEPTION 'Процентная ставка не может быть отрицательной';
    END IF;
    
    -- 2. ГЕНЕРАЦИЯ НОМЕРА ДОГОВОРА
    -- Используем функцию для получения следующего номера
    SELECT tbg.get_next_agreement() INTO v_generated_agreement_num;
    p_agreement_num := v_generated_agreement_num;
    
    -- 3. СОЗДАНИЕ ДОГОВОРА
    INSERT INTO tbg.crp_agreements (
        agreement,
        productname,
        stgeneral,
        main_client_id,
        open_date,
        close_date,
        pre_close_date,
        crlimit,
        ovdu_cycles,
        next_due_date,
        int_rate,
        modified
    ) VALUES (
        p_agreement_num,
        p_productname,
        p_stgeneral,
        p_main_client_id,
        p_open_date,
        p_close_date,
        p_pre_close_date,
        p_crlimit,
        p_ovdu_cycles,
        p_next_due_date,
        p_int_rate,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO p_agreement_id;
    
    -- 4. ЛОГИРОВАНИЕ
    RAISE NOTICE 'Договор успешно создан. ID: %, Номер: %, Клиент: %, Продукт: %',
        p_agreement_id, p_agreement_num, p_main_client_id, p_productname;
        
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ошибка уникальности номера договора. Сгенерированный номер % уже существует', v_generated_agreement_num;
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Нарушение целостности данных. Проверьте существование клиента или продукта';
    WHEN check_violation THEN
        RAISE EXCEPTION 'Нарушение проверочных ограничений. Проверьте введенные данные';
    WHEN others THEN
        RAISE EXCEPTION 'Ошибка при создании договора: %', SQLERRM;
END;
$$;

-- Пример использования:
/*
DO $$
DECLARE
    v_agreement_id BIGINT;
    v_agreement_num INTEGER;
BEGIN
    CALL tbg.create_agreement(
        p_main_client_id => 1,                    -- ID существующего клиента
        p_productname => 'STANDARD_CARD',         -- Существующий продукт
        p_crlimit => 100000.00,                   -- Кредитный лимит
        p_agreement_id => v_agreement_id,         -- OUT: ID договора
        p_agreement_num => v_agreement_num        -- OUT: номер договора
    );
    
    RAISE NOTICE 'Создан договор: ID=%, Номер=%', v_agreement_id, v_agreement_num;
END $$;
*/