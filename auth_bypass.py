import streamlit as st
from db import get_conn, get_safe_conn

def attack_1():
    st.title(" Authentication Bypass")
    st.markdown("**Try a normal login first, then try the injection below**")
    st.code("Username: admin    Password: anything")
    st.code("' OR '1'='1' --   ← paste this into username to bypass login")

    username = st.text_input("Username")
    password = st.text_input("Password", type="password")

    if st.button("Login (Vulnerable)"):
        conn   = get_conn()
        cursor = conn.cursor()

        # VULNERABLE — direct string concatenation
        query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"

        st.markdown("**Query being executed:**")
        st.code(query, language="sql")

        cursor.execute(query)
        result = cursor.fetchall()

        if result:
            st.error(f"⚠️ Login bypassed — {len(result)} user(s) exposed!")
            st.write(result)

            st.markdown("---")
            st.error("⚠️ Attacker now has access to sensitive cardholder data:")

            cursor2 = conn.cursor()
            cursor2.execute("""
                SELECT c.first, c.last, c.dob, c.job, c.street,
                       l.city, l.state,
                       COUNT(t.trans_num) as total_transactions,
                       SUM(t.amt) as total_spent
                FROM cardholder c
                JOIN location l ON l.zip = c.zip
                JOIN `transaction` t ON t.cc_num = c.cc_num
                GROUP BY c.cc_num
                LIMIT 20
            """)
            exposed = cursor2.fetchall()
            st.dataframe(exposed)
            cursor2.close()
            conn.close()

        else:
            st.info("No records found.")


def prevention_1():
    st.title("Roles & Privileges + Parameterized Queries")

    username = st.text_input("Username")
    password = st.text_input("Password", type="password")

    if st.button("Login (Patched)"):
        conn = get_safe_conn()
        cursor = conn.cursor()

        # SAFE — parameterized query, input never interpreted as SQL
        query = "SELECT * FROM users WHERE username = %s AND password = %s"

        st.markdown("**Query being executed:**")
        st.code(query, language="sql")

        cursor.execute(query, (username, password))
        result = cursor.fetchall()
        conn.close()

        if result:
            st.success(f" Login successful — welcome {result[0][1]}!")
            st.write(result)
        else:
            st.info("No records found. Injection attempt blocked.")
