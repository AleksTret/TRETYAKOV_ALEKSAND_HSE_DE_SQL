-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ ПРОДУКТОВ (CRP PRODUCTS)
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем таблицу crp_products
CREATE TABLE tbg.crp_products (
    -- Ключевое поле - тип продукта (соответствует productname в crp_agreements)
    prod_type VARCHAR(100) PRIMARY KEY,
    
    -- Описание продукта
    prod_descr TEXT NOT NULL,
    
    -- Тип карты/счета
    card_type CHAR(1) NOT NULL,  -- C (кредитовая) или D (дебетовая)
    
    -- Параметры продукта
    duration INTEGER,  -- Срок действия в месяцах/днях (положительное число)
    
    -- Тип продукта
    agr_prod_type VARCHAR(10) NOT NULL,  -- CASH, DEPO, POS, MORG, CARD, EDU, AVTO
    
    -- Лимиты по кредиту
    minimal_loan_value NUMERIC(15,2),  -- Минимальная сумма кредита
    maximal_loan_value NUMERIC(15,2),  -- Максимальная сумма кредита
    
    -- Параметры платежей
    payment_date_freq VARCHAR(20),  -- Частота платежей (MONTHLY, WEEKLY, QUARTERLY и т.д.)
    
    -- Досрочное погашение
    early_repayment SMALLINT NOT NULL DEFAULT 1,  -- 1 - ЧДП без заявления, 2 - ЧДП с заявлением, 3 - запрещено
    
    -- Возможность реструктуризации
    restruct CHAR(1) NOT NULL DEFAULT 'N',  -- Y или N
    
    -- Параметры просрочки
    demand_cycles INTEGER,  -- Количество циклов просрочки до заключительного требования
    
    -- Гибкость платежей
    range_change_pay VARCHAR(50),  -- Диапазон изменения даты платежа (например, "+/-5 days")
    
    -- Дополнительные признаки
    creditline BOOLEAN DEFAULT FALSE,  -- Признак кредитной линии
    calc_scheme VARCHAR(50),  -- Способ расчета (ANNUITY, DIFFERENTIAL, BULLET)
    insurance_scheme VARCHAR(100),  -- Схема страхования
    
    -- Технические поля аудита
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    
    -- Проверки
    CONSTRAINT valid_card_type CHECK (
        card_type IN ('C', 'D')
    ),
    
    CONSTRAINT valid_duration CHECK (
        duration IS NULL OR duration > 0
    ),
    
    CONSTRAINT valid_agr_prod_type CHECK (
        agr_prod_type IN ('CASH', 'DEPO', 'POS', 'MORG', 'CARD', 'EDU', 'AVTO')
    ),
    
    CONSTRAINT valid_loan_values CHECK (
        (minimal_loan_value IS NULL AND maximal_loan_value IS NULL) OR
        (minimal_loan_value IS NOT NULL AND maximal_loan_value IS NOT NULL AND 
         minimal_loan_value <= maximal_loan_value AND minimal_loan_value >= 0)
    ),
    
    CONSTRAINT valid_early_repayment CHECK (
        early_repayment IN (1, 2, 3)
    ),
    
    CONSTRAINT valid_restruct CHECK (
        restruct IN ('Y', 'N')
    ),
    
    CONSTRAINT valid_demand_cycles CHECK (
        demand_cycles IS NULL OR demand_cycles >= 0
    )
);

-- Добавляем комментарии к таблице и полям
COMMENT ON TABLE tbg.crp_products IS 'Справочник банковских продуктов (Client Relationship Products). Определяет параметры и характеристики различных банковских продуктов.';

