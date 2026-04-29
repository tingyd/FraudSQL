USE transactions_db;
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id   INT PRIMARY KEY AUTO_INCREMENT,
    username  VARCHAR(50) NOT NULL UNIQUE,
    password  VARCHAR(50) NOT NULL,
    role      VARCHAR(20) NOT NULL,
    cc_num    BIGINT UNSIGNED,
    CONSTRAINT fk_user_cc FOREIGN KEY (cc_num) REFERENCES cardholder(cc_num)
);

-- generate from cardholder data
INSERT INTO users (username, password, role, cc_num)
SELECT username, password, role, cc_num FROM (
    SELECT
        LOWER(CONCAT(first, '_', last))  AS username,
        CONCAT(first, LEFT(last, 1))     AS password,
        'cardholder'                     AS role,
        cc_num,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(CONCAT(first, '_', last))
            ORDER BY cc_num
        ) AS rn
    FROM cardholder
) t
WHERE rn = 1;

-- add admin manually
INSERT INTO users (username, password, role, cc_num) VALUES
('admin', 'admin123', 'admin', NULL);

DROP USER IF EXISTS 'app_user'@'localhost';
CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'client123';
GRANT SELECT ON transactions_db.users TO 'app_user'@'localhost';
FLUSH PRIVILEGES;
