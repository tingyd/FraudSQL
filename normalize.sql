
DROP DATABASE IF EXISTS fraud_detection;
CREATE DATABASE fraud_detection;
USE fraud_detection;

-- STAGING — Raw import

DROP TABLE IF EXISTS staging;
CREATE TABLE staging (
    row_id                 INT,
    trans_date_trans_time  VARCHAR(30),
    cc_num                 BIGINT UNSIGNED,
    merchant               VARCHAR(150),
    category               VARCHAR(50),
    amt                    DECIMAL(10,2),
    first                  VARCHAR(50),
    last                   VARCHAR(50),
    gender                 CHAR(1),
    street                 VARCHAR(150),
    city                   VARCHAR(100),
    state                  CHAR(2),
    zip                    INT,
    lat                    DECIMAL(9,6),
    `long`                 DECIMAL(9,6),
    city_pop               INT,
    job                    VARCHAR(100),
    dob                    VARCHAR(15),
    trans_num              CHAR(32),
    unix_time              BIGINT,
    merch_lat              DECIMAL(9,6),
    merch_long             DECIMAL(9,6),
    is_fraud               TINYINT(1)
);

-- Import via terminal (run in a separate terminal window):
-- mysql --local-infile=1 -u root -p fraud_detection
-- LOAD DATA LOCAL INFILE '/path/fraudTest.csv'
-- INTO TABLE staging FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- Verify import: both counts should match (no duplicates)
SELECT COUNT(*)                  AS total_rows   FROM staging;
SELECT COUNT(DISTINCT trans_num) AS unique_trans  FROM staging;

-- Clean: remove critical nulls
SET SQL_SAFE_UPDATES = 0;
DELETE FROM staging
WHERE trans_num IS NULL
   OR cc_num    IS NULL
   OR merchant  IS NULL
   OR amt       IS NULL
   OR is_fraud  IS NULL;

-- Confirm clean row count
SELECT COUNT(*) AS rows_after_clean FROM staging;

-- 1NF — First Normal Form
-- Rules applied:
--   1. Each column holds atomic (indivisible) values
--   2. Each row is unique — enforce PRIMARY KEY on trans_num
--   3. Proper data types: VARCHAR dates → DATETIME / DATE
--
-- Result: one flat table, all columns, trans_num as PK

DROP TABLE IF EXISTS fraud_1nf;
CREATE TABLE fraud_1nf (
    trans_num              CHAR(32)        PRIMARY KEY,   -- rule 2: enforces row uniqueness
    trans_date_trans_time  DATETIME        NOT NULL,      -- rule 3: proper type, was VARCHAR
    unix_time              BIGINT          NOT NULL,
    cc_num                 BIGINT UNSIGNED NOT NULL,
    merchant               VARCHAR(150)    NOT NULL,
    category               VARCHAR(50)     NOT NULL,
    amt                    DECIMAL(10,2)   NOT NULL,
    first                  VARCHAR(50)     NOT NULL,
    last                   VARCHAR(50)     NOT NULL,
    gender                 CHAR(1)         NOT NULL,
    dob                    DATE            NOT NULL,      -- rule 3: proper type, was VARCHAR
    job                    VARCHAR(100)    NOT NULL,
    street                 VARCHAR(150)    NOT NULL,
    zip                    INT             NOT NULL,
    city                   VARCHAR(100)    NOT NULL,
    state                  CHAR(2)         NOT NULL,
    lat                    DECIMAL(9,6)    NOT NULL,
    `long`                 DECIMAL(9,6)    NOT NULL,
    city_pop               INT             NOT NULL,
    merch_lat              DECIMAL(9,6)    NOT NULL,
    merch_long             DECIMAL(9,6)    NOT NULL,
    is_fraud               TINYINT(1)      NOT NULL
);

INSERT INTO fraud_1nf
SELECT
    trans_num,
    STR_TO_DATE(trans_date_trans_time, '%Y-%m-%d %H:%i:%s'),
    unix_time,
    cc_num, merchant, category, amt,
    first, last, gender,
    STR_TO_DATE(dob, '%Y-%m-%d'),
    job, street, zip, city, state, lat, `long`, city_pop,
    merch_lat, merch_long, is_fraud
FROM staging;

SELECT '1NF' AS stage, COUNT(*) AS row_count FROM fraud_1nf;


