CREATE SEQUENCE tbg.agreement_seq START 1000;

-- Получение следующего по порядку номер договора
CREATE OR REPLACE FUNCTION tbg.get_next_agreement()
RETURNS INTEGER AS $$
DECLARE
    v_next_num INTEGER;
BEGIN
    -- Всегда сначала проверяем и синхронизируем
    PERFORM tbg.sync_agreement_seq();
    
    -- Получаем следующий номер
    SELECT nextval('tbg.agreement_seq') INTO v_next_num;
    
    RETURN v_next_num;
END;
$$ LANGUAGE plpgsql;

-- 3. Функция синхронизации
CREATE OR REPLACE FUNCTION tbg.sync_agreement_seq()
RETURNS VOID AS $$
DECLARE
    v_max_num INTEGER;
    v_curr_val INTEGER;
BEGIN
    -- Находим максимальный номер в таблице
    SELECT COALESCE(MAX(agreement), 0) INTO v_max_num
    FROM tbg.crp_agreements;
    
    -- Получаем текущее значение SEQUENCE
    SELECT COALESCE(last_value, 0) INTO v_curr_val 
    FROM tbg.agreement_seq;
    
    -- Если нужно обновить SEQUENCE
    IF v_max_num >= v_curr_val THEN
        PERFORM setval('tbg.agreement_seq', v_max_num + 1, false);
        RAISE NOTICE 'SEQUENCE синхронизирован: установлено значение %', v_max_num + 1;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. Запуск синхронизации при старте (можно вручную или по cron)
SELECT tbg.sync_agreement_seq();