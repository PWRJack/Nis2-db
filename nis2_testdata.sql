-- ============================================================
-- NIS2 / ACN — Dataset di Test
-- Eseguire DOPO nis2_schema.sql  (PostgreSQL 14+)
-- ============================================================
-- 5 organizzazioni  (Energia · Cloud · Sanità · Trasporti · Bancario)
-- 10 sedi
-- 15 persone / referenti
-- 10 fornitori terzi
-- 29 asset  (hardware, software, OT/ICS, cloud, dati)
-- 15 servizi erogati
-- 20 associazioni asset ↔ servizio
-- 12 contratti
-- 20 dipendenze da fornitori
-- 22 responsabilità assegnate
-- 10 modifiche storiche (audit log)
-- 25 misure di sicurezza Art.21 NIS2
--  6 profili ACN
-- Totale: ~209 record
-- ============================================================

BEGIN;

-- ============================================================
-- PULIZIA — svuota le tabelle e azzera le sequenze
-- ============================================================
TRUNCATE TABLE
    profilo_acn, misura_sicurezza, asset_storico,
    responsabilita, dipendenza, contratto, asset_servizio,
    servizio, asset,
    persona, fornitore,
    sede, organizzazione, tipo_asset
RESTART IDENTITY CASCADE;


-- ============================================================
-- SEZIONE 1 — TIPO_ASSET  (lookup, PK testuale)
-- ============================================================
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
-- SEZIONE 2 — ORGANIZZAZIONE
-- 5 soggetti NIS2: 3 essenziali (Annex I), 2 importanti (Annex II)
-- ============================================================
INSERT INTO organizzazione
    (id, nome, codice_fiscale, settore_nis2, categoria_nis2,
     pec, sito_web, data_registrazione_acn)
VALUES
    (1, 'Alfa Energia S.p.A.',
     '01234567890', 'Energia',                 'essenziale',
     'alfa-energia@pec.it',       'https://www.alfa-energia.it',     '2024-01-15'),

    (2, 'BetaCloud S.r.l.',
     '09876543210', 'Infrastrutture digitali', 'importante',
     'betacloud@legalmail.it',    'https://www.betacloud.it',         '2024-03-01'),

    (3, 'Ospedale Regionale Nord',
     '05544332210', 'Sanità',                  'essenziale',
     'ospedaleregionale@pec.it',  'https://www.ospedaleregionale.it', '2024-02-10'),

    (4, 'TransLogistica S.p.A.',
     '07788991122', 'Trasporti',               'essenziale',
     'translogistica@pec.it',     'https://www.translogistica.it',    '2024-04-05'),

    (5, 'BancaMetro S.p.A.',
     '03322114455', 'Bancario',                'essenziale',
     'bancametro@pec-banche.it',  'https://www.bancametro.it',        '2024-01-20');


-- ============================================================
-- SEZIONE 3 — SEDE (10 sedi)
-- ============================================================
INSERT INTO sede
    (id, organizzazione_id, nome, indirizzo, citta, cap, paese, is_sede_principale)
VALUES
    -- Alfa Energia
    ( 1, 1, 'Sede Centrale',           'Via dell''Energia 1',    'Milano',  '20121', 'IT', TRUE),
    ( 2, 1, 'Data Center Nord',        'Via Industria 42',       'Torino',  '10123', 'IT', FALSE),
    -- BetaCloud
    ( 3, 2, 'Headquarters BetaCloud',  'Via della Nuvola 7',     'Roma',    '00185', 'IT', TRUE),
    -- Ospedale
    ( 4, 3, 'Presidio Ospedaliero',    'Viale dei Mille 10',     'Bergamo', '24121', 'IT', TRUE),
    ( 5, 3, 'CED Ospedaliero',         'Via Locatelli 20',       'Bergamo', '24123', 'IT', FALSE),
    -- TransLogistica
    ( 6, 4, 'Sede Operativa Bologna',  'Via Zanardi 100',        'Bologna', '40131', 'IT', TRUE),
    ( 7, 4, 'Hub Intermodale Nord',    'Strada Rivoltana 5',     'Segrate', '20054', 'IT', FALSE),
    -- BancaMetro
    ( 8, 5, 'Sede Direzionale',        'Piazza De Ferrari 3',    'Genova',  '16121', 'IT', TRUE),
    ( 9, 5, 'Data Center DR',          'Zona Industriale Est 1', 'Bari',    '70132', 'IT', FALSE),
    (10, 5, 'Filiale Principale',      'Corso Buenos Aires 12',  'Milano',  '20124', 'IT', FALSE);


-- ============================================================
-- SEZIONE 4 — PERSONA (15 referenti, 3 per organizzazione)
-- ============================================================
INSERT INTO persona
    (id, organizzazione_id, nome, cognome, email,
     telefono, ruolo_organizzativo, is_referente_acn)
VALUES
    -- Alfa Energia (org 1)
    ( 1, 1, 'Marco',     'Rossi',    'marco.rossi@alfa-energia.it',       '+39 02 1234 5001', 'CISO',            TRUE),
    ( 2, 1, 'Giulia',    'Bianchi',  'giulia.bianchi@alfa-energia.it',    '+39 02 1234 5002', 'Referente_NIS2',  FALSE),
    ( 3, 1, 'Paolo',     'Ferrari',  'paolo.ferrari@alfa-energia.it',     '+39 02 1234 5003', 'Admin_Sistema',   FALSE),
    -- BetaCloud (org 2)
    ( 4, 2, 'Lorenzo',   'Verdi',    'l.verdi@betacloud.it',              '+39 06 9876 4001', 'Referente_ACN',   TRUE),
    ( 5, 2, 'Sara',      'Colombo',  's.colombo@betacloud.it',            '+39 06 9876 4002', 'CISO',            FALSE),
    ( 6, 2, 'Matteo',    'Ricci',    'm.ricci@betacloud.it',              '+39 06 9876 4003', 'CTO',             FALSE),
    -- Ospedale (org 3)
    ( 7, 3, 'Francesca', 'Moretti',  'f.moretti@ospedaleregionale.it',    '+39 035 5544 001', 'Referente_ACN',   TRUE),
    ( 8, 3, 'Andrea',    'Conti',    'a.conti@ospedaleregionale.it',      '+39 035 5544 002', 'CISO',            FALSE),
    ( 9, 3, 'Luca',      'Fontana',  'l.fontana@ospedaleregionale.it',    '+39 035 5544 003', 'DPO',             FALSE),
    -- TransLogistica (org 4)
    (10, 4, 'Valentina', 'Romano',   'v.romano@translogistica.it',        '+39 051 7788 001', 'Referente_ACN',   TRUE),
    (11, 4, 'Roberto',   'Esposito', 'r.esposito@translogistica.it',      '+39 051 7788 002', 'Responsabile_IT', FALSE),
    (12, 4, 'Chiara',    'Russo',    'c.russo@translogistica.it',         '+39 051 7788 003', 'CISO',            FALSE),
    -- BancaMetro (org 5)
    (13, 5, 'Giorgio',   'Mancini',  'g.mancini@bancametro.it',           '+39 010 3322 001', 'Referente_ACN',   TRUE),
    (14, 5, 'Elena',     'Gallo',    'e.gallo@bancametro.it',             '+39 010 3322 002', 'CISO',            FALSE),
    (15, 5, 'Federico',  'Bruno',    'f.bruno@bancametro.it',             '+39 010 3322 003', 'DPO',             FALSE);