-- 2NF — Second Normal Form (builds on 1NF)
-- Rules applied:
--   No partial dependencies — every non-key attribute must
--   depend on the WHOLE primary key, not just part of it.
--
-- Problems found in fraud_1nf:
--   cc_num → first, last, gender, dob, job, street, zip,
--             city, state, lat, long, city_pop
--   (cardholder info depends on cc_num, not on trans_num)
--
--   merchant → category, merch_lat, merch_long
--   (merchant info depends on merchant name, not on trans_num)
--
-- Fix: extract cardholder and merchant into separate tables.
-- Note: zip → city, state, lat, long, city_pop is a transitive
--       dependency still present here — fixed in 3NF.
--
-- Result: 3 tables
--   cardholder_2nf   — attributes depending only on cc_num
--   merchant_2nf     — attributes depending only on merchant
--   transaction_2nf  — pure transaction facts

DROP TABLE IF EXISTS transaction_2nf;
DROP TABLE IF EXISTS cardholder_2nf;
DROP TABLE IF EXISTS merchant_2nf;

CREATE TABLE cardholder_2nf (
    cc_num    BIGINT UNSIGNED  PRIMARY KEY,
    first     VARCHAR(50)      NOT NULL,
    last      VARCHAR(50)      NOT NULL,
    gender    CHAR(1)          NOT NULL,
    dob       DATE             NOT NULL,
    job       VARCHAR(100)     NOT NULL,
    street    VARCHAR(150)     NOT NULL,
    zip       INT              NOT NULL,
    city      VARCHAR(100)     NOT NULL,   -- transitive: zip → city,  will be fixed in 3NF
    state     CHAR(2)          NOT NULL,   -- transitive: zip → state, will be fixed in 3NF
    lat       DECIMAL(9,6)     NOT NULL,   -- transitive: zip → lat,   will be fixed in 3NF
    `long`    DECIMAL(9,6)     NOT NULL,   -- transitive: zip → long,  will be fixed in 3NF
    city_pop  INT              NOT NULL    -- transitive: zip → pop,   will be fixed in 3NF
);

CREATE TABLE merchant_2nf (
    merchant_name  VARCHAR(150)   PRIMARY KEY,
    category       VARCHAR(50)    NOT NULL,
    merch_lat      DECIMAL(9,6)   NOT NULL,
    merch_long     DECIMAL(9,6)   NOT NULL
);

CREATE TABLE transaction_2nf (
    trans_num              CHAR(32)        PRIMARY KEY,
    trans_date_trans_time  DATETIME        NOT NULL,
    unix_time              BIGINT          NOT NULL,
    cc_num                 BIGINT UNSIGNED NOT NULL,
    merchant               VARCHAR(150)    NOT NULL,
    amt                    DECIMAL(10,2)   NOT NULL,
    is_fraud               TINYINT(1)      NOT NULL,
    CONSTRAINT fk2_cc    FOREIGN KEY (cc_num)   REFERENCES cardholder_2nf(cc_num),
    CONSTRAINT fk2_merch FOREIGN KEY (merchant) REFERENCES merchant_2nf(merchant_name)
);

INSERT INTO cardholder_2nf
SELECT DISTINCT cc_num, first, last, gender,
    STR_TO_DATE(dob, '%Y-%m-%d'),
    job, street, zip, city, state, lat, `long`, city_pop
FROM staging;

INSERT IGNORE INTO merchant_2nf
SELECT DISTINCT merchant, category, merch_lat, merch_long
FROM staging;

INSERT INTO transaction_2nf
SELECT trans_num,
    STR_TO_DATE(trans_date_trans_time, '%Y-%m-%d %H:%i:%s'),
    unix_time, cc_num, merchant, amt, is_fraud
FROM staging;

SELECT '2NF - cardholder_2nf'   AS stage, COUNT(*) AS row_count FROM cardholder_2nf
UNION ALL
SELECT '2NF - merchant_2nf',    COUNT(*) FROM merchant_2nf
UNION ALL
SELECT '2NF - transaction_2nf', COUNT(*) FROM transaction_2nf;


