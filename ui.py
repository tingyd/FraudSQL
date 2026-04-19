import streamlit as st
import auth_bypass, union_attack, method3

st.sidebar.title("Navigation")
selected_tab = st.sidebar.radio("Go to:", ["Union Attack", "Attack 1", "Prevention 1", "Attack 3", "Prevention 3"])

if selected_tab == "Union Attack":
    union_attack.union_attack()
if selected_tab == "Attack 1":
    auth_bypass.attack_1()
elif selected_tab == "Prevention 1":
    auth_bypass.prevention_1()
elif selected_tab == "Attack 3":
    method3.attack_3()
elif selected_tab == "Prevention 3":
    method3.prevention_3()
