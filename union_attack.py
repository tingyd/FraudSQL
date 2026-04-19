import streamlit as st
import mysql.connector
from db import get_conn, get_safe_conn


# non-attack inputs
# Cc_num: 60416207185
#

# Successful attacks:
# ' OR '1'='1' --
# ' OR 1=1 --
# ' UNION SELECT *, NULL, NULL, NULL from merchant --
#    you need to pad the columns with NULL so that number of columns matches with original select
# apostrophes (') can be removed if attacking numeric input
# ' UNION SELECT *, NULL from transactions WHERE Cc_num=(SELECT Cc_num FROM cardholders WHERE First="Mary" and Last="Diaz") --

# Unsuccessful attacks:
# ; `some other command`; --
#   my sql doesn't allow multiple concurrent commands

def union_attack():
    st.title("Union Injection")
    user_input = st.text_input("Enter your data:")

    if st.button("Submit (String, Unprotected)"):
        conn = get_conn()
        st.write(f"SELECT * FROM cardholder WHERE Street = '{user_input}';")
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM cardholder WHERE Street = '{user_input}';")
        result = cursor.fetchall()
        conn.commit()
        st.success("Data retrieved!")
        st.write(result)

    if st.button("Submit (Numeric, Unprotected)"):
        conn = get_safe_conn()
        st.write(f"SELECT * FROM cardholder WHERE Cc_num = {user_input};")
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM cardholder WHERE Cc_num = {user_input};")
        result = cursor.fetchall()
        conn.commit()
        st.success("Data retrieved!")
        st.write(result)



    if st.button("Submit (Protected)"):
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            database="transactions_db"
        )
        st.write(f"SELECT * FROM cardholder WHERE Cc_num = '{user_input}';")
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM cardholder WHERE Cc_num = '%s';", (user_input,))
        result = cursor.fetchall()
        conn.commit()
        st.success("Data retrieved!")
        st.write(result)