-- ============================================================
-- SEZIONE 5 — FORNITORE (10 fornitori terzi)
-- ============================================================
INSERT INTO fornitore
    (id, nome, codice_fiscale_vat, paese, tipo, is_fornitore_critico, sito_web)
VALUES
    ( 1, 'Microsoft Azure Corp.',          'EU826009064',   'US', 'cloud',        TRUE,  'https://azure.microsoft.com'),
    ( 2, 'IndustrialSoft S.r.l.',          '02233445566',   'IT', 'sw_vendor',    TRUE,  'https://www.industrialsoft.it'),
    ( 3, 'TelecomITA S.p.A.',              '00488410010',   'IT', 'tlc',          FALSE, 'https://www.telecomita.it'),
    ( 4, 'Amazon Web Services EMEA S.r.l.','EU372001951',   'IE', 'cloud',        TRUE,  'https://aws.amazon.com'),
    ( 5, 'SierraSW Healthcare S.p.A.',     '08877665544',   'IT', 'sw_vendor',    TRUE,  'https://www.sierrasw-health.it'),
    ( 6, 'IBM Italia S.p.A.',              '01083700150',   'IT', 'sw_vendor',    TRUE,  'https://www.ibm.com/it-it'),
    ( 7, 'SecureNetworks S.r.l.',          '09988776655',   'IT', 'manutenzione', FALSE, 'https://www.securenetworks.it'),
    ( 8, 'SAP Italia S.r.l.',              'IT02132840153', 'IT', 'sw_vendor',    FALSE, 'https://www.sap.com/italy'),
    ( 9, 'ConnectFiber S.p.A.',            '11223344556',   'IT', 'tlc',          FALSE, 'https://www.connectfiber.it'),
    (10, 'SWIFT scrl',                     'BE0413330856',  'BE', 'sw_vendor',    TRUE,  'https://www.swift.com');


-- ============================================================
-- SEZIONE 6 — ASSET (29 asset su 5 organizzazioni)
-- ============================================================
INSERT INTO asset
    (id, organizzazione_id, sede_id, tipo_asset_cod, codice_inventario,
     nome, descrizione, categoria, stato, ip_address, versione_sw)
VALUES

-- == ORG 1: Alfa Energia (6 asset — settore Energia / OT) ===============
( 1, 1, 2, 'SERVER_FISICO',  'INV-AE-001',
  'SCADA Server Primario',
  'Server principale per supervisione e controllo della rete di distribuzione gas.',
  'critico',    'attivo', '10.0.1.10',  'SCADA 6.2.1'),

( 2, 1, 2, 'OT_ICS',         'INV-AE-002',
  'PLC Controllo Rete Gas',
  'Controllore Siemens S7-1500 a presidio delle valvole di intercettazione gas.',
  'critico',    'attivo',  NULL,         'Siemens S7-1500 FW3.1'),

( 3, 1, 1, 'RETE',           'INV-AE-003',
  'Firewall Perimetrale NGT',
  'Palo Alto PA-5250 a protezione del perimetro OT/IT. Gestito da SecureNetworks.',
  'importante', 'attivo', '10.0.0.1',   'PAN-OS 11.1.2'),

( 4, 1, 2, 'DATABASE',       'INV-AE-004',
  'DB Telemetria SCADA',
  'PostgreSQL che raccoglie la telemetria in real-time dai sensori di campo.',
  'critico',    'attivo', '10.0.1.20',  'PostgreSQL 15.4'),

( 5, 1, 1, 'APPLICAZIONE',   'INV-AE-005',
  'Portale Clienti Online',
  'Applicazione web per gestione utenze, fatturazione e autoletture.',
  'importante', 'attivo', '10.0.2.20',  'Node.js 20 LTS'),

( 6, 1, 1, 'WORKSTATION',    'INV-AE-006',
  'Postazioni Operatore Sala Controllo',
  'Parco 8 workstation dedicate agli operatori della sala controllo OT.',
  'standard',   'attivo',  NULL,         'Windows 11 Enterprise'),

-- == ORG 2: BetaCloud (6 asset — settore Infrastrutture digitali) ========
( 7, 2, 3, 'SERVER_VIRTUALE','INV-BC-001',
  'API Gateway Prod',
  'Kong 3.4 come unico punto di ingresso per tutte le API esposte ai clienti B2B.',
  'critico',    'attivo', '10.1.0.5',   'Kong 3.4'),

( 8, 2, 3, 'SERVER_VIRTUALE','INV-BC-002',
  'Cluster Kubernetes Prod',
  'Azure AKS 8 nodi che ospita i microservizi della piattaforma B2B.',
  'critico',    'attivo', '10.1.0.10',  'Kubernetes 1.29'),

( 9, 2, 3, 'DATABASE',       'INV-BC-003',
  'PostgreSQL Prod',
  'DB relazionale principale con replica sincrona su availability zone secondaria.',
  'critico',    'attivo', '10.1.1.5',   'PostgreSQL 16.1'),

(10, 2, 3, 'RETE',           'INV-BC-004',
  'CDN Load Balancer',
  'Azure Front Door + Load Balancer per bilanciamento e CDN della piattaforma.',
  'importante', 'attivo', '10.1.0.1',   'Azure Front Door v2'),

