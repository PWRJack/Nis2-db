-- ============================================================
-- NIS2 / ACN — Schema Relazionale (PostgreSQL 14+)
-- Registro Centralizzato Asset, Servizi e Dipendenze per ACN
-- Versione 1.1
-- ============================================================
-- Changelog v1.1:
--   - Audit trigger: registra l'autore (modificato_da) da variabile
--     di sessione 'nis2.utente' e traccia anche versione_sw e ip_address.
--   - Vincoli: indici univoci parziali per un solo proprietario attivo
--     per asset e per servizio.
--   - Viste: ordinamento per gravità reale (non alfabetico);
--     v_profilo_acn_export riscritta con sottoquery scalari (no fan-out).
--   - Struttura: DDL e dati di esempio separati (dati in nis2_testdata.sql).
-- ============================================================
-- Struttura:
--   Sez. 1  Lookup tables       (tipo_asset — dato di riferimento)
--   Sez. 2  Entità core         (organizzazione, sede, asset, servizio, fornitore, persona)
--   Sez. 3  Tabelle associative (asset_servizio, contratto, dipendenza, responsabilita)
--   Sez. 4  Audit e sicurezza   (asset_storico, misura_sicurezza, profilo_acn)
--   Sez. 5  Trigger functions
--   Sez. 6  Trigger definitions
--   Sez. 7  Viste ACN
--   Sez. 8  Nota su dati e query di verifica
-- ============================================================


-- ============================================================
-- SEZIONE 1 — LOOKUP: TIPO_ASSET
-- ============================================================

CREATE TABLE tipo_asset (
    codice         VARCHAR(30)  PRIMARY KEY,
    descrizione    VARCHAR(150) NOT NULL,
    categoria_nis2 VARCHAR(50),
    note           TEXT
);

COMMENT ON TABLE  tipo_asset IS 'Lookup dei codici tipologia asset usato come FK da asset.tipo_asset_cod.';
COMMENT ON COLUMN tipo_asset.codice IS 'Codice breve: SERVER_FISICO, APPLICAZIONE, OT_ICS, DATO, ecc.';

INSERT INTO tipo_asset (codice, descrizione, categoria_nis2) VALUES
    ('SERVER_FISICO',   'Server fisico on-premise',                         'Infrastruttura ICT'),
    ('SERVER_VIRTUALE', 'Server virtuale / VM',                             'Infrastruttura ICT'),
    ('WORKSTATION',     'Workstation / PC / laptop',                        'Endpoint'),
    ('RETE',            'Apparato di rete (switch, router, firewall, IPS)', 'Rete'),
    ('APPLICAZIONE',    'Applicazione software (web, desktop, mobile)',     'Software'),
    ('DATABASE',        'DBMS / sistema di gestione database',              'Software'),
    ('CLOUD_SERV',      'Servizio cloud (SaaS, PaaS, IaaS)',               'Cloud'),
    ('OT_ICS',          'Sistema OT / ICS / SCADA / PLC',                  'OT'),
    ('DATO',            'Dataset, archivio dati, Data Warehouse',           'Dato'),
    ('FISICO',          'Asset fisico (edificio, generatore, UPS, ecc.)',   'Fisico');


-- ============================================================
-- SEZIONE 2 — ENTITÀ CORE
-- ============================================================

