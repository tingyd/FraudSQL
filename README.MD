# SQL Injection Attack & Defense on a Fraud Transaction Database

A database security project demonstrating SQL injection attack types and defense mechanisms using a real-world financial transaction dataset.

---

## Project Overview

This project uses a credit card fraud transaction dataset as the target database to demonstrate how SQL injection attacks work and how to defend against them.

| Person | Attack | Defense |
|---|---|---|
| Person 1 | Authentication Bypass | User roles & privileges |
| Person 2 | UNION-based injection | Views |
| Person 3 | Blind/Boolean injection | Stored procedures |

---

## Project Structure

```
fraud-detection/
│
├── data/                        # Exported CSVs from MySQL (3NF tables)
│   ├── location.csv
│   ├── cardholder.csv
│   ├── merchant.csv
│   └── transaction.csv
│
├── fraudDetection.sql           # Full schema: staging → 1NF → 2NF → 3NF
├── import_csv.py                # Imports CSVs into MySQL via SQLAlchemy
├── ui.py                        # Streamlit frontend (login + fraud alerts)
├── requirements.txt             # Python dependencies
└── README.MD
```

---

## Database Schema (3NF)

The raw dataset was normalized through three stages:

- **1NF** — Enforced primary key, corrected data types (VARCHAR dates → DATETIME/DATE)
- **2NF** — Removed partial dependencies, extracted `cardholder` and `merchant` tables
- **3NF** — Removed transitive dependencies, extracted `location` table (zip → city, state, lat, long, city_pop)

Final tables:

| Table | Primary Key | Description |
|---|---|---|
| `location` | `zip` | City, state, coordinates, population |
| `cardholder` | `cc_num` | Cardholder personal info, FK to location |
| `merchant` | `merchant_id` | Merchant name, category, coordinates |
| `transaction` | `trans_num` | Transaction facts, FK to cardholder & merchant |

---

## Setup

### 1. Clone the repository
```bash
git clone https://github.com/tingyd/FraudSQL.git
cd fraud-detection
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Set up the database
Run the schema script in MySQL Workbench or terminal:
```bash
mysql -u root -p < fraudDetection.sql
```

Then import the raw CSV:
```bash
mysql --local-infile=1 -u root -p fraud_detection
```
```sql
LOAD DATA LOCAL INFILE '/path/to/fraudTest.csv'
INTO TABLE staging FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;
```

### 4. Import CSVs (alternative)
If you already have the CSVs in `data/`, you can import directly:
```bash
python import_csv.py
```

### 5. Run the app
```bash
streamlit run ui.py
```

---

## Dependencies

```
streamlit
mysql-connector-python
pandas
sqlalchemy
pymysql
```

---

## Dataset

The dataset used is a synthetic credit card fraud transaction dataset containing 555,719 transactions with cardholder PII, merchant info, transaction amounts, and a fraud label (`is_fraud`).