(11, 2, 3, 'DATO',           'INV-BC-005',
  'Storage Dati Clienti S3',
  'Azure Blob Storage cifrato AES-256: dati contrattuali e analytics dei clienti.',
  'critico',    'attivo',  NULL,          NULL),

(12, 2, 3, 'APPLICAZIONE',   'INV-BC-006',
  'Dashboard Monitoraggio Infra',
  'Grafana + Prometheus per il monitoraggio interno dell''infrastruttura cloud.',
  'standard',   'attivo', '10.1.2.1',   'Grafana 10.2'),

-- == ORG 3: Ospedale Regionale Nord (6 asset — settore Sanità) ===========
(13, 3, 5, 'SERVER_FISICO',  'INV-OR-001',
  'Server HIS — Hospital Info System',
  'Server primario che ospita il sistema informativo ospedaliero Meditech Expanse.',
  'critico',    'attivo', '172.16.1.10', 'Meditech Expanse 2.1'),

(14, 3, 5, 'SERVER_FISICO',  'INV-OR-002',
  'Server PACS Radiologia',
  'Server PACS per archiviazione e distribuzione immagini diagnostiche DICOM.',
  'critico',    'attivo', '172.16.1.11', 'Horos PACS 3.3.6 / DICOM 3.0'),

(15, 3, 5, 'DATABASE',       'INV-OR-003',
  'DB Pazienti e Cartelle Cliniche',
  'Oracle DB con intera storia clinica dei pazienti. Dati particolari ex Art.9 GDPR.',
  'critico',    'attivo', '172.16.1.20', 'Oracle DB 19c'),

(16, 3, 4, 'APPLICAZIONE',   'INV-OR-004',
  'CCE — Cartella Clinica Elettronica',
  'Applicazione Meditech CCE accessibile da tutti i reparti per la gestione clinica.',
  'critico',    'attivo', '172.16.2.10', 'Meditech CCE 4.2'),

(17, 3, 4, 'RETE',           'INV-OR-005',
  'Rete Medica Segregata VLAN-100',
  'Segmento di rete dedicato ai dispositivi medici, segregato dalla rete amministrativa.',
  'importante', 'attivo',  NULL,          'Cisco Catalyst IOS-XE 17.9'),

(18, 3, 4, 'OT_ICS',         'INV-OR-006',
  'Dispositivi IoMT (Infusori, Monitor Pz.)',
  'Parco 120 dispositivi medicali connessi: pompe infusori e monitor parametri vitali.',
  'importante', 'attivo',  NULL,          'Firmware misto — gestione vendor SierraSW'),

-- == ORG 4: TransLogistica (5 asset — settore Trasporti) =================
(19, 4, 6, 'SERVER_FISICO',  'INV-TL-001',
  'Server Gestione Flotta',
  'Server applicativo che ospita FleetMaster, il sistema di gestione flotta camionistica.',
  'critico',    'attivo', '192.168.1.10', 'FleetMaster 3.1'),

(20, 4, 6, 'APPLICAZIONE',   'INV-TL-002',
  'Sistema GPS Fleet Tracking',
  'Piattaforma SaaS FleetMaster GPS per il tracking real-time di 450 veicoli.',
  'critico',    'attivo', '192.168.1.20', 'FleetMaster GPS 3.1'),

(21, 4, 6, 'DATABASE',       'INV-TL-003',
  'DB WMS Magazzino',
  'SAP WM: gestione giacenze e movimenti di magazzino per gli hub logistici.',
  'importante', 'attivo', '192.168.1.30', 'SAP WM 7.5 EHP8'),

(22, 4, 7, 'RETE',           'INV-TL-004',
  'Rete Operativa Hub Bologna',
  'Router, switch, AP e firewall dell''hub intermodale di Segrate.',
  'importante', 'attivo', '192.168.1.1',  'Juniper JunOS 23.1'),

(23, 4, 7, 'WORKSTATION',    'INV-TL-005',
  'Terminali RF Magazzino (parco 20 unità)',
  'Zebra TC52 per gestione movimenti magazzino via barcode e RFID.',
  'standard',   'attivo',  NULL,           'Android 13 / Zebra DataWedge'),

-- == ORG 5: BancaMetro (6 asset — settore Bancario) =====================
(24, 5, 8, 'SERVER_FISICO',  'INV-BM-001',
  'Core Banking Server Primario',
  'Mainframe IBM z16 che esegue il core banking. Ridondato su DC-DR Bari.',
  'critico',    'attivo', '10.10.1.10',  'IBM z/OS 3.1'),

(25, 5, 8, 'DATABASE',       'INV-BM-002',
  'DB Transazioni OLTP',
  'IBM Db2 for z/OS — gestisce milioni di transazioni giornaliere con ACID completo.',
  'critico',    'attivo', '10.10.1.20',  'IBM Db2 12.1'),

(26, 5,10, 'APPLICAZIONE',   'INV-BM-003',
  'Sistema PSD2 Open Banking',
  'Backend OpenBankProject per esposizione API PSD2/XS2A ai Third Party Providers.',
  'critico',    'attivo', '10.10.2.10',  'OpenBankProject 4.2 / PSD2 2.0'),

(27, 5, 8, 'RETE',           'INV-BM-004',
  'Rete SWIFT Interbancaria',
  'Infrastruttura dedicata per il collegamento alla rete SWIFT Alliance Access 7.4.',
  'critico',    'attivo', '10.10.0.1',   'SWIFT Alliance Access 7.4'),

(28, 5, 8, 'FISICO',         'INV-BM-005',
  'HSM — Hardware Security Module nShield',
  'Thales nShield Connect XC per gestione chiavi crittografiche di firma e cifratura.',
  'critico',    'attivo',  NULL,           'Thales nShield FW 12.80'),

(29, 5,10, 'APPLICAZIONE',   'INV-BM-006',
  'Sistema Antifrode Real-Time',
  'Motore ML rilevamento frodi in real-time: analizza ogni transazione in <50 ms.',
  'importante', 'attivo', '10.10.2.20',  'FICO Falcon 9.1');


-- ============================================================
-- SEZIONE 7 — SERVIZIO (15 servizi, 3 per organizzazione)
-- ============================================================
INSERT INTO servizio
    (id, organizzazione_id, nome, descrizione,
     tipo_servizio, criticita, stato, rto_ore, rpo_ore, url_servizio)
