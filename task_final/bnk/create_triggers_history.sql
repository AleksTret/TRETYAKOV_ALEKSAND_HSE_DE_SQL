-- ===================================================
-- ТРИГГЕРЫ ДЛЯ ВЕДЕНИЯ ИСТОРИИ ИЗМЕНЕНИЙ
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

SET search_path TO tbg;

-- ===================================================
-- 1. ТРИГГЕР ДЛЯ crp_agreements (история договоров)
-- ===================================================

-- Функция триггера для записи истории договоров
CREATE OR REPLACE FUNCTION tbg.track_agreement_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем, изменились ли поля, которые мы отслеживаем
    IF (OLD.stgeneral IS DISTINCT FROM NEW.stgeneral OR
        OLD.crlimit IS DISTINCT FROM NEW.crlimit OR
        OLD.ovdu_cycles IS DISTINCT FROM NEW.ovdu_cycles OR
        OLD.next_due_date IS DISTINCT FROM NEW.next_due_date) THEN
        
        -- Записываем изменения в историю
        INSERT INTO tbg.crp_agr_hist (
            agreement,
            stgeneral,
            crlimit,
            ovdu_cycles,
            next_due_date,
            hist_date,
            hist_user
        ) VALUES (
            NEW.agreement,
            OLD.stgeneral,
            OLD.crlimit,
            OLD.ovdu_cycles,
            OLD.next_due_date,
            CURRENT_TIMESTAMP,
            CURRENT_USER
        );
        
        RAISE NOTICE 'Изменения договора ID % записаны в историю', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Создаем триггер на обновление таблицы crp_agreements
DROP TRIGGER IF EXISTS trg_agreement_history ON tbg.crp_agreements;
CREATE TRIGGER trg_agreement_history
    AFTER UPDATE ON tbg.crp_agreements
    FOR EACH ROW
    EXECUTE FUNCTION tbg.track_agreement_changes();

-- ===================================================
-- 2. ТРИГГЕР ДЛЯ crp_cards (история карт)
-- ===================================================

-- Функция триггера для записи истории карт
CREATE OR REPLACE FUNCTION tbg.track_card_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем, изменились ли поля, которые мы отслеживаем
    IF (OLD.status_card IS DISTINCT FROM NEW.status_card OR
        OLD.next_annual_fee_date IS DISTINCT FROM NEW.next_annual_fee_date) THEN
        
        -- Записываем изменения в историю карт
        INSERT INTO tbg.crp_cards_hist (
            card_id,
            status_card,
            next_annual_fee_date,
            stamp,
            hist_date,
            hist_user
        ) VALUES (
            NEW.card_id,
            OLD.status_card,
            OLD.next_annual_fee_date,
            CURRENT_TIMESTAMP,
            CURRENT_DATE,
            CURRENT_USER
        );
        
        RAISE NOTICE 'Изменения карты ID % записаны в историю', NEW.card_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Создаем триггер на обновление таблицы crp_cards
DROP TRIGGER IF EXISTS trg_card_history ON tbg.crp_cards;
CREATE TRIGGER trg_card_history
    AFTER UPDATE ON tbg.crp_cards
    FOR EACH ROW
    EXECUTE FUNCTION tbg.track_card_changes();

-- ===================================================
-- СООБЩЕНИЕ О СОЗДАНИИ ТРИГГЕРОВ
-- ===================================================

DO $$
BEGIN
    RAISE NOTICE 'Триггеры для ведения истории успешно созданы:';
    RAISE NOTICE '  1. trg_agreement_history - история изменений договоров';
    RAISE NOTICE '  2. trg_card_history - история изменений карт';
END $$;