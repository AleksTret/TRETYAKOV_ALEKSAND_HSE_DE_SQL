-- ===================================================
-- СОЗДАНИЕ КАРТ ДЛЯ СУЩЕСТВУЮЩИХ ДОГОВОРОВ
-- ===================================================

\c bnk
SET search_path TO tbg;

\echo 'Создание карт для существующих договоров...'

DO $$
DECLARE
    v_agreement RECORD;
    v_card_id BIGINT;
    v_client_id BIGINT;
    v_card_no VARCHAR(50);
    v_counter INTEGER := 0;
BEGIN
    -- Берем реальные номера договоров из базы
    FOR v_agreement IN 
        SELECT ca.agreement, ca.main_client_id 
        FROM tbg.crp_agreements ca 
        ORDER BY ca.agreement
    LOOP
        
        -- Генерируем номер карты на основе реального номера договора
        v_card_no := '2200' || LPAD(v_agreement.agreement::TEXT, 8, '0') || '01';
        
        RAISE NOTICE 'Создаем карту: % для договора % (клиент %)', 
            v_card_no, v_agreement.agreement, v_agreement.main_client_id;
        
        BEGIN
            CALL tbg.create_card(
                p_card_no => v_card_no,
                p_agreement => v_agreement.agreement,
                p_card_id => v_card_id,
                p_client_id => v_client_id,
                p_card_type => 'MIR_NO_NAME',
                p_card_kind => 'M'
            );
            
            RAISE NOTICE 'Карта создана: ID=%', v_card_id;
            v_counter := v_counter + 1;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка: %', SQLERRM;
        END;
        
    END LOOP;
    
    RAISE NOTICE 'Всего создано карт: %', v_counter;
END $$;

\echo ''
\echo '=== ПРОВЕРКА СОЗДАННЫХ КАРТ ==='
SELECT 
    cc.card_id as "ID карты",
    cc.card_no as "Номер карты",
    cc.agreement as "Номер договора",
    cc.card_type as "Тип карты",
    cc.card_kind as "Вид",
    cc.status_card as "Статус",
    cc.expiredate as "Действует до",
    cc.client_id as "ID клиента",
    mc.name_cyr as "ФИО клиента",
    ca.productname as "Продукт"
FROM tbg.crp_cards cc
JOIN tbg.crp_agreements ca ON cc.agreement = ca.agreement
JOIN tbg.mgc_clients mc ON cc.client_id = mc.client_id
ORDER BY cc.card_no;