VALUES
    -- Alfa Energia (org 1)
    ( 1, 1, 'Distribuzione Energia Elettrica',
      'Servizio essenziale di distribuzione energia alla rete nazionale. Soggetto a obblighi ACN.',
      'essenziale', 'alta',  'attivo',  4,  1,  NULL),
    ( 2, 1, 'Monitoraggio SCADA',
      'Supervisione e controllo real-time degli impianti tramite SCADA. H24 365gg.',
      'essenziale', 'alta',  'attivo',  2,  0,  NULL),
    ( 3, 1, 'Portale Clienti Online',
      'Servizio digitale per gestione utenze, bollette e autoletture.',
      'digitale',   'media', 'attivo', 24,  4,  'https://clienti.alfa-energia.it'),

    -- BetaCloud (org 2)
    ( 4, 2, 'Piattaforma Cloud B2B',
      'Infrastruttura cloud gestita erogata a clienti enterprise. Core business di BetaCloud.',
      'digitale',   'alta',  'attivo',  8,  4,  'https://cloud.betacloud.it'),
    ( 5, 2, 'API Management Service',
      'Gestione, sicurezza e monitoraggio delle API per clienti B2B e integrazioni.',
      'digitale',   'alta',  'attivo',  4,  1,  'https://api.betacloud.it'),
    ( 6, 2, 'Servizio Backup e DR',
      'Backup giornaliero e disaster recovery su infrastruttura georedondante Azure + AWS.',
      'interno',    'bassa', 'attivo', 48, 24,   NULL),

    -- Ospedale Regionale Nord (org 3)
    ( 7, 3, 'Gestione Cartelle Cliniche Elettroniche',
      'Accesso e gestione CCE da medici e infermieri in tutti i reparti. H24.',
      'essenziale', 'alta',  'attivo',  4,  1,  NULL),
    ( 8, 3, 'Servizi Radiologia Digitale PACS',
      'Acquisizione, archiviazione e refertazione immagini diagnostiche (RX, TAC, RM).',
      'essenziale', 'alta',  'attivo',  8,  2,  NULL),
    ( 9, 3, 'Prenotazione Online Prestazioni',
      'Portale web e app per prenotazione visite ed esami da parte dei pazienti.',
      'digitale',   'media', 'attivo', 24, 12,  'https://prenotazioni.ospedaleregionale.it'),

    -- TransLogistica (org 4)
    (10, 4, 'Tracking Flotta e Spedizioni',
      'Tracking GPS real-time di 450 veicoli e visibilità spedizioni per i clienti.',
      'essenziale', 'alta',  'attivo',  4,  1,  'https://track.translogistica.it'),
    (11, 4, 'Gestione Magazzino WMS',
      'Sistema WMS per gestione giacenze, picking e spedizioni degli hub logistici.',
      'essenziale', 'alta',  'attivo',  8,  2,  NULL),
    (12, 4, 'Portale B2B Clienti Logistici',
      'Self-service clienti: ordini, tracking, documenti di trasporto e fatture.',
      'digitale',   'media', 'attivo', 24,  8,  'https://business.translogistica.it'),

    -- BancaMetro (org 5)
    (13, 5, 'Core Banking e Transazioni',
      'Gestione conti, transazioni, bonifici e regolamento. Servizio essenziale H24.',
      'essenziale', 'alta',  'attivo',  2,  0,  NULL),
    (14, 5, 'Open Banking PSD2',
      'Esposizione API XS2A/PSD2 ai TPP autorizzati da Banca d''Italia. Obbligo normativo.',
      'essenziale', 'alta',  'attivo',  4,  1,  'https://openbanking.bancametro.it'),
    (15, 5, 'Home Banking Retail',
      'Internet banking e app mobile per clienti retail: pagamenti, bonifici, estratto conto.',
      'digitale',   'alta',  'attivo',  4,  2,  'https://homebanking.bancametro.it');


-- ============================================================
-- SEZIONE 8 — ASSET_SERVIZIO (20 associazioni N:M)
-- ============================================================
INSERT INTO asset_servizio (asset_id, servizio_id, ruolo, data_inizio) VALUES
    -- Alfa Energia
    ( 1,  1, 'elabora_dati',  '2022-01-01'),  -- SCADA Server      → Distribuzione Energia
    ( 1,  2, 'supporta',      '2022-01-01'),  -- SCADA Server      → Monitoraggio SCADA
    ( 2,  2, 'elabora_dati',  '2022-01-01'),  -- PLC Gas           → Monitoraggio SCADA
    ( 4,  1, 'elabora_dati',  '2022-01-01'),  -- DB Telemetria     → Distribuzione Energia
    ( 4,  2, 'elabora_dati',  '2022-01-01'),  -- DB Telemetria     → Monitoraggio SCADA
    ( 5,  3, 'ospita',        '2023-06-01'),  -- Portale           → Portale Clienti Online
    -- BetaCloud
    ( 7,  5, 'supporta',      '2024-01-01'),  -- API Gateway       → API Management
    ( 8,  4, 'ospita',        '2024-01-01'),  -- Kubernetes        → Piattaforma Cloud B2B
    ( 9,  4, 'elabora_dati',  '2024-01-01'),  -- PostgreSQL        → Piattaforma Cloud B2B
    (11,  6, 'ospita',        '2023-01-01'),  -- Storage S3        → Backup e DR
    -- Ospedale
    (13,  7, 'ospita',        '2021-01-01'),  -- Server HIS        → Gestione CCE
    (14,  8, 'ospita',        '2021-01-01'),  -- Server PACS       → Radiologia
    (15,  7, 'elabora_dati',  '2021-01-01'),  -- DB Pazienti       → Gestione CCE
    (16,  7, 'supporta',      '2021-01-01'),  -- App CCE           → Gestione CCE
    -- TransLogistica
    (19, 10, 'supporta',      '2022-06-01'),  -- Server Flotta     → Tracking Flotta
    (20, 10, 'supporta',      '2022-06-01'),  -- GPS Fleet App     → Tracking Flotta
    (21, 11, 'elabora_dati',  '2022-06-01'),  -- DB WMS            → Gestione WMS
    -- BancaMetro
    (24, 13, 'ospita',        '2019-01-01'),  -- Core Banking Srv  → Core Banking svc
    (25, 13, 'elabora_dati',  '2019-01-01'),  -- DB Transazioni    → Core Banking svc
    (26, 14, 'supporta',      '2022-09-01');  -- App PSD2          → Open Banking PSD2