-- ------------------------------------------------------------
-- 2.1  ORGANIZZAZIONE
-- ------------------------------------------------------------
CREATE TABLE organizzazione (
    id                     SERIAL       PRIMARY KEY,
    nome                   VARCHAR(255) NOT NULL,
    codice_fiscale         VARCHAR(16)  UNIQUE,
    settore_nis2           VARCHAR(100) NOT NULL,
    categoria_nis2         VARCHAR(20)  NOT NULL
                             CHECK (categoria_nis2 IN ('essenziale','importante')),
    pec                    VARCHAR(255),
    sito_web               VARCHAR(255),
    data_registrazione_acn DATE,
    attiva                 BOOLEAN      NOT NULL DEFAULT TRUE,
    note                   TEXT,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  organizzazione IS 'Soggetto NIS2. Allegato I = essenziale; Allegato II = importante.';
COMMENT ON COLUMN organizzazione.settore_nis2 IS
    'Es.: Energia, Trasporti, Sanità, Bancario, Infrastrutture digitali, Spazio, …';

CREATE INDEX idx_org_settore   ON organizzazione (settore_nis2);
CREATE INDEX idx_org_categoria ON organizzazione (categoria_nis2);


-- ------------------------------------------------------------
-- 2.2  SEDE
-- ------------------------------------------------------------
CREATE TABLE sede (
    id                 SERIAL       PRIMARY KEY,
    organizzazione_id  INT          NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    nome               VARCHAR(255) NOT NULL,
    indirizzo          TEXT,
    citta              VARCHAR(100),
    cap                VARCHAR(10),
    paese              VARCHAR(50)  NOT NULL DEFAULT 'IT',
    is_sede_principale BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE sede IS 'Sedi fisiche dell''organizzazione; usate come FK da asset.sede_id.';

CREATE INDEX idx_sede_org ON sede (organizzazione_id);


-- ------------------------------------------------------------
-- 2.3  ASSET
-- ------------------------------------------------------------
CREATE TABLE asset (
    id                SERIAL       PRIMARY KEY,
    organizzazione_id INT          NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    sede_id           INT                   REFERENCES sede (id) ON DELETE SET NULL,
    tipo_asset_cod    VARCHAR(30)  NOT NULL REFERENCES tipo_asset (codice),
    codice_inventario VARCHAR(100) UNIQUE,
    nome              VARCHAR(255) NOT NULL,
    descrizione       TEXT,
    categoria         VARCHAR(20)  NOT NULL DEFAULT 'standard'
                        CHECK (categoria IN ('critico','importante','standard')),
    stato             VARCHAR(20)  NOT NULL DEFAULT 'attivo'
                        CHECK (stato IN ('attivo','in_manutenzione','dismesso')),
    ip_address        VARCHAR(45),     -- IPv4 o IPv6
    versione_sw       VARCHAR(100),
    note              TEXT,
    is_deleted        BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by        VARCHAR(100)
);

COMMENT ON TABLE  asset IS 'Asset ICT, OT, fisici e informativi. Nucleo del profilo ACN.';
COMMENT ON COLUMN asset.categoria  IS 'critico = impatto elevato; importante = medio; standard = basso.';
COMMENT ON COLUMN asset.is_deleted IS 'Soft-delete: nasconde il record senza cancellarlo.';

CREATE INDEX idx_asset_org           ON asset (organizzazione_id);
CREATE INDEX idx_asset_tipo          ON asset (tipo_asset_cod);
CREATE INDEX idx_asset_categoria     ON asset (categoria);
CREATE INDEX idx_asset_operativi     ON asset (organizzazione_id)
    WHERE stato = 'attivo' AND is_deleted = FALSE;


-- ------------------------------------------------------------
-- 2.4  SERVIZIO
-- ------------------------------------------------------------
CREATE TABLE servizio (
    id                SERIAL       PRIMARY KEY,
    organizzazione_id INT          NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    nome              VARCHAR(255) NOT NULL,
    descrizione       TEXT,
    tipo_servizio     VARCHAR(30)  NOT NULL
                        CHECK (tipo_servizio IN ('essenziale','digitale','interno','erogato_terzi')),
    criticita         VARCHAR(10)  NOT NULL DEFAULT 'media'
                        CHECK (criticita IN ('alta','media','bassa')),
    stato             VARCHAR(20)  NOT NULL DEFAULT 'attivo'
                        CHECK (stato IN ('attivo','sospeso','dismesso')),
    rto_ore           INT          CHECK (rto_ore >= 0),  -- Recovery Time Objective
    rpo_ore           INT          CHECK (rpo_ore >= 0),  -- Recovery Point Objective
    url_servizio      VARCHAR(255),
    note              TEXT,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN servizio.rto_ore IS 'Tempo max (ore) per ripristinare il servizio dopo un incidente.';
COMMENT ON COLUMN servizio.rpo_ore IS 'Quantità max (ore) di dati che possono essere persi.';

CREATE INDEX idx_servizio_org       ON servizio (organizzazione_id);
CREATE INDEX idx_servizio_criticita ON servizio (criticita);


-- ------------------------------------------------------------
-- 2.5  FORNITORE
-- ------------------------------------------------------------
CREATE TABLE fornitore (
    id                   SERIAL       PRIMARY KEY,
    nome                 VARCHAR(255) NOT NULL,
    codice_fiscale_vat   VARCHAR(50)  UNIQUE,
    paese                VARCHAR(50)  NOT NULL DEFAULT 'IT',
    tipo                 VARCHAR(30)  NOT NULL
                           CHECK (tipo IN ('cloud','sw_vendor','hw_vendor','tlc',
                                           'consulenza','manutenzione','altro')),
    is_fornitore_critico BOOLEAN      NOT NULL DEFAULT FALSE,
    sito_web             VARCHAR(255),
    note                 TEXT,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN fornitore.is_fornitore_critico IS
    'TRUE se rilevante ai fini della supply chain NIS2 (Art.21.2.d).';

CREATE INDEX idx_fornitore_tipo    ON fornitore (tipo);
CREATE INDEX idx_fornitore_critico ON fornitore (is_fornitore_critico)
    WHERE is_fornitore_critico = TRUE;


-- ------------------------------------------------------------
-- 2.6  PERSONA
-- ------------------------------------------------------------
CREATE TABLE persona (
    id                  SERIAL       PRIMARY KEY,
    organizzazione_id   INT          NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    nome                VARCHAR(100) NOT NULL,
    cognome             VARCHAR(100) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    telefono            VARCHAR(30),
    ruolo_organizzativo VARCHAR(50)
                          CHECK (ruolo_organizzativo IN (
                              'CEO','CTO','CISO','DPO',
                              'Responsabile_IT','Referente_NIS2',
                              'Referente_ACN','Admin_Sistema','Altro'
                          )),
    is_referente_acn    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_persona_email_org UNIQUE (email, organizzazione_id)
);

COMMENT ON COLUMN persona.is_referente_acn IS 'TRUE = punto di contatto ufficiale con l''ACN.';

CREATE INDEX idx_persona_org       ON persona (organizzazione_id);
CREATE INDEX idx_persona_referente ON persona (organizzazione_id)
    WHERE is_referente_acn = TRUE;


-- ============================================================
-- SEZIONE 3 — TABELLE ASSOCIATIVE
-- ============================================================

-- ------------------------------------------------------------
-- 3.1  ASSET_SERVIZIO  (N:M  asset → servizio)
-- ------------------------------------------------------------
CREATE TABLE asset_servizio (
    asset_id    INT NOT NULL REFERENCES asset    (id) ON DELETE CASCADE,
    servizio_id INT NOT NULL REFERENCES servizio (id) ON DELETE CASCADE,
    ruolo       VARCHAR(40) NOT NULL DEFAULT 'supporta'
                  CHECK (ruolo IN ('supporta','ospita','elabora_dati','connettivita')),
    data_inizio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fine   DATE,
    note        TEXT,
    PRIMARY KEY (asset_id, servizio_id),
    CONSTRAINT chk_date_asset_serv CHECK (data_fine IS NULL OR data_fine > data_inizio)
);

COMMENT ON TABLE asset_servizio IS
    'Junction N:M: quale asset supporta quale servizio, con ruolo e validità temporale.';

CREATE INDEX idx_asset_serv_servizio ON asset_servizio (servizio_id);


-- ------------------------------------------------------------
-- 3.2  CONTRATTO
-- ------------------------------------------------------------
CREATE TABLE contratto (
    id                         SERIAL        PRIMARY KEY,
    organizzazione_id          INT           NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    fornitore_id               INT           NOT NULL REFERENCES fornitore (id),
    numero_contratto           VARCHAR(100),
    data_inizio                DATE          NOT NULL,
    data_scadenza              DATE,
    oggetto                    TEXT          NOT NULL,
    sla_disponibilita          NUMERIC(5,2)  CHECK (sla_disponibilita BETWEEN 0 AND 100),
    include_clausole_sicurezza BOOLEAN       NOT NULL DEFAULT FALSE,
    valore_annuo_eur           NUMERIC(14,2),
    note                       TEXT,
    created_at                 TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_date_contratto CHECK (data_scadenza IS NULL OR data_scadenza > data_inizio)
);

COMMENT ON COLUMN contratto.sla_disponibilita IS
    'SLA uptime % garantito, es. 99.95 = "cinque nini". NULL se non contrattualizzato.';

CREATE INDEX idx_contratto_org       ON contratto (organizzazione_id);
CREATE INDEX idx_contratto_fornitore ON contratto (fornitore_id);
CREATE INDEX idx_contratto_scadenza  ON contratto (data_scadenza)
    WHERE data_scadenza IS NOT NULL;


-- ------------------------------------------------------------
-- 3.3  DIPENDENZA
--      Collega un asset o servizio a un fornitore terzo.
--      Almeno uno tra asset_id e servizio_id deve essere NOT NULL.
-- ------------------------------------------------------------
CREATE TABLE dipendenza (
    id                SERIAL      PRIMARY KEY,
    organizzazione_id INT         NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    asset_id          INT                  REFERENCES asset    (id) ON DELETE CASCADE,
    servizio_id       INT                  REFERENCES servizio (id) ON DELETE CASCADE,
    fornitore_id      INT         NOT NULL REFERENCES fornitore (id),
    contratto_id      INT                  REFERENCES contratto (id) ON DELETE SET NULL,
    tipo_dipendenza   VARCHAR(30) NOT NULL
                        CHECK (tipo_dipendenza IN (
                            'licenza','hosting','supporto','manutenzione',
                            'fornitura_hw','connettivita','saas','paas','iaas','altro'
                        )),
    criticita         VARCHAR(10) NOT NULL DEFAULT 'media'
                        CHECK (criticita IN ('critica','alta','media','bassa')),
    descrizione       TEXT,
    data_inizio       DATE        NOT NULL DEFAULT CURRENT_DATE,
    data_fine         DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_dip_asset_o_servizio
        CHECK (asset_id IS NOT NULL OR servizio_id IS NOT NULL),
    CONSTRAINT chk_date_dipendenza
        CHECK (data_fine IS NULL OR data_fine > data_inizio)
);

COMMENT ON TABLE  dipendenza IS
    'Dipendenza di un asset/servizio da un fornitore. Nucleo della supply chain NIS2 (Art.21.2.d).';
COMMENT ON COLUMN dipendenza.asset_id IS
    'Nullable: compilare asset_id e/o servizio_id. Il CHECK garantisce che almeno uno sia valorizzato.';

CREATE INDEX idx_dip_org       ON dipendenza (organizzazione_id);
CREATE INDEX idx_dip_fornitore ON dipendenza (fornitore_id);
CREATE INDEX idx_dip_criticita ON dipendenza (criticita);
CREATE INDEX idx_dip_asset     ON dipendenza (asset_id)    WHERE asset_id    IS NOT NULL;
CREATE INDEX idx_dip_servizio  ON dipendenza (servizio_id) WHERE servizio_id IS NOT NULL;


-- ------------------------------------------------------------
-- 3.4  RESPONSABILITA
--      Chi è responsabile di un asset o servizio.
--      Almeno uno tra asset_id e servizio_id deve essere NOT NULL.
-- ------------------------------------------------------------
CREATE TABLE responsabilita (
    id                  SERIAL      PRIMARY KEY,
    persona_id          INT         NOT NULL REFERENCES persona  (id) ON DELETE CASCADE,
    asset_id            INT                  REFERENCES asset    (id) ON DELETE CASCADE,
    servizio_id         INT                  REFERENCES servizio (id) ON DELETE CASCADE,
    tipo_responsabilita VARCHAR(30) NOT NULL
                          CHECK (tipo_responsabilita IN (
                              'proprietario','gestore',
                              'contatto_tecnico','contatto_acn','referente_fornitore'
                          )),
    data_inizio         DATE        NOT NULL DEFAULT CURRENT_DATE,
    data_fine           DATE,
    note                TEXT,
    CONSTRAINT chk_resp_asset_o_servizio
        CHECK (asset_id IS NOT NULL OR servizio_id IS NOT NULL),
    CONSTRAINT chk_date_responsabilita
        CHECK (data_fine IS NULL OR data_fine > data_inizio)
);

CREATE INDEX idx_resp_persona  ON responsabilita (persona_id);
CREATE INDEX idx_resp_asset    ON responsabilita (asset_id)    WHERE asset_id    IS NOT NULL;
CREATE INDEX idx_resp_servizio ON responsabilita (servizio_id) WHERE servizio_id IS NOT NULL;

-- Integrità: un asset/servizio può avere UN SOLO proprietario attivo alla volta.
-- Impedisce righe duplicate nelle viste di profilo e ambiguità di responsabilità.
CREATE UNIQUE INDEX uq_asset_proprietario_attivo
    ON responsabilita (asset_id)
    WHERE tipo_responsabilita = 'proprietario'
      AND data_fine IS NULL
      AND asset_id IS NOT NULL;
CREATE UNIQUE INDEX uq_servizio_proprietario_attivo
    ON responsabilita (servizio_id)
    WHERE tipo_responsabilita = 'proprietario'
      AND data_fine IS NULL
      AND servizio_id IS NOT NULL;


-- ============================================================
-- SEZIONE 4 — AUDIT E SICUREZZA
-- ============================================================

-- ------------------------------------------------------------
-- 4.1  ASSET_STORICO  (audit log immutabile)
-- ------------------------------------------------------------
CREATE TABLE asset_storico (
    id                SERIAL       PRIMARY KEY,
    asset_id          INT          NOT NULL REFERENCES asset (id) ON DELETE CASCADE,
    campo_modificato  VARCHAR(100) NOT NULL,
    valore_precedente TEXT,
    valore_nuovo      TEXT,
    modificato_da     VARCHAR(100),
    modificato_il     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    motivo            VARCHAR(255)
);

COMMENT ON TABLE asset_storico IS
    'Log immutabile delle modifiche agli asset. Popolato dal trigger trg_audit_asset.';

CREATE INDEX idx_storico_asset_ts ON asset_storico (asset_id, modificato_il DESC);


-- ------------------------------------------------------------
-- 4.2  MISURA_SICUREZZA  (Art. 21 NIS2)
-- ------------------------------------------------------------
CREATE TABLE misura_sicurezza (
    id                    SERIAL      PRIMARY KEY,
    organizzazione_id     INT         NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    asset_id              INT                  REFERENCES asset    (id) ON DELETE SET NULL,
    servizio_id           INT                  REFERENCES servizio (id) ON DELETE SET NULL,
    articolo_nis2         VARCHAR(20),          -- es. 'Art.21.2.a'
    categoria             VARCHAR(40) NOT NULL
                            CHECK (categoria IN (
                                'governance','gestione_rischi','incident_response',
                                'continuita_operativa','supply_chain','crittografia',
                                'controllo_accessi','vulnerability_management','altro'
                            )),
    nome                  VARCHAR(255) NOT NULL,
    descrizione           TEXT,
    stato_implementazione VARCHAR(20) NOT NULL DEFAULT 'pianificata'
                            CHECK (stato_implementazione IN (
                                'implementata','in_corso','pianificata','non_applicabile'
                            )),
    data_implementazione  DATE,
    data_verifica         DATE,
    note                  TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN misura_sicurezza.articolo_nis2 IS
    'Riferimento al comma NIS2: Art.21.2.a = MFA, .b = incident response, .i = crittografia, ecc.';

CREATE INDEX idx_misura_org   ON misura_sicurezza (organizzazione_id);
CREATE INDEX idx_misura_stato ON misura_sicurezza (stato_implementazione);


-- ------------------------------------------------------------
-- 4.3  PROFILO_ACN
-- ------------------------------------------------------------
CREATE TABLE profilo_acn (
    id                SERIAL      PRIMARY KEY,
    organizzazione_id INT         NOT NULL REFERENCES organizzazione (id) ON DELETE CASCADE,
    compilato_da_id   INT                  REFERENCES persona (id) ON DELETE SET NULL,
    versione          INT         NOT NULL DEFAULT 1,
    data_compilazione TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    stato             VARCHAR(20) NOT NULL DEFAULT 'bozza'
                        CHECK (stato IN ('bozza','inviato','approvato','da_aggiornare')),
    note              TEXT,
    CONSTRAINT uq_profilo_versione UNIQUE (organizzazione_id, versione)
);

COMMENT ON TABLE profilo_acn IS
    'Snapshot del profilo ACN. Ogni nuovo invio crea una riga con versione incrementale.';

CREATE INDEX idx_profilo_org ON profilo_acn (organizzazione_id);


-- ============================================================
-- SEZIONE 5 — TRIGGER FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- 5.1  fn_audit_asset  — traccia modifiche rilevanti su ASSET
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit_asset()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    -- Autore della modifica: l'applicazione può impostarlo con
    --   SET nis2.utente = 'mario.rossi@org.it';   (o SET LOCAL in transazione)
    -- In assenza, si registra l'utente di database corrente.
    v_utente TEXT := COALESCE(
        NULLIF(current_setting('nis2.utente', TRUE), ''),
        current_user
    );
BEGIN
    -- IS DISTINCT FROM gestisce correttamente anche i valori NULL
    IF NEW.nome IS DISTINCT FROM OLD.nome THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'nome', OLD.nome, NEW.nome, v_utente);
    END IF;
    IF NEW.categoria IS DISTINCT FROM OLD.categoria THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'categoria', OLD.categoria, NEW.categoria, v_utente);
    END IF;
    IF NEW.stato IS DISTINCT FROM OLD.stato THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'stato', OLD.stato, NEW.stato, v_utente);
    END IF;
    IF NEW.tipo_asset_cod IS DISTINCT FROM OLD.tipo_asset_cod THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'tipo_asset_cod', OLD.tipo_asset_cod, NEW.tipo_asset_cod, v_utente);
    END IF;
    IF NEW.sede_id IS DISTINCT FROM OLD.sede_id THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'sede_id', OLD.sede_id::TEXT, NEW.sede_id::TEXT, v_utente);
    END IF;
    -- versione_sw e ip_address sono rilevanti per il tracciamento NIS2
    -- (aggiornamenti software, riconfigurazioni di rete)
    IF NEW.versione_sw IS DISTINCT FROM OLD.versione_sw THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'versione_sw', OLD.versione_sw, NEW.versione_sw, v_utente);
    END IF;
    IF NEW.ip_address IS DISTINCT FROM OLD.ip_address THEN
        INSERT INTO asset_storico (asset_id, campo_modificato, valore_precedente, valore_nuovo, modificato_da)
        VALUES (OLD.id, 'ip_address', OLD.ip_address, NEW.ip_address, v_utente);
    END IF;
    -- updated_at viene aggiornato dal trigger separato trg_updated_asset
    RETURN NEW;
