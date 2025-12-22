-- ============================================
-- МАСТЕР-СКРИПТ СОЗДАНИЯ БАЗЫ ДАННЫХ BNK
-- ЗАПУСКАТЬ ОТ ПОЛЬЗОВАТЕЛЯ postgres ИЛИ СУПЕРПОЛЬЗОВАТЕЛЯ
-- ============================================

\echo '============================================'
\echo 'НАЧАЛО СОЗДАНИЯ БАЗЫ ДАННЫХ BNK'
\echo '============================================'

-- 1. Создание базы и схемы
\echo ''
\echo '1. Создание базы данных и схемы'
\i create_db.sql

-- 2. Создание таблиц в правильном порядке (по зависимостям)
\echo ''
\echo '2. Создание таблицы договоров crp_agreements'
\i create_agreements.sql

\echo ''
\echo '3. Создание таблицы истории изменений договоров crp_agr_hist'
\i create_agr_hist.sql

\echo ''
\echo '4. Создание таблицы продуктов crp_products'
\i create_crp_products.sql

\echo ''
\echo '5. Создание таблицы клиентов mgc_clients'
\i create_mgc_clients.sql

\echo ''
\echo '6. Создание таблицы документов клиентов mgc_cl_dcm'
\i create_mgc_cl_dcm.sql

\echo ''
\echo '7. Создание таблицы карт crp_cards'
\i create_crp_cards.sql

\echo ''
\echo '8. Создание истории изменений карт crp_cards_hist'
\i create_crp_cards_hist.sql

\echo ''
\echo '9. Создание функций для генерации номеров договоров set_get_agreements'
\i create_set_get_agreement.sql

\echo ''
\echo '10. Создание процедуры для работы c клиентами'
\i create_client_proc.sql

\echo ''
\echo '11. Создание процедуры для работы с договорами'
\i create_agreement_proc.sql

\echo ''
\echo '12. Создание процедуры для работы с картами'
\i create_card_proc.sql

\echo ''
\echo '13. Создание дополнительных тригеров для заполнения истории'
\i create_triggers_history.sql

-- Загрузка тестовых данных
\cd data

\echo ''
\echo '14. Загрузка продуктов из products.csv'
\i load_products.sql

\echo ''
\echo '15. Загрузка клиентов из clients.csv'
\i load_clients.sql

\echo ''
\echo '16. Создание договоров на текущие счета'
\i create_curracc_agreements.sql

\echo ''
\echo '17. Создание карт для договоров'
\i create_cards_for_agreements.sql

\echo '============================================'
\echo 'БАЗА ДАННЫХ BNK УСПЕШНО СОЗДАНА!'
\echo '============================================'

-- Проверка создания таблиц
\echo 'Проверка созданных таблиц:'
SELECT 
    table_schema,
    table_name,
    (SELECT COUNT(*) FROM tbg.crp_agreements) as agreements_count,
    (SELECT COUNT(*) FROM tbg.mgc_clients) as clients_count,
    (SELECT COUNT(*) FROM tbg.crp_products) as products_count,
    (SELECT COUNT(*) FROM tbg.crp_cards) as cards_count
FROM information_schema.tables 
WHERE table_schema = 'tbg'
ORDER BY table_name;

\echo ''
\echo 'Проверка созданных ФУНКЦИИ:'
SELECT 
    n.nspname as schema,
    p.proname as function_name,
    CASE p.prokind
        WHEN 'f' THEN 'FUNCTION'
        WHEN 'p' THEN 'PROCEDURE'
    END as type
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'tbg'
ORDER BY p.proname;

\echo ''
\echo 'Проверка созданных ТРИГГЕРОВ:'
SELECT 
    n.nspname as schema,
    c.relname as table_name,
    t.tgname as trigger_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'tbg' AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname;

\echo ''
\echo 'Проверка созданных ВНЕШНИХ КЛЮЧЕЙ:'
SELECT
    tc.table_name as "Таблица",
    kcu.column_name as "Колонка", 
    ccu.table_name as "Ссылается на",
    ccu.column_name as "Колонка в таблице"
FROM information_schema.table_constraints tc 
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'tbg'
ORDER BY tc.table_name;
