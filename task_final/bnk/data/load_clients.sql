-- ===================================================
-- ЗАГРУЗКА КЛИЕНТОВ ИЗ JSON ФАЙЛА С ПАСПОРТНЫМИ ДАННЫМИ
-- ===================================================

\c bnk
SET search_path TO tbg;

\echo ''
\echo 'Загрузка клиентов из JSON файла...'

-- Создаем временную таблицу для JSON данных
CREATE TEMP TABLE temp_clients_json (
    data JSONB
);

-- Загружаем JSON файл через программу jq
\copy temp_clients_json FROM PROGRAM 'jq -c ".[]" clients.json';

DO $$
DECLARE
    v_client_id BIGINT;
    v_client JSONB;
    v_counter INTEGER := 0;
BEGIN
    -- Проходим по всем объектам в JSON
    FOR v_client IN SELECT data FROM temp_clients_json LOOP
        
        RAISE NOTICE 'Создаем клиента: %', v_client->>'name_cyr';
        
        -- Создаем клиента
        CALL tbg.create_client(
            p_name_cyr => v_client->>'name_cyr',
            p_is_resident => (v_client->>'is_resident')::BOOLEAN,
            p_tax_number => v_client->>'tax_number',
            p_last_name => v_client->>'last_name',
            p_first_name => v_client->>'first_name',
            p_middle_name => v_client->>'middle_name',
            p_birth_date => (v_client->>'birth_date')::DATE,
            p_death_date => NULLIF(v_client->>'death_date', '')::DATE,
            p_registry_date => (v_client->>'registry_date')::DATE,
            p_risk_status => v_client->>'risk_status',
            p_risk_group => v_client->>'risk_group',
            p_sex => v_client->>'sex',
            p_country => v_client->>'country',
            p_birth_place => v_client->>'birth_place',
            p_client_id => v_client_id
        );
        
        -- Добавляем паспортные данные
            INSERT INTO tbg.mgc_cl_dcm (
                client_id,
                dcm_type_c,
                dcm_serial_no,
                dcm_no,
                dcm_date,
                dcm_issue_where    
            ) VALUES (
                v_client_id,
                v_client->'passport'->>'type',
                v_client->'passport'->>'dcm_serial_no',
                v_client->'passport'->>'dcm_no',
                (v_client->'passport'->>'dcm_date')::DATE,
                v_client->'passport'->>'issued_by'
            );
                    
        RAISE NOTICE 'Клиент создан с ID: % (добавлен паспорт)', v_client_id;
        v_counter := v_counter + 1;
        
    END LOOP;
    
    RAISE NOTICE 'Создано клиентов с паспортами: %', v_counter;
END $$;

-- Удаляем временную таблицу
DROP TABLE temp_clients_json;

\echo ''
\echo 'Клиенты с паспортными данными успешно созданы!'

\echo ''
\echo 'Проверка клиентов:'
SELECT 
    client_id as "ID",
    name_cyr as "ФИО",
    tax_number as "ИНН",
    birth_date as "Дата рождения",
    sex as "Пол",
    risk_status as "Статус риска"
FROM tbg.mgc_clients 
ORDER BY client_id;

\echo ''
\echo 'Проверка документов клиентов:'
SELECT 
    c.client_id as "ID клиента",
    c.name_cyr as "ФИО",
    d.dcm_type_c as "Тип документа",
    d.dcm_serial_no as "Серия",
    d.dcm_no as "Номер",
    d.dcm_date as "Дата выдачи",
    d.dcm_issue_where as "Кем выдан"
FROM tbg.mgc_clients c
JOIN tbg.mgc_cl_dcm d ON c.client_id = d.client_id
ORDER BY c.client_id;