-- ============================================================
-- SEZIONE 9 — CONTRATTO (12 contratti)
-- ============================================================
INSERT INTO contratto
    (id, organizzazione_id, fornitore_id, numero_contratto,
     data_inizio, data_scadenza, oggetto,
     sla_disponibilita, include_clausole_sicurezza, valore_annuo_eur)
VALUES
    -- Alfa Energia
    ( 1, 1, 1, 'CTR-AE-2024-001', '2024-01-01', '2026-12-31',
      'Microsoft Azure IaaS/PaaS per infrastruttura SCADA cloud-hybrid',
      99.95,  TRUE,  180000.00),
    ( 2, 1, 2, 'CTR-AE-2024-002', '2024-03-01', '2025-02-28',
      'Manutenzione correttiva ed evolutiva piattaforma SCADA IndustrialSoft v6',
      99.50,  TRUE,   95000.00),
    ( 3, 1, 3, 'CTR-AE-2022-003', '2022-01-01', '2025-12-31',
      'Connettività WAN dedicata MPLS tra Sede Centrale e Data Center Nord',
      99.90,  FALSE,  48000.00),
    -- BetaCloud
    ( 4, 2, 1, 'CTR-BC-2024-001', '2024-06-01', '2027-05-31',
      'Azure compute, networking e storage per piattaforma BetaCloud B2B',
      99.99,  TRUE,  520000.00),
    ( 5, 2, 4, 'CTR-BC-2023-002', '2023-01-01', '2025-12-31',
      'Amazon Web Services EMEA — backup georedondante su AWS eu-south-1',
      99.95,  TRUE,   86000.00),
    -- Ospedale
    ( 6, 3, 5, 'CTR-OR-2023-001', '2023-06-01', '2026-05-31',
      'Licenze, manutenzione e supporto H24 Meditech Expanse (HIS + PACS + CCE)',
      99.00,  TRUE,  310000.00),
    ( 7, 3, 3, 'CTR-OR-2021-002', '2021-01-01', '2025-12-31',
      'Fibra dedicata TelecomITA: CED ospedaliero → rete GARR e WAN interospedaliera',
      99.50,  FALSE,  36000.00),
    -- TransLogistica
    ( 8, 4, 8, 'CTR-TL-2023-001', '2023-04-01', '2026-03-31',
      'Licenze SAP WM e supporto applicativo per sistema WMS logistico',
      99.00,  FALSE, 145000.00),
    ( 9, 4, 9, 'CTR-TL-2022-002', '2022-01-01', '2025-12-31',
      'Connettività ConnectFiber: fibra dedicata e connessioni hub intermodale',
      99.80,  FALSE,  28000.00),
    -- BancaMetro
    (10, 5, 6, 'CTR-BM-2023-001', '2023-01-01', '2026-12-31',
      'IBM: manutenzione mainframe z16, licenze z/OS 3.1 e Db2 12.1, supporto 24/7',
      99.999, TRUE,  980000.00),
    (11, 5,10, 'CTR-BM-2020-002', '2020-01-01', '2025-12-31',
      'SWIFT Alliance Access: licenze di connessione alla rete interbancaria globale',
      99.99,  TRUE,  220000.00),
    (12, 5, 7, 'CTR-BM-2024-003', '2024-09-01', '2027-08-31',
      'SecureNetworks: gestione HSM, PKI e servizi di crittografia managed',
      99.90,  TRUE,   75000.00);


-- ============================================================
-- SEZIONE 10 — DIPENDENZA (20 dipendenze da fornitori terzi)
-- CHECK: (asset_id IS NOT NULL OR servizio_id IS NOT NULL)
-- ============================================================
INSERT INTO dipendenza
    (id, organizzazione_id, asset_id, servizio_id,
     fornitore_id, contratto_id, tipo_dipendenza, criticita,
     descrizione, data_inizio)
VALUES
    -- Alfa Energia ------------------------------------------------
    ( 1, 1,  1, NULL,  1,  1, 'iaas',         'alta',
      'SCADA Server Primario ospitato su VM Azure (componente cloud-hybrid).',
      '2024-01-01'),
    ( 2, 1, NULL,  2,  2,  2, 'manutenzione', 'critica',
      'Manutenzione correttiva e supporto H24 del software SCADA IndustrialSoft.',
      '2024-03-01'),
    ( 3, 1,  4, NULL,  2,  2, 'licenza',      'alta',
      'Licenza del modulo PostgreSQL customizzato IndustrialSoft per telemetria.',
      '2024-03-01'),
    ( 4, 1, NULL,  1,  3,  3, 'connettivita', 'alta',
      'Link WAN MPLS TelecomITA necessario per continuità del servizio distribuzione.',
      '2022-01-01'),
    -- BetaCloud ---------------------------------------------------
    ( 5, 2,  8, NULL,  1,  4, 'iaas',         'critica',
      'Cluster Kubernetes interamente su Azure AKS: dipendenza infrastrutturale totale.',
      '2024-06-01'),
    ( 6, 2, NULL,  4,  1,  4, 'paas',         'critica',
      'Piattaforma Cloud B2B usa Azure PaaS (AppService, ServiceBus, KeyVault).',
      '2024-06-01'),
    ( 7, 2, NULL,  5,  1,  4, 'hosting',      'alta',
      'API Gateway su Azure Container Apps: hosting e scalabilità gestiti.',
      '2024-06-01'),
    ( 8, 2, 11, NULL,  4,  5, 'hosting',      'media',
      'AWS S3 come destinazione georedondante del backup dati clienti.',
      '2023-01-01'),
    -- Ospedale ----------------------------------------------------
    ( 9, 3, NULL,  7,  5,  6, 'licenza',      'critica',
      'Licenze Meditech CCE indispensabili per l''operatività clinica H24.',
      '2023-06-01'),
    (10, 3, NULL,  8,  5,  6, 'supporto',     'critica',
      'Supporto H24 SierraSW per PACS: SLA garantito per imaging diagnostico.',
      '2023-06-01'),
    (11, 3, 13, NULL,  5,  6, 'manutenzione', 'alta',
      'Manutenzione HW e SW del Server HIS inclusa nel contratto SierraSW.',
      '2023-06-01'),
    (12, 3, NULL,  7,  3,  7, 'connettivita', 'alta',
      'Fibra TelecomITA come backbone per il CCE accessibile da tutti i reparti.',
      '2021-01-01'),
    -- TransLogistica ----------------------------------------------
    (13, 4, NULL, 11,  8,  8, 'saas',         'alta',
      'SAP WM in modalità SaaS per la gestione magazzino: dipendenza applicativa diretta.',
      '2023-04-01'),
    (14, 4, 20, NULL,  8,  8, 'licenza',      'media',
      'Licenza FleetMaster GPS integrata con SAP WM per sincronizzazione ordini.',
      '2023-04-01'),
    (15, 4, NULL, 10,  9,  9, 'connettivita', 'alta',
      'Connettività ConnectFiber per trasmissione dati GPS flotta → hub.',
      '2022-01-01'),
    -- BancaMetro --------------------------------------------------
    (16, 5, 24, NULL,  6, 10, 'manutenzione', 'critica',
      'IBM: manutenzione mainframe z16 e supporto z/OS. Fermo = blocco transazioni.',
      '2023-01-01'),
    (17, 5, 25, NULL,  6, 10, 'supporto',     'critica',
      'IBM supporto Db2 for z/OS: patch di sicurezza e ottimizzazione query.',
      '2023-01-01'),
    (18, 5, NULL, 13,  6, 10, 'hosting',      'critica',
      'Core Banking gira su infrastruttura IBM: dipendenza infrastrutturale totale.',
      '2023-01-01'),
    (19, 5, 27, NULL, 10, 11, 'connettivita', 'critica',
      'SWIFT Alliance Access: rete interbancaria globale, indispensabile per i bonifici.',
      '2020-01-01'),
    (20, 5, 28, NULL,  7, 12, 'manutenzione', 'critica',
      'SecureNetworks gestisce HSM e intera PKI bancaria: criticità massima.',
      '2024-09-01');


