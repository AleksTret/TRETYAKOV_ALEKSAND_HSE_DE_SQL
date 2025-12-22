-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ КАРТ (CRP CARDS)
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем таблицу crp_cards
CREATE TABLE tbg.crp_cards (
    -- Уникальный идентификатор карты
    card_id BIGSERIAL PRIMARY KEY,
    
    -- Внешний ключ, связь с таблицей договоров
    agreement INTEGER NOT NULL,

    -- Номер карты 
    card_no VARCHAR(50) NOT NULL UNIQUE,
    
    -- Ссылки на другие карты
    prevcardno VARCHAR(50),  -- Предыдущая карта (при перевыпуске)
    maincardno VARCHAR(50),  -- Главная карта по договору
    
    -- Срок действия и статус
    expiredate DATE NOT NULL,  -- Дата окончания действия
    status_card VARCHAR(10) NOT NULL DEFAULT 'ACT',  -- ACT, CNL 
    -- stgeneral удалено по требованию
    
    -- Связь с клиентом
    client_id BIGINT NOT NULL,
    
    -- Даты операций с картой
    status_date DATE,  -- Дата изменения статуса
    reg_date DATE NOT NULL DEFAULT CURRENT_DATE,  -- Дата регистрации
    activation_date DATE,  -- Дата активации
    
    -- Финансовые даты
    next_annual_fee_date DATE,  -- Дата следующей годовой комиссии
    
    -- Классификация карты
    card_type VARCHAR(20),  -- Тип карты (VISA, MasterCard, MIR и т.д.)
    card_kind CHAR(1) NOT NULL DEFAULT 'M',  -- M основная, S дополнительная
    
    -- Технические поля аудита
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    
    -- Внешние ключи
    CONSTRAINT fk_crp_cards_client 
        FOREIGN KEY (client_id) 
        REFERENCES tbg.mgc_clients(client_id),
    
    -- Проверки
    CONSTRAINT valid_status_card_check CHECK (
        status_card IN ('ACT', 'CNL', 'EXP', 'LOST', 'STOLEN', 'BLOCKED')
    ),
    
    CONSTRAINT valid_card_kind_check CHECK (
        card_kind IN ('M', 'S')
    ),
    
    CONSTRAINT valid_dates_check CHECK (
        expiredate > reg_date AND
        (activation_date IS NULL OR activation_date >= reg_date) AND
        (status_date IS NULL OR status_date >= reg_date) AND
        (next_annual_fee_date IS NULL OR next_annual_fee_date >= reg_date)
    ),
    
    -- Проверка что prevcardno ссылается на существующую карту (если указано)
    CONSTRAINT fk_crp_cards_prevcard 
        FOREIGN KEY (prevcardno) 
        REFERENCES tbg.crp_cards(card_no),
    
    -- Проверка что maincardno ссылается на существующую карту (если указано)
    CONSTRAINT fk_crp_cards_maincard 
        FOREIGN KEY (maincardno) 
        REFERENCES tbg.crp_cards(card_no)
);

-- Добавляем комментарии к таблице и полям
COMMENT ON TABLE tbg.crp_cards IS 'Банковские карты клиентов. Хранит информацию о выпущенных картах, их статусах и характеристиках.';