END;
$$;


-- ------------------------------------------------------------
-- 5.2  fn_set_updated_at  — aggiorna updated_at su UPDATE
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


-- ============================================================
-- SEZIONE 6 — TRIGGER DEFINITIONS
-- ============================================================

-- Audit dettagliato su asset (deve precedere updated_at)
CREATE TRIGGER trg_audit_asset
    BEFORE UPDATE ON asset
    FOR EACH ROW EXECUTE FUNCTION fn_audit_asset();

-- updated_at automatico
CREATE TRIGGER trg_updated_asset
    BEFORE UPDATE ON asset
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_updated_organizzazione
    BEFORE UPDATE ON organizzazione
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_updated_servizio
    BEFORE UPDATE ON servizio
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_updated_fornitore
    BEFORE UPDATE ON fornitore
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_updated_persona
    BEFORE UPDATE ON persona
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================================
-- SEZIONE 7 — VISTE PER IL PROFILO ACN
-- ============================================================

-- ------------------------------------------------------------
-- 7.1  v_asset_critici
--      Asset critici/importanti con responsabile e sede.
--      Corrisponde alla sezione "Asset" del profilo ACN.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_asset_critici AS
SELECT
    o.nome                          AS organizzazione,
    o.settore_nis2,
    o.categoria_nis2,
    a.codice_inventario,
    a.nome                          AS asset,
    ta.descrizione                  AS tipo_asset,
    ta.categoria_nis2               AS categoria_tipo,
    a.categoria,
    a.stato,
    a.ip_address,
    a.versione_sw,
    s.nome                          AS sede,
    s.citta,
    CONCAT(p.cognome, ' ', p.nome)  AS responsabile,
    p.email                         AS email_responsabile,
    p.ruolo_organizzativo
