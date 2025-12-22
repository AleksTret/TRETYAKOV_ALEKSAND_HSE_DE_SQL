-- ===================================================
-- СОЗДАНИЕ ТЕКУЩИХ РАСЧЕТНЫХ СЧЕТОВ ДЛЯ ВСЕХ КЛИЕНТОВ
-- ===================================================

\c bnk
SET search_path TO tbg;

\echo 'Создание текущих расчетных счетов для всех клиентов...'

DO $$
DECLARE
    v_client RECORD;
    v_agreement_id BIGINT;
    v_agreement_num INTEGER;
    v_counter INTEGER := 0;
BEGIN
    -- Проходим по всем клиентам
    FOR v_client IN SELECT client_id FROM tbg.mgc_clients ORDER BY client_id LOOP
        
        RAISE NOTICE 'Создаем текущий счет для клиента ID: %', v_client.client_id;
        
        -- Создаем договор текущего расчетного счета (БЕЗ accountid параметра)
        CALL tbg.create_agreement(
            p_main_client_id => v_client.client_id,   -- ID клиента
            p_productname => 'CURACC',                -- Текущий расчетный счет
            p_stgeneral => 'NORM',                    -- Статус: нормальный
            p_open_date => CURRENT_DATE,              -- Дата открытия
            p_close_date => NULL,                     -- Дата закрытия
            p_pre_close_date => NULL,                 -- Предзакрытие
            p_crlimit => 0.00,                        -- Без кредитного лимита
            p_ovdu_cycles => NULL,                    -- Циклы просрочки
            p_next_due_date => NULL,                  -- Нет платежей
            p_int_rate => 0.00,                       -- Без процентов
            p_agreement_id => v_agreement_id,         -- OUT: ID договора
            p_agreement_num => v_agreement_num        -- OUT: номер договора
        );
        
        RAISE NOTICE 'Создан договор текущего счета: Номер=% для клиента ID=%', 
            v_agreement_num, v_client.client_id;
        v_counter := v_counter + 1;
        
    END LOOP;
    
    RAISE NOTICE 'Всего создано договоров текущих счетов: %', v_counter;
END $$;

\echo ''
\echo 'Проверка созданных договоров текущих счетов:'
SELECT 
    ca.id as "ID договора",
    ca.agreement as "Номер договора",
    ca.productname as "Продукт",
    ca.stgeneral as "Статус",
    ca.main_client_id as "ID клиента",
    mc.name_cyr as "ФИО клиента",
    ca.open_date as "Дата открытия",
    ca.crlimit as "Кредитный лимит"
FROM tbg.crp_agreements ca
JOIN tbg.mgc_clients mc ON ca.main_client_id = mc.client_id
WHERE ca.productname = 'CURACC'
ORDER BY ca.agreement;