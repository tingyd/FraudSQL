import streamlit as st
import mysql.connector
import method1

st.sidebar.title("Navigation")
selected_tab = st.sidebar.radio("Go to:", ["Attack 1", "Prevention 1", "Attack 2", "Prevention 2", "Attack 3", "Prevention 3"])

if selected_tab == "Attack 1":
    method1.attack_1()

elif selected_tab == "Prevention 1":
    ...

        