FROM asset a
JOIN organizzazione o   ON o.id  = a.organizzazione_id
JOIN tipo_asset ta      ON ta.codice = a.tipo_asset_cod
LEFT JOIN sede s        ON s.id  = a.sede_id
LEFT JOIN responsabilita r
       ON r.asset_id = a.id
      AND r.tipo_responsabilita = 'proprietario'
      AND r.data_fine IS NULL
LEFT JOIN persona p     ON p.id  = r.persona_id
WHERE a.categoria IN ('critico','importante')
  AND a.stato     <> 'dismesso'
  AND a.is_deleted = FALSE
ORDER BY o.nome, a.categoria, a.nome;

COMMENT ON VIEW v_asset_critici IS
    'Asset critici/importanti con proprietario. Usare per la sezione "asset" del profilo ACN.';


-- ------------------------------------------------------------
-- 7.2  v_dipendenze_critiche
--      Dipendenze attive da fornitori terzi con dettaglio SLA.
--      Corrisponde alla sezione "Supply chain" del profilo ACN.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_dipendenze_critiche AS
SELECT
    o.nome                                         AS organizzazione,
    COALESCE(a.nome, sv.nome)                      AS risorsa,
    CASE WHEN d.asset_id IS NOT NULL THEN 'asset'
         ELSE 'servizio' END                       AS tipo_risorsa,
    f.nome                                         AS fornitore,
    f.paese                                        AS paese_fornitore,
    f.tipo                                         AS tipo_fornitore,
    f.is_fornitore_critico,
    d.tipo_dipendenza,
    d.criticita,
    c.numero_contratto,
    c.sla_disponibilita,
    c.include_clausole_sicurezza,
    c.data_scadenza                                AS scadenza_contratto,
    d.data_inizio,
    d.data_fine,
    d.descrizione
