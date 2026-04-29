#!/bin/bash

echo "=== FraudSQL Setup ==="
read -sp "Enter MySQL root password: " DB_PASS
echo ""

# 1. Create database and staging table
echo "Creating database and staging table..."
mysql -u root -p"$DB_PASS" < setup.sql
if [ $? -ne 0 ]; then echo "ERROR: setup.sql failed"; exit 1; fi

# 2. Load CSV into staging
echo "Loading CSV into staging..."
mysql --local-infile=1 -u root -p"$DB_PASS" transactions_db -e "
LOAD DATA LOCAL INFILE '$(pwd)/data/fraudTest.csv'
INTO TABLE staging
FIELDS TERMINATED BY ','
ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;"
if [ $? -ne 0 ]; then echo "ERROR: CSV load failed"; exit 1; fi

# 3. Normalize
echo "Normalizing data (1NF -> 2NF -> 3NF)..."
mysql -u root -p"$DB_PASS" transactions_db < normalize.sql
if [ $? -ne 0 ]; then echo "ERROR: normalize.sql failed"; exit 1; fi

# 4. Security setup
echo "Setting up users and permissions..."
mysql -u root -p"$DB_PASS" transactions_db < security.sql
if [ $? -ne 0 ]; then echo "ERROR: security.sql failed"; exit 1; fi

echo ""
echo "=== Setup complete! Run: streamlit run ui.py ==="
echo "streamlit run ui.py" >> setup.sh
streamlit run ui.py
