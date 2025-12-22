-- ===================================================
-- СКРИПТ ВЫДАЧИ КРЕДИТА (DISBURSEMENT)
-- ===================================================

\c bnk
SET search_path TO tbg;

\echo ''
\echo 'ВЫДАЧА КРЕДИТА ПО ДОГОВОРУ...'

DO $$
DECLARE
    v_agreement_id BIGINT;
    v_agreement_num INTEGER;
    v_client_id BIGINT;
    v_crlimit NUMERIC(15,2);
    v_history_before INTEGER;
    v_history_after INTEGER;
    v_account_no VARCHAR;
    v_client_name VARCHAR;
BEGIN
    -- 1. НАЙТИ ДОГОВОР СО СТАТУСОМ NEW
    SELECT a.id, a.agreement, a.main_client_id, a.crlimit, 
           c.last_name || ' ' || c.first_name
    INTO v_agreement_id, v_agreement_num, v_client_id, v_crlimit, v_client_name
    FROM tbg.crp_agreements a
    JOIN tbg.mgc_clients c ON a.main_client_id = c.client_id
    WHERE a.stgeneral = 'NEW' 
    ORDER BY a.id 
    LIMIT 1;
    
    IF v_agreement_id IS NULL THEN
        RAISE EXCEPTION 'Не найдено договоров со статусом NEW';
    END IF;
    
    RAISE NOTICE 'Найден договор: Номер=%, ID=%, Клиент=%, Лимит=%', 
        v_agreement_num, v_agreement_id, v_client_name, v_crlimit;
    
    -- 2. ЗАГЛУШКИ ОТКРЫТИЯ СЧЕТОВ
    RAISE NOTICE 'Открытие счетов по договору:';
    
    -- Ссудный счет
    v_account_no := '452' || LPAD(v_agreement_num::TEXT, 10, '0');
    RAISE NOTICE 'Открыт ссудный счет: %', v_account_no;
    
    -- Процентный счет
    RAISE NOTICE 'Открыт процентный счет: %', REPLACE(v_account_no, '452', '47427');
    
    -- 3. ПЕРЕВОД ЛИМИТА
    RAISE NOTICE 'Перевод кредитного лимита: %', v_crlimit;
    RAISE NOTICE 'Со счета: 30102 (корреспондентский)';
    RAISE NOTICE 'На счет: % (ссудный)', v_account_no;
    
    -- 4. ИЗМЕНЕНИЕ СТАТУСА ДОГОВОРА (NEW → NORM)
    RAISE NOTICE 'Изменение статуса договора: NEW → NORM';
    
    -- Запись в историю до изменения
    SELECT COUNT(*) INTO v_history_before
    FROM tbg.crp_agr_hist WHERE agreement = v_agreement_num;
    
    -- Обновление статуса (используем NORM вместо OPEN)
    UPDATE tbg.crp_agreements 
    SET stgeneral = 'NORM'
    WHERE id = v_agreement_id;
    
    -- 5. ПРОВЕРКА ИСТОРИИ
    SELECT COUNT(*) INTO v_history_after
    FROM tbg.crp_agr_hist WHERE agreement = v_agreement_num;
    
    RAISE NOTICE 'ПРОВЕРКА ИСТОРИИ:';
    RAISE NOTICE 'Записей до: %', v_history_before;
    RAISE NOTICE 'Записей после: %', v_history_after;
    RAISE NOTICE 'Добавлено записей: %', v_history_after - v_history_before;
    
    RAISE NOTICE 'Договор успешно активирован';
    
END $$;

\echo ''
\echo 'Проверка изменений:'
\echo '==================='

-- Проверка статуса договора
SELECT 
    agreement as "Номер_договора",
    stgeneral as "Статус",
    productname as "Продукт",
    crlimit as "Кредитный_лимит",
    open_date as "Дата_открытия"
FROM tbg.crp_agreements 
WHERE stgeneral = 'NORM'
ORDER BY agreement DESC 
LIMIT 1;

\echo ''
\echo 'Последняя запись в истории изменений:'
SELECT 
    agreement as "Договор",
    stgeneral as "Старый_статус",
    crlimit as "Лимит",
    hist_date as "Дата_изменения",
    hist_user as "Пользователь"
FROM tbg.crp_agr_hist 
ORDER BY id DESC 
LIMIT 1;

\echo ''
\echo 'СКРИПТ ВЫПОЛНЕН УСПЕШНО';