FROM dipendenza d
JOIN organizzazione o  ON o.id  = d.organizzazione_id
JOIN fornitore f       ON f.id  = d.fornitore_id
LEFT JOIN asset a      ON a.id  = d.asset_id
LEFT JOIN servizio sv  ON sv.id = d.servizio_id
LEFT JOIN contratto c  ON c.id  = d.contratto_id
WHERE d.data_fine IS NULL
ORDER BY o.nome,
         CASE d.criticita WHEN 'critica' THEN 1 WHEN 'alta' THEN 2
                          WHEN 'media' THEN 3 ELSE 4 END,
         f.nome;

COMMENT ON VIEW v_dipendenze_critiche IS
    'Dipendenze da fornitori terzi ancora attive. Usare per la sezione "supply chain" del profilo ACN.';


-- ------------------------------------------------------------
-- 7.3  v_referenti_acn
--      Referenti ufficiali verso ACN per ogni organizzazione.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_referenti_acn AS
SELECT
    o.nome           AS organizzazione,
    o.settore_nis2,
    o.categoria_nis2,
    o.pec,
    p.cognome,
    p.nome           AS nome_referente,
    p.email,
    p.telefono,
    p.ruolo_organizzativo
FROM persona p
JOIN organizzazione o ON o.id = p.organizzazione_id
WHERE p.is_referente_acn = TRUE
  AND o.attiva = TRUE
