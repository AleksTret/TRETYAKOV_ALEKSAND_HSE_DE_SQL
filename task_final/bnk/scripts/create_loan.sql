-- ===================================================
-- СОЗДАНИЕ КРЕДИТНОГО ДОГОВОРА С КАРТОЙ ТИПА LOCAL
-- ===================================================

\c bnk
SET search_path TO tbg;

\echo ''
\echo 'Создаем кредитный договор и карту LOCAL...'

DO $$
DECLARE
    v_agreement_id BIGINT;
    v_agreement_num INTEGER;
    v_card_no VARCHAR := '22000000999999';
    v_card_id BIGINT;
    v_client_id BIGINT;
BEGIN
    -- Создаем договор
    CALL tbg.create_agreement(
        p_main_client_id => 2::BIGINT,
        p_productname => 'CONSUMER_LOAN'::VARCHAR,
        p_crlimit => 300000.00::NUMERIC,
        p_int_rate => 14.9::NUMERIC,
        p_agreement_id => v_agreement_id,
        p_agreement_num => v_agreement_num
    );
    
    RAISE NOTICE 'Договор создан: ID=%, Номер=%', v_agreement_id, v_agreement_num;

    -- Создаем карту LOCAL для этого договора
    CALL tbg.create_card(
        p_card_no => v_card_no::VARCHAR,
        p_agreement => v_agreement_num::INTEGER,
        p_card_type => 'LOCAL'::VARCHAR,
        p_card_id => v_card_id,
        p_client_id => v_client_id
    );
    
    RAISE NOTICE 'Карта создана: ID=%, Номер=%, Клиент=%', v_card_id, v_card_no, v_client_id;
END $$;

\echo 'Готово!'

\echo ''
\echo 'Проверка созданного кредитного договора:'
SELECT 
    a.agreement as "Номер договора",
    a.productname as "Продукт",
    a.stgeneral  as "Статус",
    a.main_client_id as "ID клиента",
    c.last_name || ' ' || c.first_name || ' ' || COALESCE(c.middle_name, '') as "ФИО клиента",
    a.open_date as "Дата договора",
    a.close_date as "Дата закрытия",
    a.crlimit  as "Кредитный лимит",
    a.int_rate as "Ставка %"
FROM tbg.crp_agreements a
JOIN tbg.mgc_clients c ON a.main_client_id = c.client_id
WHERE a.productname IN ('CONSUMER_LOAN', 'CREDIT_CARD', 'AVTO_LOAN', 'MORTGAGE', 'EDU_LOAN')
ORDER BY a.agreement  DESC
LIMIT 1;

\echo ''
\echo 'Проверка созданной карты типа LOCAL:'
SELECT 
    cr.card_no as "Номер карты",
    cr.card_type as "Тип карты",
    cr.card_kind as "Вид",
    cr.status_card  as "Статус",
    cr.expiredate as "Действует до",
    ca.agreement as "Договор",
    ca.productname as "Продукт",
    cl.client_id as "ID клиента",
    cl.last_name || ' ' || cl.first_name || ' ' || COALESCE(cl.middle_name, '') as "ФИО клиента"
FROM tbg.crp_cards cr
JOIN tbg.crp_agreements ca ON cr.agreement = ca.agreement
JOIN tbg.mgc_clients cl ON cr.client_id = cl.client_id
WHERE cr.card_type = 'LOCAL'
ORDER BY cr.card_id DESC
LIMIT 1;