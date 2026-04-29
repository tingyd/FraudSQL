# SQL Injection Attack & Defense on a Fraud Transaction Database

A database security project demonstrating SQL injection attack types and defense mechanisms using a real-world financial transaction dataset.

---

## Project Overview

| Person | Attack | Defense |
|---|---|---|
| Person 1 | Authentication Bypass | User Roles & Privileges + Parameterized Queries |
| Person 2 | UNION-based Injection | Views |
| Person 3 | Blind/Boolean Injection | Stored Procedures |

---

## Project Structure

```
FraudSQL/
│
├── data/                        # Exported CSVs from MySQL (3NF tables)
│   ├── location.csv
│   ├── cardholder.csv
│   ├── merchant.csv
│   └── transaction.csv
│
├── normalize.sql                # Full schema: staging → 1NF → 2NF → 3NF (transactions_db)
├── security.sql                 # Creates users table, app_user credentials, and grants
├── import_csv.py                # Imports CSVs into transactions_db via SQLAlchemy
├── db.py                        # Database connection helpers (get_conn, get_safe_conn)
├── auth_bypass.py               # Method 1: Authentication bypass attack + prevention
├── union_attack.py              # Method 2: UNION injection attack + prevention
├── method3.py                   # Method 3: Blind/Boolean injection attack + prevention
├── ui.py                        # Streamlit frontend — navigation across all methods
├── requirements.txt             # Python dependencies
└── README.MD
```

---

## Database Schema (3NF)

The raw dataset was normalized through three stages:

- **1NF** — Enforced primary key, corrected data types (VARCHAR dates → DATETIME/DATE)
- **2NF** — Removed partial dependencies, extracted `cardholder` and `merchant` tables
- **3NF** — Removed transitive dependencies, extracted `location` table (zip → city, state, lat, long, city_pop)

Final tables in `transactions_db`:

| Table | Primary Key | Description |
|---|---|---|
| `location` | `zip` | City, state, coordinates, population |
| `cardholder` | `cc_num` | Cardholder personal info, FK to location |
| `merchant` | `merchant_id` | Merchant name, category, coordinates |
| `transaction` | `trans_num` | Transaction facts, FK to cardholder & merchant |
| `users` | `user_id` | App-level logins generated from cardholder data |
| `app_users` | `user_id` | Demo users for Method 3 blind/boolean injection |

---

## Database Users

| User | Password | Access |
|---|---|---|
| `root` | your local root password | Full access — used in attack demos |
| `app_user` | `client123` | SELECT on `users` only — used in prevention demos |

---

## Setup

### 1. Clone the repository
```bash
git clone https://github.com/tingyd/FraudSQL.git
cd FraudSQL
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Import CSVs into transactions_db
Make sure the CSVs are in the `data/` folder, then run:
```bash
python import_csv.py
```

### 4. Run security setup
This creates the `users` table, populates it from cardholder data, and sets up `app_user`:
```bash
mysql -u root -p transactions_db < security.sql
```

### 5. Run the app
```bash
streamlit run ui.py
```

---

## Connection Helpers (db.py)

- `get_conn()` — connects as `root`, full access, used in **attack** demos
- `get_safe_conn()` — connects as `app_user`, restricted access, used in **prevention** demos

---

## Demo Payloads

**Auth Bypass (Method 1)**
- Username: `' OR '1'='1 --` / Password: anything

**UNION Injection (Method 2)**
- `' UNION SELECT *, NULL, NULL, NULL FROM merchant --`

**Blind/Boolean (Method 3)**
- TRUE payload: `' OR (1=1) -- `
- FALSE payload: `' OR (1=2) -- `

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