-- 3NF — Third Normal Form
-- Rules applied:
--   No transitive dependencies — every non-key attribute must
--   depend ONLY on the PK, not on another non-key attribute.
--
-- Problem found in cardholder_2nf:
--   cc_num → zip → city, state, lat, long, city_pop
--   zip is a non-key attribute that determines other non-key
--   attributes — this is a transitive dependency.
--
-- Fix: extract zip and its dependents into a location table.
--      Replace merchant_name PK with surrogate merchant_id.
--
-- Result: 4 tables
--   location    — zip → city, state, lat, long, city_pop
--   cardholder  — cc_num → personal info + zip (FK to location)
--   merchant    — merchant_id → name, category, coords
--   transaction — trans_num → facts + FK to cardholder & merchant

DROP TABLE IF EXISTS `transaction`;
DROP TABLE IF EXISTS cardholder;
DROP TABLE IF EXISTS merchant;
DROP TABLE IF EXISTS location;

CREATE TABLE location (
    zip       INT            PRIMARY KEY,
    city      VARCHAR(100)   NOT NULL,
    state     CHAR(2)        NOT NULL,
    lat       DECIMAL(9,6)   NOT NULL,
    `long`    DECIMAL(9,6)   NOT NULL,
    city_pop  INT            NOT NULL
);

CREATE TABLE cardholder (
    cc_num    BIGINT UNSIGNED  PRIMARY KEY,
    first     VARCHAR(50)      NOT NULL,
    last      VARCHAR(50)      NOT NULL,
    gender    CHAR(1)          NOT NULL,
    dob       DATE             NOT NULL,
    job       VARCHAR(100)     NOT NULL,
    street    VARCHAR(150)     NOT NULL,
    zip       INT              NOT NULL,
    CONSTRAINT fk3_zip FOREIGN KEY (zip) REFERENCES location(zip)
);

CREATE TABLE merchant (
    merchant_id    INT            PRIMARY KEY AUTO_INCREMENT,
    merchant_name  VARCHAR(150)   NOT NULL UNIQUE,
    category       VARCHAR(50)    NOT NULL,
    merch_lat      DECIMAL(9,6)   NOT NULL,
    merch_long     DECIMAL(9,6)   NOT NULL
);

CREATE TABLE `transaction` (
    trans_num              CHAR(32)        PRIMARY KEY,
    trans_date_trans_time  DATETIME        NOT NULL,
    unix_time              BIGINT          NOT NULL,
    cc_num                 BIGINT UNSIGNED NOT NULL,
    merchant_id            INT             NOT NULL,
    amt                    DECIMAL(10,2)   NOT NULL,
    is_fraud               TINYINT(1)      NOT NULL,
    CONSTRAINT fk3_cc    FOREIGN KEY (cc_num)      REFERENCES cardholder(cc_num),
    CONSTRAINT fk3_merch FOREIGN KEY (merchant_id) REFERENCES merchant(merchant_id)
);

-- Populate in FK-safe order
INSERT INTO location (zip, city, state, lat, `long`, city_pop)
SELECT DISTINCT zip, city, state, lat, `long`, city_pop
FROM cardholder_2nf;

INSERT INTO cardholder (cc_num, first, last, gender, dob, job, street, zip)
SELECT cc_num, first, last, gender, dob, job, street, zip
FROM cardholder_2nf;

INSERT IGNORE INTO merchant (merchant_name, category, merch_lat, merch_long)
SELECT merchant_name, category, merch_lat, merch_long
FROM merchant_2nf;

INSERT INTO `transaction` (trans_num, trans_date_trans_time, unix_time, cc_num, merchant_id, amt, is_fraud)
SELECT t.trans_num, t.trans_date_trans_time, t.unix_time,
    t.cc_num, m.merchant_id, t.amt, t.is_fraud
FROM transaction_2nf t
JOIN merchant m ON m.merchant_name = t.merchant;

-- Final verification
SELECT '3NF - location'      AS stage, COUNT(*) AS row_count FROM location
UNION ALL
SELECT '3NF - cardholder',   COUNT(*) FROM cardholder
UNION ALL
SELECT '3NF - merchant',     COUNT(*) FROM merchant
UNION ALL
SELECT '3NF - transaction',  COUNT(*) FROM `transaction`;

-- Cleanup intermediate tables
DROP TABLE IF EXISTS fraud_1nf;
DROP TABLE IF EXISTS transaction_2nf;
DROP TABLE IF EXISTS cardholder_2nf;
DROP TABLE IF EXISTS merchant_2nf;
DROP TABLE IF EXISTS staging;