-- ============================================================
-- SEZIONE 11 — RESPONSABILITA (22 assegnazioni)
-- CHECK: (asset_id IS NOT NULL OR servizio_id IS NOT NULL)
-- ============================================================
INSERT INTO responsabilita
    (id, persona_id, asset_id, servizio_id, tipo_responsabilita, data_inizio)
VALUES
    -- Alfa Energia
    ( 1,  1,  1, NULL, 'proprietario',     '2022-01-01'),  -- Rossi (CISO)   → SCADA Server
    ( 2,  1,  2, NULL, 'proprietario',     '2022-01-01'),  -- Rossi          → PLC Gas
    ( 3,  1,  4, NULL, 'proprietario',     '2022-01-01'),  -- Rossi          → DB Telemetria
    ( 4,  3,  1, NULL, 'contatto_tecnico', '2022-01-01'),  -- Ferrari        → SCADA Server
    ( 5,  3,  3, NULL, 'gestore',          '2023-01-01'),  -- Ferrari        → Firewall
    ( 6,  2, NULL,  1, 'gestore',          '2022-01-01'),  -- Bianchi (NIS2) → Distrib. Energia
    ( 7,  2, NULL,  2, 'gestore',          '2022-01-01'),  -- Bianchi        → Monit. SCADA
    -- BetaCloud
    ( 8,  6,  7, NULL, 'proprietario',     '2024-01-01'),  -- Ricci (CTO)    → API Gateway
    ( 9,  6,  8, NULL, 'proprietario',     '2024-01-01'),  -- Ricci          → Kubernetes
    (10,  5, NULL,  4, 'gestore',          '2024-01-01'),  -- Colombo (CISO) → Cloud B2B
    (11,  4, NULL,  5, 'proprietario',     '2024-01-01'),  -- Verdi (ACN)    → API Mgmt
    -- Ospedale
    (12,  8, 13, NULL, 'proprietario',     '2021-01-01'),  -- Conti (CISO)   → Server HIS
    (13,  8, 14, NULL, 'proprietario',     '2021-01-01'),  -- Conti          → Server PACS
    (14,  9, 15, NULL, 'gestore',          '2021-01-01'),  -- Fontana (DPO)  → DB Pazienti
    (15,  7, NULL,  7, 'proprietario',     '2021-01-01'),  -- Moretti (ACN)  → Gestione CCE
    (16,  7, NULL,  8, 'proprietario',     '2021-01-01'),  -- Moretti        → Radiologia
    -- TransLogistica
    (17, 11, 19, NULL, 'proprietario',     '2022-06-01'),  -- Esposito       → Server Flotta
    (18, 11, 20, NULL, 'gestore',          '2022-06-01'),  -- Esposito       → GPS Tracking
    (19, 10, NULL, 10, 'proprietario',     '2022-06-01'),  -- Romano (ACN)   → Fleet Tracking
    (20, 12, NULL, 11, 'gestore',          '2022-06-01'),  -- Russo (CISO)   → WMS
    -- BancaMetro
    (21, 14, 24, NULL, 'proprietario',     '2019-01-01'),  -- Gallo (CISO)   → Core Banking Srv
    (22, 13, NULL, 13, 'proprietario',     '2019-01-01');  -- Mancini (ACN)  → Core Banking svc


-- ============================================================
-- SEZIONE 12 — ASSET_STORICO (10 modifiche storiche simulate)
-- Nota: in produzione questo log è popolato automaticamente
--       dal trigger trg_audit_asset; qui i dati sono pre-caricati
--       per coprire casistiche di test sulle viste e query.
-- ============================================================
INSERT INTO asset_storico
    (id, asset_id, campo_modificato,
     valore_precedente, valore_nuovo,
     modificato_da, modificato_il, motivo)
