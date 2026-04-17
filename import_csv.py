import mysql.connector
import pandas as pd
from sqlalchemy import create_engine

# Replace these variables with your actual MySQL details
DB_HOST = "localhost"
DB_USER = "root"          # Default XAMPP/MySQL user
DB_NAME = "transactions_db"
CSV_FILE = ("data/location.csv", "data/transaction.csv", "data/merchant.csv", "data/cardholder.csv")
TABLE_NAME = ("location", "transaction", "merchant", "cardholder") 
# ==========================================
# 1. CREATE THE DATABASE
# ==========================================
# Connect to the MySQL server (without specifying a database yet)
server_conn = mysql.connector.connect(
    host=DB_HOST,
    user=DB_USER
)
cursor = server_conn.cursor()

# Create the database if it doesn't already exist
cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
print(f"Database '{DB_NAME}' is ready.")

# Close the server connection
cursor.close()
server_conn.close()

# ==========================================
# 2. IMPORT THE CSV AS A TABLE
# ==========================================
# Load the CSV data into a Pandas DataFrame
for (file, name) in zip(CSV_FILE, TABLE_NAME):
    print("Reading CSV file...")
    df = pd.read_csv(file)

    # Create an SQLAlchemy engine to connect to our newly created database
    # The connection string format is: mysql+pymysql://user:password@host/database_name
    connection_string = f"mysql+pymysql://{DB_USER}@{DB_HOST}/{DB_NAME}"
    engine = create_engine(connection_string)

    # Push the DataFrame to MySQL
    # if_exists='replace' will drop the table if it exists and recreate it. 
    # You can change this to 'append' if you want to add rows to an existing table.
    print("Importing data into MySQL...")
    df.to_sql(name=name, con=engine, if_exists="replace", index=False)

    print(f"Success! '{file}' has been imported into the '{name}' table.")