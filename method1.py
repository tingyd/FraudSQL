import streamlit as st
import mysql.connector

def attack_1():
    st.title("Attack 1: SQL Injection")
    user_input = st.text_input("Enter your data:")

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
        
def prevention_1():
    st.title("Test")