VALUES
    ( 1,  2, 'categoria',
      'importante',           'critico',
      'marco.rossi@alfa-energia.it',     '2023-08-15 09:12:00+02',
      'Rivalutazione rischio post-analisi OT: impatto elevato su infrastruttura critica'),

    ( 2,  1, 'stato',
      'in_manutenzione',      'attivo',
      'sistema_automatico',              '2024-01-10 06:30:00+01',
      'Fine manutenzione programmata: sostituzione disco RAID completata'),

    ( 3,  5, 'nome',
      'Portale Clienti',      'Portale Clienti Online',
      'giulia.bianchi@alfa-energia.it',  '2024-03-01 11:00:00+01',
      'Allineamento nomenclatura agli standard di inventario NIS2'),

    ( 4,  9, 'stato',
      'in_manutenzione',      'attivo',
      'sistema_automatico',              '2024-04-15 07:45:00+02',
      'Completamento migrazione PostgreSQL 15.4 → 16.1 in finestra di manutenzione'),

    ( 5, 13, 'versione_sw',
      'Meditech Expanse 1.9', 'Meditech Expanse 2.1',
      'andrea.conti@ospedaleregionale.it','2024-02-20 08:00:00+01',
      'Aggiornamento pianificato al ciclo di release SierraSW Q1 2024'),

    ( 6, 15, 'categoria',
      'importante',           'critico',
      'l.fontana@ospedaleregionale.it',  '2023-11-01 14:30:00+01',
      'DPIA ex Art.35 GDPR: dati pazienti riclassificati critici ai fini NIS2'),

    ( 7, 24, 'stato',
      'in_manutenzione',      'attivo',
      'sistema_automatico',              '2024-05-01 04:00:00+02',
      'Fine upgrade IBM z/OS 3.1: applicazione PTF sicurezza critica UA99967'),

    ( 8, 26, 'categoria',
      'importante',           'critico',
      'e.gallo@bancametro.it',           '2024-01-15 10:00:00+01',
      'Reclassificazione post-assessment PSD2: sistema ora in scope diretto NIS2'),

    ( 9, 20, 'versione_sw',
      'FleetMaster GPS 2.8',  'FleetMaster GPS 3.1',
      'r.esposito@translogistica.it',    '2024-06-10 09:30:00+02',
      'Aggiornamento per supporto nuovo formato telematico ADR 2025'),

    (10,  7, 'stato',
      'in_manutenzione',      'attivo',
      'sistema_automatico',              '2024-07-01 06:00:00+02',
      'Completamento migrazione Kong 3.3 → 3.4: patch sicurezza CVE-2024-2185');


-- ============================================================
-- SEZIONE 13 — MISURA_SICUREZZA (25 misure Art.21 NIS2, 5 per org)
-- ============================================================
INSERT INTO misura_sicurezza
    (id, organizzazione_id, asset_id, servizio_id,
     articolo_nis2, categoria, nome,
     stato_implementazione, data_implementazione, data_verifica)
VALUES

-- == ORG 1: Alfa Energia ================================================
( 1, 1,  1, NULL, 'Art.21.2.a', 'controllo_accessi',
  'MFA su tutti gli accessi alla console SCADA',
  'implementata', '2024-01-15', '2024-07-15'),

( 2, 1,  4, NULL, 'Art.21.2.i', 'crittografia',
  'Cifratura AES-256 del DB Telemetria SCADA at-rest',
  'implementata', '2024-02-01',  NULL),

( 3, 1, NULL,  1, 'Art.21.2.b', 'incident_response',
  'Piano risposta incidenti ICS/OT v2.1 (conforme IEC 62443)',
  'implementata', '2023-10-01', '2024-04-01'),

( 4, 1, NULL, NULL,'Art.21.2.d', 'supply_chain',
  'Audit annuale sicurezza fornitori critici SCADA (IndustrialSoft)',
  'in_corso',      NULL,          NULL),

( 5, 1, NULL,  1, 'Art.21.2.c', 'continuita_operativa',
  'BCP settore energia — test semestrale DRP con simulazione black-out',
  'pianificata',   NULL,          NULL),

-- == ORG 2: BetaCloud ===================================================
( 6, 2,  8, NULL, 'Art.21.2.a', 'controllo_accessi',
  'Zero Trust su k8s: RBAC + OPA Gatekeeper + Falco runtime security',
  'implementata', '2024-03-01', '2024-09-01'),

( 7, 2,  7, NULL, 'Art.21.2.i', 'crittografia',
  'TLS 1.3 obbligatorio + mTLS tra microservizi via Kong API Gateway',
  'implementata', '2024-07-15',  NULL),

( 8, 2, NULL, NULL,'Art.21.2.f', 'gestione_rischi',
  'Risk Assessment annuale cloud (ISO 27005): riesame rischi infrastruttura e SaaS',
  'implementata', '2024-01-01', '2025-01-01'),

( 9, 2, NULL,  4, 'Art.21.2.b', 'incident_response',
  'SIEM Splunk Cloud + SOAR Phantom per rilevamento e risposta automatizzata',
  'in_corso',      NULL,          NULL),

(10, 2, NULL, NULL,'Art.21.2.h', 'vulnerability_management',
  'Vulnerability scanning Nessus mensile + pentesting annuale infrastruttura',
  'implementata', '2023-06-01', '2024-06-01'),

-- == ORG 3: Ospedale ====================================================
(11, 3, 16, NULL, 'Art.21.2.a', 'controllo_accessi',
  'Smart card + PIN per accesso CCE da tutti i reparti',
  'implementata', '2024-04-01',  NULL),

(12, 3, 15, NULL, 'Art.21.2.i', 'crittografia',
  'TDE AES-256 su DB Oracle: cifratura dati pazienti at-rest',
  'implementata', '2024-01-01', '2024-07-01'),

(13, 3, NULL,  7, 'Art.21.2.b', 'incident_response',
  'Piano risposta incidenti allineato CERT-PA Sanità: procedure escalation H24',
  'implementata', '2023-12-01', '2024-06-01'),

(14, 3, NULL, NULL,'Art.21.2.g', 'governance',
  'Nomina CISO e approvazione Policy di Sicurezza ICT v1.0 da parte del CdA',
  'implementata', '2023-06-01',  NULL),

(15, 3, NULL,  8, 'Art.21.2.d', 'supply_chain',
  'Inserimento clausole NIS2 nel rinnovo contratto SierraSW (PACS e HIS)',
  'in_corso',      NULL,          NULL),

-- == ORG 4: TransLogistica ==============================================
(16, 4, 19, NULL, 'Art.21.2.a', 'controllo_accessi',
  'MFA per accesso VPN operatori flotta e sistema gestione Fleet',
  'in_corso',      NULL,          NULL),

(17, 4, NULL, 10, 'Art.21.2.c', 'continuita_operativa',
  'BCP continuità tracking flotta: failover su cluster secondario Hub Nord',
  'implementata', '2023-09-01', '2024-03-01'),

(18, 4, NULL, NULL,'Art.21.2.b', 'incident_response',
  'Procedure gestione incidenti informatici — documento in fase di redazione',
  'pianificata',   NULL,          NULL),

