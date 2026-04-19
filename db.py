import mysql.connector

# attack connection — root, full access
def get_conn():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="password",
        database="transactions_db"
    )

# defense connection — app_user, restricted
def get_safe_conn():
    return mysql.connector.connect(
        host="localhost",
        user="app_user",
        password="apppassword",
        database="transactions_db"
    )
