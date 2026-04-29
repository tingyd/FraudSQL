CREATE DATABASE IF NOT EXISTS transactions_db;
USE transactions_db;

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
