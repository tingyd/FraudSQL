import streamlit as st
import mysql.connector


def _connect_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        database="transactions_db",
    )


def attack_3():
    st.title("Attack 3: Blind/Boolean SQL Injection")
    st.caption("Target: vulnerable login query in transactions_db.app_users")

    st.markdown(
        """
A blind/boolean injection does not require direct data output.
The attacker infers TRUE/FALSE from behavior changes (e.g., login success vs failure).
"""
    )

    col1, col2 = st.columns(2)
    with col1:
        if st.button("Load TRUE payload", key="a3_true"):
            st.session_state["a3_password"] = "' OR (1=1) -- "
    with col2:
        if st.button("Load FALSE payload", key="a3_false"):
            st.session_state["a3_password"] = "' OR (1=2) -- "

    username = st.text_input("Username", value="alice", key="a3_username")
    password_input = st.text_input(
        "Password (can include payload)",
        value=st.session_state.get("a3_password", "password123"),
        key="a3_password",
    )

    if st.button("Run Vulnerable Login", key="a3_run"):
        conn = _connect_db()
        cursor = conn.cursor(dictionary=True, buffered=True)

        vulnerable_query = (
            "SELECT user_id, username, role "
            "FROM app_users "
            f"WHERE username = '{username}' AND password_plain = '{password_input}' "
            "LIMIT 1"
        )

        st.code(vulnerable_query, language="sql")

        try:
            cursor.execute(vulnerable_query)
            row = cursor.fetchone()

            if row:
                st.error(
                    "Login SUCCESS. This can indicate a TRUE boolean condition in injected SQL."
                )
                st.json(row)
            else:
                st.info(
                    "Login FAILED. This can indicate a FALSE boolean condition in injected SQL."
                )
        except mysql.connector.Error as exc:
            st.warning(f"Query error: {exc}")
        finally:
            cursor.close()
            conn.close()


def prevention_3():
    st.title("Prevention 3: Stored Procedure Defense")
    st.caption("Defense: hashed passwords + procedure + parameter binding")

    st.markdown(
        """
This defense blocks blind SQLi by treating user input as data, not executable SQL.
"""
    )

    if st.button("Setup Demo Users + Procedure", key="p3_setup"):
        conn = _connect_db()
        cursor = conn.cursor()
        try:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS app_users (
                    user_id INT AUTO_INCREMENT PRIMARY KEY,
                    username VARCHAR(50) NOT NULL UNIQUE,
                    password_plain VARCHAR(100),
                    password_hash CHAR(64),
                    role VARCHAR(20) NOT NULL
                )
                """
            )

            cursor.execute(
                """
                INSERT INTO app_users (username, password_plain, password_hash, role)
                VALUES
                    ('alice', 'password123', SHA2('password123', 256), 'analyst'),
                    ('admin', 'adminpass', SHA2('adminpass', 256), 'admin')
                ON DUPLICATE KEY UPDATE
                    password_plain = VALUES(password_plain),
                    password_hash = VALUES(password_hash),
                    role = VALUES(role)
                """
            )

            cursor.execute("DROP PROCEDURE IF EXISTS sp_secure_login")
            cursor.execute(
                """
                CREATE PROCEDURE sp_secure_login(
                    IN p_username VARCHAR(50),
                    IN p_password VARCHAR(100)
                )
                BEGIN
                    SELECT user_id, username, role
                    FROM app_users
                    WHERE username = p_username
                      AND password_hash = SHA2(p_password, 256)
                    LIMIT 1;
                END
                """
            )

            conn.commit()
            st.success("Secure objects created in transactions_db.")
        except mysql.connector.Error as exc:
            st.error(f"Setup failed: {exc}")
        finally:
            cursor.close()
            conn.close()

    col1, col2 = st.columns(2)
    with col1:
        if st.button("Load Injection Payload", key="p3_payload"):
            st.session_state["p3_password"] = "' OR (1=1) -- "
    with col2:
        if st.button("Load Correct Password", key="p3_valid"):
            st.session_state["p3_password"] = "password123"

    username = st.text_input("Username", value="alice", key="p3_username")
    password_input = st.text_input(
        "Password",
        value=st.session_state.get("p3_password", "password123"),
        key="p3_password",
    )

    if st.button("Run Secure Login", key="p3_run"):
        conn = _connect_db()
        cursor = conn.cursor(dictionary=True, buffered=True)

        try:
            cursor.callproc("sp_secure_login", (username, password_input))
            rows = []
            for result in cursor.stored_results():
                rows = result.fetchall()

            st.code("CALL sp_secure_login(%s, %s)", language="sql")

            if rows:
                st.success("Valid credentials accepted.")
                st.json(rows[0])
            else:
                st.info("Login failed. Payload was treated as plain input, not SQL code.")
        except mysql.connector.Error as exc:
            st.error(f"Secure login error: {exc}")
        finally:
            cursor.close()
            conn.close()