COMMENT ON COLUMN tbg.crp_cards.card_id IS 'Уникальный идентификатор карты (суррогатный ключ)';
COMMENT ON COLUMN tbg.crp_cards.agreement IS 'Уникальный номер договора (бизнес-идентификатор)';
COMMENT ON COLUMN tbg.crp_cards.card_no IS 'Номер карты (уникальный).';
COMMENT ON COLUMN tbg.crp_cards.prevcardno IS 'Номер предыдущей карты (при перевыпуске)';
COMMENT ON COLUMN tbg.crp_cards.maincardno IS 'Номер главной/основной карты по договору (для дополнительных карт)';
COMMENT ON COLUMN tbg.crp_cards.expiredate IS 'Дата окончания действия карты';
COMMENT ON COLUMN tbg.crp_cards.status_card IS 'Статус карты: ACT(активна), CNL(аннулирована), EXP(просрочена), LOST(утрачена), STOLEN(украдена), BLOCKED(заблокирована)';
COMMENT ON COLUMN tbg.crp_cards.client_id IS 'Ссылка на клиента (внешний ключ к mgc_clients.client_id)';
COMMENT ON COLUMN tbg.crp_cards.status_date IS 'Дата последнего изменения статуса карты';
COMMENT ON COLUMN tbg.crp_cards.reg_date IS 'Дата регистрации/выпуска карты';
COMMENT ON COLUMN tbg.crp_cards.activation_date IS 'Дата активации карты клиентом';
COMMENT ON COLUMN tbg.crp_cards.next_annual_fee_date IS 'Дата следующей годовой комиссии';
COMMENT ON COLUMN tbg.crp_cards.card_type IS 'Тип платежной системы: VISA, MasterCard, MIR, UnionPay и т.д.';
COMMENT ON COLUMN tbg.crp_cards.card_kind IS 'Вид карты: M - основная (Main), S - дополнительная (Supplementary)';
COMMENT ON COLUMN tbg.crp_cards.created IS 'Дата и время создания записи';
COMMENT ON COLUMN tbg.crp_cards.created_by IS 'Пользователь, создавший запись';
COMMENT ON COLUMN tbg.crp_cards.modified IS 'Дата и время последнего изменения записи';
COMMENT ON COLUMN tbg.crp_cards.modified_by IS 'Пользователь, изменивший запись последним';

-- Создаем индексы для ускорения часто используемых запросов
CREATE INDEX idx_crp_cards_card_no ON tbg.crp_cards(card_no);
CREATE INDEX idx_crp_cards_client_id ON tbg.crp_cards(client_id);
CREATE INDEX idx_crp_cards_status_card ON tbg.crp_cards(status_card);
CREATE INDEX idx_crp_cards_expiredate ON tbg.crp_cards(expiredate);
CREATE INDEX idx_crp_cards_card_kind ON tbg.crp_cards(card_kind);
CREATE INDEX idx_crp_cards_maincardno ON tbg.crp_cards(maincardno) WHERE maincardno IS NOT NULL;
CREATE INDEX idx_crp_cards_prevcardno ON tbg.crp_cards(prevcardno) WHERE prevcardno IS NOT NULL;

-- Создаем триггер для автоматического обновления полей modified и modified_by
CREATE OR REPLACE FUNCTION tbg.update_crp_cards_audit()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    NEW.modified_by = CURRENT_USER;
    
    -- Автоматическое обновление status_date при изменении статуса карты
    IF OLD.status_card IS DISTINCT FROM NEW.status_card THEN
        NEW.status_date = CURRENT_DATE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crp_cards_update
    BEFORE UPDATE ON tbg.crp_cards
    FOR EACH ROW
    EXECUTE FUNCTION tbg.update_crp_cards_audit();

-- Добавляем внешний ключ в таблицу crp_cards для связи с договорами
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables 
               WHERE table_schema = 'tbg' AND table_name = 'crp_agreements') THEN
               
        -- Добавляем внешний ключ из crp_cards.agreement в crp_agreements.agreement
        ALTER TABLE tbg.crp_cards
            ADD CONSTRAINT fk_crp_cards_agreement 
            FOREIGN KEY (agreement) 
            REFERENCES tbg.crp_agreements(agreement);
            
        RAISE NOTICE 'Внешний ключ fk_crp_cards_agreement добавлен (crp_cards.agreement → crp_agreements.agreement)';
    ELSE
        RAISE NOTICE 'Таблица crp_agreements не существует, внешний ключ не добавлен';
    END IF;
END $$;

-- Сообщение об успешном создании
DO $$
BEGIN
    RAISE NOTICE 'Таблица tbg.crp_cards успешно создана';
END $$;