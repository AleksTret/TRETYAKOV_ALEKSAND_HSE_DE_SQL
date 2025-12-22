-- ===================================================
-- ЗАГРУЗКА ПРОДУКТОВ ИЗ CSV ФАЙЛА
-- ===================================================

-- Подключаемся к базе bnk (этот файл запускается отдельно)
\c bnk
SET search_path TO tbg;

\echo ''
\echo 'Загрузка продуктов из CSV файла...'

\echo 'Проверка файла: products.csv'

\copy tbg.crp_products(prod_type, prod_descr, card_type, duration, agr_prod_type, minimal_loan_value, maximal_loan_value, payment_date_freq, early_repayment, restruct, demand_cycles, range_change_pay, creditline, calc_scheme, insurance_scheme) FROM 'products.csv' WITH CSV HEADER DELIMITER ',';

\echo 'Продукты успешно загружены из файла products.csv'

SELECT 
    prod_type as "Тип продукта",
    prod_descr as "Описание",
    card_type as "Тип карты",
    agr_prod_type as "Категория",
    duration as "Срок",
    minimal_loan_value as "Мин сумма",
    maximal_loan_value as "Макс сумма"
FROM tbg.crp_products 
ORDER BY agr_prod_type, prod_type;
