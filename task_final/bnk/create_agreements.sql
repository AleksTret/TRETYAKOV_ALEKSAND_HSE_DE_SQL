-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ ДОГОВОРОВ ПРОДУКТОВ КЛИЕНТСКИХ ОТНОШЕНИЙ
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем таблицу crp_agreements
CREATE TABLE tbg.crp_agreements (
    -- Идентификатор записи (суррогатный первичный ключ)
    id BIGSERIAL PRIMARY KEY,
    
    -- Номер договора (уникальный бизнес-идентификатор)
    agreement INTEGER NOT NULL,
    
    -- Название продукта на латинице 
    productname VARCHAR(100),
    
    -- Состояние договора с фиксированными значениями
    stgeneral VARCHAR(10) NOT NULL DEFAULT 'NEW',
    
    -- ID основного клиента
    main_client_id BIGINT NOT NULL,
    
    -- Дата открытия договора
    open_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Дата закрытия договора
    close_date DATE,

    -- Дата предзакрытия (может быть null)
    pre_close_date DATE,
    
    -- Кредитный лимит 
    crlimit NUMERIC(15,2) DEFAULT 0.00,
    
    -- Количество циклов просрочки
    ovdu_cycles INTEGER,

    -- Дата следующего платежа
    next_due_date DATE,

    -- Ставка по договору (null или положительное)
    int_rate NUMERIC(5,2),

    -- Дата и время последнего изменения
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Обеспечиваем уникальность номера договора
    CONSTRAINT uniq_crp_agreement_number UNIQUE (agreement),
    
    -- Проверяем, что дата закрытия не раньше даты открытия
    CONSTRAINT valid_dates_check CHECK (
        close_date IS NULL OR close_date >= open_date
    ),
    
    -- Проверяем, что кредитный лимит не отрицательный
    CONSTRAINT valid_crlimit_check CHECK (
        crlimit >= 0
    ),
    
    -- Проверяем, что статус соответствует допустимым значениям
    CONSTRAINT valid_stgeneral_check CHECK (
        stgeneral IN ('NORM', 'CANC', 'OVDU', 'NEW', 'PEND', 'CLSC', 'SOLD', 'BNRT')
    ),

    -- Проверка, что ovdu_cycles не отрицательный 
    CONSTRAINT valid_ovdu_cycles CHECK (
        ovdu_cycles IS NULL OR ovdu_cycles >= 0
    ),

    -- Проверка, что next_due_date не раньше open_date 
    CONSTRAINT valid_next_due_date CHECK (
        next_due_date IS NULL OR next_due_date >= open_date
    ),

    -- Проверка даты предзакрытия
    CONSTRAINT valid_pre_close_date CHECK (
        pre_close_date IS NULL OR 
        (pre_close_date >= open_date AND (close_date IS NULL OR pre_close_date <= close_date))
    ),

    -- Проверка процентной ставки
    CONSTRAINT valid_int_rate CHECK (
        int_rate IS NULL OR int_rate >= 0
    )
);

-- Добавляем комментарии к таблице и полям
COMMENT ON TABLE tbg.crp_agreements IS 'Договоры продуктов клиентских отношений (Client Relationship Product agreements). Хранит информацию о договорах с клиентами на продукты транзакционного банкинга.';

COMMENT ON COLUMN tbg.crp_agreements.id IS 'Уникальный идентификатор записи (суррогатный ключ)';
COMMENT ON COLUMN tbg.crp_agreements.agreement IS 'Уникальный номер договора (бизнес-идентификатор)';
COMMENT ON COLUMN tbg.crp_agreements.productname IS 'Наименование банковского продукта на латинице (RKO, CashManagement, TradeFinance и т.д.)';
COMMENT ON COLUMN tbg.crp_agreements.stgeneral IS 'Общее состояние договора. Допустимые значения: NORM(нормальный), CANC(отменен), OVDU(просрочен), NEW(новый), PEND(в ожидании), CLSC(закрыт), SOLD(продан), BNRT(банкротство)';
COMMENT ON COLUMN tbg.crp_agreements.main_client_id IS 'Идентификатор основного клиента (контрагента)';
COMMENT ON COLUMN tbg.crp_agreements.open_date IS 'Дата открытия/заключения договора';
COMMENT ON COLUMN tbg.crp_agreements.close_date IS 'Дата закрытия/расторжения договора';
COMMENT ON COLUMN tbg.crp_agreements.crlimit IS 'Кредитный лимит, установленный по договору (если применимо)';
COMMENT ON COLUMN tbg.crp_agreements.modified IS 'Дата и время последнего изменения записи';
COMMENT ON COLUMN tbg.crp_agreements.ovdu_cycles IS 'Количество циклов просрочки';
COMMENT ON COLUMN tbg.crp_agreements.next_due_date IS 'Дата следующего платежа';
COMMENT ON COLUMN tbg.crp_agreements.pre_close_date IS 'Дата предварительного закрытия договора';
COMMENT ON COLUMN tbg.crp_agreements.int_rate IS 'Процентная ставка по договору';

-- Создаем индексы для ускорения часто используемых запросов
CREATE INDEX idx_crp_agreements_agreement ON tbg.crp_agreements(agreement);
CREATE INDEX idx_crp_agreements_main_client_id ON tbg.crp_agreements(main_client_id);
CREATE INDEX idx_crp_agreements_stgeneral ON tbg.crp_agreements(stgeneral); 
CREATE INDEX idx_crp_agreements_open_date ON tbg.crp_agreements(open_date);
CREATE INDEX idx_crp_agreements_productname ON tbg.crp_agreements(productname);
CREATE INDEX idx_crp_agreements_next_due_date ON tbg.crp_agreements(next_due_date);

-- Создаем триггер для автоматического обновления поля modified при изменении записи
CREATE OR REPLACE FUNCTION tbg.update_crp_agreements_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crp_agreements_update
    BEFORE UPDATE ON tbg.crp_agreements
    FOR EACH ROW
    EXECUTE FUNCTION tbg.update_crp_agreements_modified();

-- Сообщение об успешном создании
DO $$
BEGIN
    RAISE NOTICE 'Таблица tbg.crp_agreements успешно создана';
END $$;