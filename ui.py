import streamlit as st
import mysql.connector

user_input = st.text_input("Enter your dat:")

if st.button("Submit"):
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        database="transactions_db"
    )
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM transaction WHERE Cc_num = {user_input}")
    result = cursor.fetchall()
    conn.commit()
    st.success("Data retrieved!")
    st.write(result)