(19, 4, NULL, NULL,'Art.21.2.h', 'vulnerability_management',
  'Patch management automatizzato WSUS per endpoint e server Windows',
  'in_corso',      NULL,          NULL),

(20, 4, NULL, 11, 'Art.21.2.d', 'supply_chain',
  'Revisione clausole di sicurezza nei contratti SAP WM e connettività',
  'pianificata',   NULL,          NULL),

-- == ORG 5: BancaMetro ==================================================
(21, 5, 24, NULL, 'Art.21.2.a', 'controllo_accessi',
  'PAM CyberArk per gestione accessi privilegiati a mainframe e sistemi core',
  'implementata', '2024-02-01', '2024-08-01'),

(22, 5, NULL, 13, 'Art.21.2.i', 'crittografia',
  'Cifratura E2E di tutte le transazioni con HSM nShield: firma e verifica HMAC',
  'implementata', '2023-01-01', '2024-01-01'),

(23, 5, NULL, 13, 'Art.21.2.b', 'incident_response',
  'SOC bancario H24 con CSIRT dedicato e gestione incidenti DORA-compliant',
  'implementata', '2022-06-01', '2024-06-01'),

(24, 5, NULL, NULL,'Art.21.2.d', 'supply_chain',
  'Due diligence annuale fornitori critici (IBM, SWIFT): audit on-site e questionari',
  'implementata', '2024-01-01', '2025-01-01'),

(25, 5, NULL, NULL,'Art.21.2.f', 'gestione_rischi',
  'Framework ERM integrato Basel III + NIS2: risk appetite e quarterly risk review',
  'implementata', '2023-03-01', '2024-03-01');


-- ============================================================
-- SEZIONE 14 — PROFILO_ACN (6 profili, stati differenti)
-- ============================================================
INSERT INTO profilo_acn
    (id, organizzazione_id, compilato_da_id, versione, stato,
     data_compilazione, note)
VALUES
    (1, 1,  1, 1, 'inviato',       '2024-03-01 10:00:00+01',
     'Prima registrazione profilo ACN. Sezioni asset e referenti complete.'),

    (2, 1,  1, 2, 'bozza',         '2024-10-15 09:30:00+02',
     'Aggiornamento v2: aggiunti 3 asset OT post-assessment IEC 62443.'),

    (3, 2,  4, 1, 'bozza',         '2024-06-01 14:00:00+02',
     'Prima compilazione in corso. Mancano dipendenze cloud e referenti tecnici.'),

    (4, 3,  7, 1, 'approvato',     '2024-04-20 11:00:00+02',
     'Profilo approvato da ACN. Tutte le sezioni obbligatorie sanità complete.'),

    (5, 4, 10, 1, 'da_aggiornare', '2024-07-01 08:00:00+02',
     'ACN ha richiesto integrazione misure sicurezza mancanti e aggiornamento dipendenze.'),

    (6, 5, 13, 1, 'inviato',       '2024-02-28 16:00:00+01',
     'Profilo bancario inviato con documentazione DORA allegata. In attesa esito ACN.');


-- ============================================================
-- RESET SEQUENZE (allinea i contatori ai MAX degli id inseriti)
-- ============================================================
SELECT setval(pg_get_serial_sequence('organizzazione',   'id'), MAX(id)) FROM organizzazione;
SELECT setval(pg_get_serial_sequence('sede',             'id'), MAX(id)) FROM sede;
SELECT setval(pg_get_serial_sequence('persona',          'id'), MAX(id)) FROM persona;
SELECT setval(pg_get_serial_sequence('fornitore',        'id'), MAX(id)) FROM fornitore;
SELECT setval(pg_get_serial_sequence('asset',            'id'), MAX(id)) FROM asset;
SELECT setval(pg_get_serial_sequence('servizio',         'id'), MAX(id)) FROM servizio;
SELECT setval(pg_get_serial_sequence('contratto',        'id'), MAX(id)) FROM contratto;
SELECT setval(pg_get_serial_sequence('dipendenza',       'id'), MAX(id)) FROM dipendenza;
SELECT setval(pg_get_serial_sequence('responsabilita',   'id'), MAX(id)) FROM responsabilita;
SELECT setval(pg_get_serial_sequence('asset_storico',    'id'), MAX(id)) FROM asset_storico;
SELECT setval(pg_get_serial_sequence('misura_sicurezza', 'id'), MAX(id)) FROM misura_sicurezza;
SELECT setval(pg_get_serial_sequence('profilo_acn',      'id'), MAX(id)) FROM profilo_acn;


COMMIT;


-- ============================================================
-- VERIFICA — decommentare per controllare i conteggi attesi
-- ============================================================
/*
SELECT tabella, n FROM (
    SELECT 'organizzazione'    AS tabella, COUNT(*) AS n FROM organizzazione    -- 5
    UNION ALL SELECT 'sede',              COUNT(*) FROM sede                   -- 10
    UNION ALL SELECT 'persona',           COUNT(*) FROM persona                -- 15
    UNION ALL SELECT 'tipo_asset',        COUNT(*) FROM tipo_asset             -- 10
    UNION ALL SELECT 'fornitore',         COUNT(*) FROM fornitore              -- 10
    UNION ALL SELECT 'asset',             COUNT(*) FROM asset                  -- 29
    UNION ALL SELECT 'servizio',          COUNT(*) FROM servizio               -- 15
    UNION ALL SELECT 'asset_servizio',    COUNT(*) FROM asset_servizio         -- 20
    UNION ALL SELECT 'contratto',         COUNT(*) FROM contratto              -- 12
    UNION ALL SELECT 'dipendenza',        COUNT(*) FROM dipendenza             -- 20
    UNION ALL SELECT 'responsabilita',    COUNT(*) FROM responsabilita         -- 22
    UNION ALL SELECT 'asset_storico',     COUNT(*) FROM asset_storico          -- 10
    UNION ALL SELECT 'misura_sicurezza',  COUNT(*) FROM misura_sicurezza       -- 25
    UNION ALL SELECT 'profilo_acn',       COUNT(*) FROM profilo_acn            --  6
) t ORDER BY tabella;

-- Anteprima viste ACN
SELECT * FROM v_asset_critici           LIMIT 10;
SELECT * FROM v_dipendenze_critiche     LIMIT 10;
SELECT * FROM v_referenti_acn;
SELECT * FROM v_misure_sicurezza_stato  LIMIT 10;
SELECT * FROM v_profilo_acn_export;
*/
