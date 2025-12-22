-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ ДОКУМЕНТОВ КЛИЕНТОВ (MGC CLIENT DOCUMENTS)
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

-- Убедимся, что мы находимся в нужной схеме
SET search_path TO tbg;

-- Создаем таблицу mgc_cl_dcm
CREATE TABLE tbg.mgc_cl_dcm (
    -- Уникальный идентификатор документа
    dcm_id BIGSERIAL PRIMARY KEY,
    
    -- Ссылка на клиента
    client_id BIGINT NOT NULL,
    
    -- Тип документа
    dcm_type_c VARCHAR(10) NOT NULL,      -- Паспорт (NPT), СНИЛС (SNL) и др.
    
    -- Реквизиты документа
    dcm_serial_no VARCHAR(50),            -- Серия документа
    dcm_no VARCHAR(50) NOT NULL,          -- Номер документа
    dcm_date DATE NOT NULL,               -- Дата выдачи документа
    dcm_issue_where VARCHAR(255) NOT NULL, -- Кем выдан
    dcm_subdivision VARCHAR(100),         -- Код подразделения
    dcm_expir_date DATE,                  -- Дата окончания действия
    dcm_status VARCHAR(10) NOT NULL DEFAULT 'VALID', -- Статус документа
    
    -- Технические поля аудита
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    
    -- Внешний ключ на клиента
    CONSTRAINT fk_mgc_cl_dcm_client 
        FOREIGN KEY (client_id) 
        REFERENCES tbg.mgc_clients(client_id)
        ON DELETE CASCADE,
    
    -- Проверки
    CONSTRAINT valid_dcm_type_check CHECK (
        dcm_type_c IN ('NPT', 'SNL', 'INN', 'PTS', 'VOD', 'MED', 'MIL', 'FOR', 'BIRTH')
    ),
    
    CONSTRAINT valid_dcm_status_check CHECK (
        dcm_status IN ('VALID', 'INVALID', 'EXPIRED', 'LOST')
    ),
    
    CONSTRAINT valid_dates_check CHECK (
        dcm_date <= CURRENT_DATE AND 
        (dcm_expir_date IS NULL OR dcm_expir_date > dcm_date)
    ),
    
    -- Уникальность номера документа в пределах типа
    CONSTRAINT uniq_dcm_no_type UNIQUE (dcm_type_c, dcm_no)
);

-- Добавляем комментарии к таблице и полям
COMMENT ON TABLE tbg.mgc_cl_dcm IS 'Документы клиентов (физических лиц). Хранит информацию о документах, удостоверяющих личность и других документах клиентов.';

COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_id IS 'Уникальный идентификатор документа (суррогатный ключ)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.client_id IS 'Ссылка на клиента (внешний ключ к mgc_clients.client_id)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_type_c IS 'Тип документа: NPT(паспорт), SNL(СНИЛС), INN(ИНН), PTS(паспорт ТС), VOD(водительское), MED(медицинское), MIL(военный билет), FOR(загранпаспорт), BIRTH(свидетельство о рождении)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_serial_no IS 'Серия документа (для паспорта и т.п.)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_no IS 'Номер документа (обязательное поле)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_date IS 'Дата выдачи документа';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_issue_where IS 'Кем выдан документ (наименование органа выдачи)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_subdivision IS 'Код подразделения, выдавшего документ';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_expir_date IS 'Дата окончания действия документа (если применимо)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.dcm_status IS 'Статус документа: VALID(действителен), INVALID(недействителен), EXPIRED(просрочен), LOST(утрачен)';
COMMENT ON COLUMN tbg.mgc_cl_dcm.created IS 'Дата и время создания записи';
COMMENT ON COLUMN tbg.mgc_cl_dcm.created_by IS 'Пользователь, создавший запись';
COMMENT ON COLUMN tbg.mgc_cl_dcm.modified IS 'Дата и время последнего изменения записи';
COMMENT ON COLUMN tbg.mgc_cl_dcm.modified_by IS 'Пользователь, изменивший запись последним';

-- Создаем индексы для ускорения часто используемых запросов
CREATE INDEX idx_mgc_cl_dcm_client_id ON tbg.mgc_cl_dcm(client_id);
CREATE INDEX idx_mgc_cl_dcm_dcm_type_c ON tbg.mgc_cl_dcm(dcm_type_c);
CREATE INDEX idx_mgc_cl_dcm_dcm_no ON tbg.mgc_cl_dcm(dcm_no);
CREATE INDEX idx_mgc_cl_dcm_dcm_status ON tbg.mgc_cl_dcm(dcm_status);
CREATE INDEX idx_mgc_cl_dcm_dcm_expir_date ON tbg.mgc_cl_dcm(dcm_expir_date);

-- Создаем триггер для автоматического обновления полей modified и modified_by
CREATE OR REPLACE FUNCTION tbg.update_mgc_cl_dcm_audit()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    NEW.modified_by = CURRENT_USER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mgc_cl_dcm_update
    BEFORE UPDATE ON tbg.mgc_cl_dcm
    FOR EACH ROW
    EXECUTE FUNCTION tbg.update_mgc_cl_dcm_audit();

-- Сообщение об успешном создании
DO $$
BEGIN
    RAISE NOTICE 'Таблица tbg.mgc_cl_dcm успешно создана';
END $$;