ORDER BY o.nome, p.cognome;


-- ------------------------------------------------------------
-- 7.4  v_misure_sicurezza_stato
--      Stato di implementazione delle misure Art.21 NIS2.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_misure_sicurezza_stato AS
SELECT
    o.nome           AS organizzazione,
    ms.articolo_nis2,
    ms.categoria,
    ms.nome          AS misura,
    ms.stato_implementazione,
    ms.data_implementazione,
    ms.data_verifica,
    a.nome           AS asset_collegato,
    sv.nome          AS servizio_collegato
FROM misura_sicurezza ms
JOIN organizzazione o  ON o.id  = ms.organizzazione_id
LEFT JOIN asset a      ON a.id  = ms.asset_id
LEFT JOIN servizio sv  ON sv.id = ms.servizio_id
ORDER BY o.nome,
         CASE ms.stato_implementazione
              WHEN 'pianificata'     THEN 1   -- da affrontare per prime
              WHEN 'in_corso'        THEN 2
              WHEN 'implementata'    THEN 3
              WHEN 'non_applicabile' THEN 4
         END,
         ms.categoria;


-- ------------------------------------------------------------
-- 7.5  v_profilo_acn_export
--      Vista aggregata per l'export del quadro riepilogativo.
--      Una riga per organizzazione; adatta all'export CSV/PDF.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_profilo_acn_export AS
SELECT
    o.id                                                 AS org_id,
    o.nome                                               AS organizzazione,
    o.codice_fiscale,
    o.settore_nis2,
    o.categoria_nis2,
    o.pec,
    -- Ogni contatore è una sottoquery scalare indipendente: nessun prodotto
    -- cartesiano tra le dimensioni (asset, servizi, dipendenze, misure).
    (SELECT COUNT(*) FROM asset a
      WHERE a.organizzazione_id = o.id
        AND a.categoria = 'critico' AND a.is_deleted = FALSE)        AS n_asset_critici,
    (SELECT COUNT(*) FROM asset a
      WHERE a.organizzazione_id = o.id
        AND a.categoria = 'importante' AND a.is_deleted = FALSE)     AS n_asset_importanti,
    (SELECT COUNT(*) FROM servizio sv
      WHERE sv.organizzazione_id = o.id
        AND sv.criticita = 'alta' AND sv.stato = 'attivo')           AS n_servizi_alta_criticita,
    (SELECT COUNT(DISTINCT d.fornitore_id) FROM dipendenza d
      JOIN fornitore f ON f.id = d.fornitore_id
      WHERE d.organizzazione_id = o.id
        AND f.is_fornitore_critico = TRUE AND d.data_fine IS NULL)   AS n_fornitori_critici,
    (SELECT COUNT(*) FROM dipendenza d
      WHERE d.organizzazione_id = o.id
        AND d.criticita IN ('critica','alta') AND d.data_fine IS NULL) AS n_dipendenze_critiche,
    (SELECT COUNT(*) FROM misura_sicurezza ms
      WHERE ms.organizzazione_id = o.id
        AND ms.stato_implementazione = 'implementata')               AS n_misure_implementate,
    (SELECT COUNT(*) FROM misura_sicurezza ms
      WHERE ms.organizzazione_id = o.id
        AND ms.stato_implementazione IN ('in_corso','pianificata'))  AS n_misure_in_corso,
    (SELECT pa.versione FROM profilo_acn pa
      WHERE pa.organizzazione_id = o.id
      ORDER BY pa.versione DESC LIMIT 1)                             AS ultima_versione_profilo,
    (SELECT pa.stato FROM profilo_acn pa
      WHERE pa.organizzazione_id = o.id
      ORDER BY pa.versione DESC LIMIT 1)                             AS stato_profilo
