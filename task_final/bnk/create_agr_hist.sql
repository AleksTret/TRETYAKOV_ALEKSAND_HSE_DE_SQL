-- ===================================================
-- СОЗДАНИЕ ТАБЛИЦЫ ИСТОРИИ ИЗМЕНЕНИЙ ДОГОВОРОВ
-- В СХЕМЕ TBG (Transaction Banking Group)
-- ===================================================

SET search_path TO tbg;

CREATE TABLE tbg.crp_agr_hist (
    -- Идентификатор записи в истории
    id BIGSERIAL PRIMARY KEY,
    
    -- Ссылка на основной договор
    agreement BIGINT NOT NULL,
    
    -- Поля, которые могут меняться и нужно отслеживать
    accountid VARCHAR(50),
    stgeneral VARCHAR(10),
    crlimit NUMERIC(15,2),
    ovdu_cycles INTEGER,           
    next_due_date DATE,          
    
    -- Технические поля истории
    hist_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hist_user VARCHAR(50) NOT NULL DEFAULT CURRENT_USER
);

-- Внешний ключ на основную таблицу
ALTER TABLE tbg.crp_agr_hist
    ADD CONSTRAINT fk_crp_agr_hist_agreement 
    FOREIGN KEY (agreement) 
    REFERENCES tbg.crp_agreements(agreement);

-- Индекс по agreement
CREATE INDEX idx_crp_agr_hist_agreement_id ON tbg.crp_agr_hist(agreement);