COMMENT ON COLUMN tbg.crp_products.prod_type IS 'Тип/код продукта (уникальный идентификатор). Соответствует полю productname в таблице crp_agreements.';
COMMENT ON COLUMN tbg.crp_products.prod_descr IS 'Полное описание продукта';
COMMENT ON COLUMN tbg.crp_products.card_type IS 'Тип карты/счета: C - кредитовая (Credit), D - дебетовая (Debit)';
COMMENT ON COLUMN tbg.crp_products.duration IS 'Срок действия продукта (в месяцах/днях)';
COMMENT ON COLUMN tbg.crp_products.agr_prod_type IS 'Тип продукта: CASH(наличные), DEPO(депозит), POS(потребительский), MORG(ипотека), CARD(карта), EDU(образовательный), AVTO(автокредит)';
COMMENT ON COLUMN tbg.crp_products.minimal_loan_value IS 'Минимальная сумма кредита по продукту';
COMMENT ON COLUMN tbg.crp_products.maximal_loan_value IS 'Максимальная сумма кредита по продукту';
COMMENT ON COLUMN tbg.crp_products.payment_date_freq IS 'Частота платежей: MONTHLY(ежемесячно), WEEKLY(еженедельно), QUARTERLY(ежеквартально), BIWEEKLY(раз в две недели)';
COMMENT ON COLUMN tbg.crp_products.early_repayment IS 'Условия досрочного погашения: 1 - ЧДП без заявления, 2 - ЧДП с заявлением, 3 - запрещено';
COMMENT ON COLUMN tbg.crp_products.restruct IS 'Возможность реструктуризации: Y - да, N - нет';
COMMENT ON COLUMN tbg.crp_products.demand_cycles IS 'Количество циклов просрочки до заключительного требования';
COMMENT ON COLUMN tbg.crp_products.range_change_pay IS 'Диапазон изменения даты платежа (например, "+/- 5 days", "+10 days")';
COMMENT ON COLUMN tbg.crp_products.creditline IS 'Признак кредитной линии: TRUE - продукт является кредитной линией, FALSE - нет';
COMMENT ON COLUMN tbg.crp_products.calc_scheme IS 'Способ расчета платежей: ANNUITY(аннуитетный), DIFFERENTIAL(дифференцированный), BULLET(разовый)';
COMMENT ON COLUMN tbg.crp_products.insurance_scheme IS 'Схема страхования (описание условий страхования)';
COMMENT ON COLUMN tbg.crp_products.created IS 'Дата и время создания записи';
COMMENT ON COLUMN tbg.crp_products.created_by IS 'Пользователь, создавший запись';
COMMENT ON COLUMN tbg.crp_products.modified IS 'Дата и время последнего изменения записи';
COMMENT ON COLUMN tbg.crp_products.modified_by IS 'Пользователь, изменивший запись последним';

-- Создаем индексы для ускорения часто используемых запросов
CREATE INDEX idx_crp_products_card_type ON tbg.crp_products(card_type);
CREATE INDEX idx_crp_products_agr_prod_type ON tbg.crp_products(agr_prod_type);
CREATE INDEX idx_crp_products_creditline ON tbg.crp_products(creditline);

-- Создаем триггер для автоматического обновления полей modified и modified_by
CREATE OR REPLACE FUNCTION tbg.update_crp_products_audit()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    NEW.modified_by = CURRENT_USER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crp_products_update
    BEFORE UPDATE ON tbg.crp_products
    FOR EACH ROW
    EXECUTE FUNCTION tbg.update_crp_products_audit();

-- Добавляем внешний ключ в таблицу crp_agreements для связи с продуктами
-- (если таблица crp_agreements уже существует)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables 
               WHERE table_schema = 'tbg' AND table_name = 'crp_agreements') THEN
               
        ALTER TABLE tbg.crp_agreements
            ADD CONSTRAINT fk_crp_agreements_product 
            FOREIGN KEY (productname) 
            REFERENCES tbg.crp_products(prod_type);
            
        RAISE NOTICE 'Внешний ключ fk_crp_agreements_product добавлен';
    ELSE
        RAISE NOTICE 'Таблица crp_agreements не существует, внешний ключ не добавлен';
    END IF;
END $$;

-- Сообщение об успешном создании
DO $$
BEGIN
    RAISE NOTICE 'Таблица tbg.crp_products успешно создана';
END $$;