FROM organizzazione o
WHERE o.attiva = TRUE
ORDER BY
    CASE o.categoria_nis2 WHEN 'essenziale' THEN 1 ELSE 2 END,
    o.settore_nis2, o.nome;

COMMENT ON VIEW v_profilo_acn_export IS
    'Quadro riepilogativo NIS2: una riga per organizzazione con tutti i contatori chiave.';


-- ============================================================
-- SEZIONE 8 — DATI
-- ============================================================
-- Questo file contiene SOLO la struttura (DDL) e i dati di
-- riferimento statici (tabella tipo_asset, Sezione 1).
--
-- I dati dimostrativi di business (organizzazioni, asset, servizi,
-- dipendenze, ecc.) sono mantenuti separati nel file:
--
--     nis2_testdata.sql
--
-- Sequenza di installazione:
--     psql -d nis2db -f nis2_schema.sql      -- 1) struttura
--     psql -d nis2db -f nis2_testdata.sql    -- 2) dataset di test
--
-- Questa separazione tiene il DDL versionabile e idempotente,
-- indipendente dal dataset di esempio.
-- ============================================================


-- ============================================================
-- QUERY DI VERIFICA (dopo aver caricato nis2_testdata.sql)
-- ============================================================

-- SELECT * FROM v_asset_critici;
-- SELECT * FROM v_dipendenze_critiche;
-- SELECT * FROM v_referenti_acn;
-- SELECT * FROM v_misure_sicurezza_stato;
-- SELECT * FROM v_profilo_acn_export;
