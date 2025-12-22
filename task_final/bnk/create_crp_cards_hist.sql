-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ ИСТОРИИ ИЗМЕНЕНИЙ КАРТ (CRP CARDS HISTORY)
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем таблицу crp_cards_hist
CREATE TABLE tbg.crp_cards_hist (
    -- Идентификатор записи в истории
    id BIGSERIAL PRIMARY KEY,
    
    -- Ссылка на карту
    card_id BIGINT NOT NULL,
    
    -- Поля, которые отслеживаем в истории
    status_card VARCHAR(10),  -- Статус карты (ACT, CNL, EXP, LOST, STOLEN, BLOCKED)
    next_annual_fee_date DATE,  -- Дата следующей годовой комиссии
    
    -- Технические поля истории
    stamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- Момент фиксации изменения
    hist_date DATE NOT NULL DEFAULT CURRENT_DATE,  -- Дата записи истории
    hist_user VARCHAR(50) NOT NULL DEFAULT CURRENT_USER  -- Пользователь, внесший изменение
);

-- Добавляем комментарии к таблице и полям
COMMENT ON TABLE tbg.crp_cards_hist IS 'История изменений банковских карт. Фиксирует изменения ключевых параметров карт для аудита и отслеживания.';

COMMENT ON COLUMN tbg.crp_cards_hist.id IS 'Уникальный идентификатор записи в истории (суррогатный ключ)';
COMMENT ON COLUMN tbg.crp_cards_hist.card_id IS 'Ссылка на карту (внешний ключ к crp_cards.card_id)';
COMMENT ON COLUMN tbg.crp_cards_hist.status_card IS 'Статус карты на момент записи в историю: ACT(активна), CNL(аннулирована), EXP(просрочена), LOST(утрачена), STOLEN(украдена), BLOCKED(заблокирована)';
COMMENT ON COLUMN tbg.crp_cards_hist.next_annual_fee_date IS 'Дата следующей годовой комиссии на момент записи в историю';
COMMENT ON COLUMN tbg.crp_cards_hist.stamp IS 'Точная дата и время фиксации изменения (timestamp)';
COMMENT ON COLUMN tbg.crp_cards_hist.hist_date IS 'Дата записи в историю (обычно совпадает с датой изменения)';
COMMENT ON COLUMN tbg.crp_cards_hist.hist_user IS 'Пользователь, который внес изменение в карту';

-- Внешний ключ на таблицу карт
ALTER TABLE tbg.crp_cards_hist
    ADD CONSTRAINT fk_crp_cards_hist_card 
    FOREIGN KEY (card_id) 
    REFERENCES tbg.crp_cards(card_id)
    ON DELETE CASCADE;

-- Индексы для ускорения запросов
CREATE INDEX idx_crp_cards_hist_card_id ON tbg.crp_cards_hist(card_id);
CREATE INDEX idx_crp_cards_hist_stamp ON tbg.crp_cards_hist(stamp);
CREATE INDEX idx_crp_cards_hist_hist_date ON tbg.crp_cards_hist(hist_date);
CREATE INDEX idx_crp_cards_hist_status_card ON tbg.crp_cards_hist(status_card);
CREATE INDEX idx_crp_cards_hist_next_annual_fee_date ON tbg.crp_cards_hist(next_annual_fee_date);

-- Проверка допустимых значений статуса (если нужно)
ALTER TABLE tbg.crp_cards_hist
    ADD CONSTRAINT valid_status_card_hist_check CHECK (
        status_card IS NULL OR status_card IN ('ACT', 'CNL', 'EXP', 'LOST', 'STOLEN', 'BLOCKED')
    );

-- Создаем триггер для автоматической записи в историю при изменении статуса карты
CREATE OR REPLACE FUNCTION tbg.track_crp_cards_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Записываем в историю, если изменился статус или дата годовой комиссии
    IF OLD.status_card IS DISTINCT FROM NEW.status_card OR 
       OLD.next_annual_fee_date IS DISTINCT FROM NEW.next_annual_fee_date THEN
        
        INSERT INTO tbg.crp_cards_hist (
            card_id,
            status_card,
            next_annual_fee_date,
            hist_date,
            hist_user
        ) VALUES (
            NEW.card_id,
            NEW.status_card,
            NEW.next_annual_fee_date,
            CURRENT_DATE,
            CURRENT_USER
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Применяем триггер к таблице карт
CREATE TRIGGER trg_crp_cards_history
    AFTER UPDATE ON tbg.crp_cards
    FOR EACH ROW
    EXECUTE FUNCTION tbg.track_crp_cards_changes();

-- Сообщение об успешном создании
DO $$
BEGIN
    RAISE NOTICE 'Таблица tbg.crp_cards_hist успешно создана';
    RAISE NOTICE 'Триггер для автоматической записи истории изменений карт создан';
END $$;