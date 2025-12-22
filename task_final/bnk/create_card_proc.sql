-- ===================================================
-- ХРАНИМАЯ ПРОЦЕДУРА ДЛЯ СОЗДАНИЯ КАРТЫ
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

SET search_path TO tbg;

-- Процедура создания новой банковской карты
CREATE OR REPLACE PROCEDURE tbg.create_card(
    -- Обязательные параметры
    p_card_no VARCHAR(50),              -- Номер карты
    p_agreement INTEGER,                -- Номер договора
    
    -- Выходные параметры
    OUT p_card_id BIGINT,                  -- ID созданной карты
    OUT p_client_id BIGINT,                -- ID клиента из договора

    -- Опциональные параметры
    p_card_type VARCHAR(20) DEFAULT NULL,  -- Тип платежной системы
    p_card_kind CHAR(1) DEFAULT 'M',       -- Вид карты: M-основная, S-дополнительная
    p_activation_date DATE DEFAULT NULL    -- Дата активации
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_agreement_exists BOOLEAN;
    v_agreement_id BIGINT;
    v_main_client_id BIGINT;
    v_productname VARCHAR(100);  -- Продукт из договора
    v_existing_main_card VARCHAR(50);
    v_prevcardno VARCHAR(50);
    v_reg_date DATE := CURRENT_DATE;
    v_expiredate DATE;
BEGIN
    -- 1. ПРОВЕРКА ВХОДНЫХ ДАННЫХ
    
    -- Проверка номера карты
    IF p_card_no IS NULL OR p_card_no = '' THEN
        RAISE EXCEPTION 'Номер карты обязателен';
    END IF;
    
    -- Проверка уникальности номера карты
    IF EXISTS (SELECT 1 FROM tbg.crp_cards WHERE card_no = p_card_no) THEN
        RAISE EXCEPTION 'Карта с номером % уже существует', p_card_no;
    END IF;
    
    -- Проверка существования договора
    SELECT EXISTS(SELECT 1 FROM tbg.crp_agreements WHERE agreement = p_agreement) 
    INTO v_agreement_exists;
    
    IF NOT v_agreement_exists THEN
        RAISE EXCEPTION 'Договор с номером % не существует', p_agreement;
    END IF;
    
    -- Получаем данные из договора: ID, клиента, продукт
    SELECT id, main_client_id, productname 
    INTO v_agreement_id, v_main_client_id, v_productname
    FROM tbg.crp_agreements 
    WHERE agreement = p_agreement;
    
    p_client_id := v_main_client_id;
    
    -- Проверка существования клиента
    IF NOT EXISTS (SELECT 1 FROM tbg.mgc_clients WHERE client_id = v_main_client_id) THEN
        RAISE EXCEPTION 'Клиент с ID % (из договора) не существует', v_main_client_id;
    END IF;
    
    -- Проверка что у договора указан продукт
    IF v_productname IS NULL OR v_productname = '' THEN
        RAISE EXCEPTION 'У договора % не указан продукт', p_agreement;
    END IF;
    
    -- Автоматически вычисляем дату окончания (на 3 года от текущей даты)
    v_expiredate := CURRENT_DATE + INTERVAL '3 years';
    
    -- Проверка вида карты
    IF p_card_kind NOT IN ('M', 'S') THEN
        RAISE EXCEPTION 'Вид карты должен быть M (основная) или S (дополнительная)';
    END IF;
    
    -- Проверка даты активации (если указана)
    IF p_activation_date IS NOT NULL AND p_activation_date < v_reg_date THEN
        RAISE EXCEPTION 'Дата активации не может быть раньше даты регистрации';
    END IF;
    
    -- 2. ОБРАБОТКА ВИДА КАРТЫ
    
    -- Если не указан вид карты, проверяем есть ли уже карты по договору
    IF p_card_kind = 'M' THEN
        -- Проверяем, есть ли уже основная карта по этому договору
        SELECT card_no INTO v_existing_main_card
        FROM tbg.crp_cards 
        WHERE agreement = p_agreement 
          AND card_kind = 'M'
          AND expiredate > CURRENT_DATE
          AND status_card = 'ACT';
        
        IF v_existing_main_card IS NOT NULL THEN
            RAISE EXCEPTION 'По договору % уже существует действующая основная карта: %', 
                p_agreement, v_existing_main_card;
        END IF;
    END IF;
    
    -- Если это дополнительная карта, проверяем наличие основной
    IF p_card_kind = 'S' THEN
        -- Находим действующую основную карту по договору
        SELECT card_no INTO v_existing_main_card
        FROM tbg.crp_cards 
        WHERE agreement = p_agreement 
          AND card_kind = 'M'
          AND expiredate > CURRENT_DATE
          AND status_card = 'ACT';
        
        IF v_existing_main_card IS NULL THEN
            RAISE EXCEPTION 'Для создания дополнительной карты нужна действующая основная карта по договору %', 
                p_agreement;
        END IF;
    END IF;
    
    -- 3. ПОИСК ПРЕДЫДУЩЕЙ КАРТЫ (для перевыпуска)
    -- Если есть карта с таким же договором, но просроченная или аннулированная
    SELECT card_no INTO v_prevcardno
    FROM tbg.crp_cards 
    WHERE agreement = p_agreement 
      AND (expiredate <= CURRENT_DATE OR status_card IN ('CNL', 'EXP'))
    ORDER BY expiredate DESC 
    LIMIT 1;
    
    -- 4. СОЗДАНИЕ КАРТЫ
    INSERT INTO tbg.crp_cards (
        card_no,
        agreement,
        prevcardno,
        maincardno,
        expiredate,
        status_card,
        client_id,
        status_date,
        reg_date,
        activation_date,
        next_annual_fee_date,
        card_type,
        card_kind,
        created,
        created_by,
        modified,
        modified_by
    ) VALUES (
        p_card_no,
        p_agreement,
        v_prevcardno,                 -- Предыдущая карта (если перевыпуск)
        CASE WHEN p_card_kind = 'S' THEN v_existing_main_card ELSE NULL END, -- Основная карта для доп.
        v_expiredate,                 -- Автоматически рассчитанная дата
        'ACT',                        -- Статус по умолчанию
        v_main_client_id,             -- Клиент из договора
        CASE WHEN p_activation_date IS NOT NULL THEN p_activation_date ELSE NULL END,
        v_reg_date,
        p_activation_date,
        NULL,                         -- Дата следующей годовой комиссии
        p_card_type,
        p_card_kind,
        CURRENT_TIMESTAMP,
        CURRENT_USER,
        CURRENT_TIMESTAMP,
        CURRENT_USER
    )
    RETURNING card_id INTO p_card_id;
      
    -- 5. ЛОГИРОВАНИЕ
    RAISE NOTICE 'Карта успешно создана. ID: %, Номер: %, Договор: %, Вид: %, Продукт: %, Клиент: %',
        p_card_id, p_card_no, p_agreement, 
        CASE p_card_kind WHEN 'M' THEN 'Основная' ELSE 'Дополнительная' END,
        v_productname,
        v_main_client_id;
        
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Карта с номером % уже существует', p_card_no;
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Нарушение целостности данных. Проверьте существование договора или клиента';
    WHEN check_violation THEN
        RAISE EXCEPTION 'Нарушение проверочных ограничений. Проверьте введенные данные';
    WHEN others THEN
        RAISE EXCEPTION 'Ошибка при создании карты: %', SQLERRM;
END;
$$;

-- Пример использования
/*

DO $$
DECLARE
    v_card_id BIGINT;
    v_client_id BIGINT;
BEGIN
    -- Создание основной карты
    CALL tbg.create_card(
        p_card_no => '1234567812345678',
        p_agreement => 1001,
        p_crp_prod_type => 'GOLD_CARD',
        p_expiredate => '2026-12-31',
        p_card_type => 'VISA',
        p_card_kind => 'M',
        p_card_id => v_card_id,
        p_client_id => v_client_id
    );
    
    RAISE NOTICE 'Создана основная карта: ID=%, Клиент=%', v_card_id, v_client_id;
    
    -- Создание дополнительной карты к той же
    CALL tbg.create_card(
        p_card_no => '8765432187654321',
        p_agreement => 1001,
        p_crp_prod_type => 'GOLD_CARD',
        p_expiredate => '2026-12-31',
        p_card_type => 'VISA',
        p_card_kind => 'S',
        p_card_id => v_card_id,
        p_client_id => v_client_id
    );
    
    RAISE NOTICE 'Создана дополнительная карта: ID=%', v_card_id;
END $$;
*/