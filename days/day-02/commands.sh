#!/bin/bash
# Day 02 — Temporary User Account with Expiry Date
# Challenge: KodeKloud 100 Days of DevOps
# Task: Create user 'anita' with expiry 2027-01-28 on App Server 2

# ─────────────────────────────────────────
# STEP 1: SSH into App Server 2
# ─────────────────────────────────────────
# ssh steve@stapp02

# ─────────────────────────────────────────
# STEP 2: Create user with expiry date
# ─────────────────────────────────────────
sudo useradd -e 2027-01-28 anita

# ─────────────────────────────────────────
# STEP 3: Verify expiry (human-readable)
# ─────────────────────────────────────────
sudo chage -l anita
# Look for: Account expires: Jan 28, 2027

# ─────────────────────────────────────────
# STEP 4: Verify via /etc/shadow
# ─────────────────────────────────────────
sudo grep "anita" /etc/shadow
# 8th field = days since epoch = expiry date

# ─────────────────────────────────────────
# STEP 5: Confirm lowercase username
# ─────────────────────────────────────────
getent passwd anita

# ─────────────────────────────────────────
# ALTERNATIVE METHODS (modify existing user)
# ─────────────────────────────────────────
# sudo usermod -e 2027-01-28 anita
# sudo chage -E 2027-01-28 anita

# ─────────────────────────────────────────
# BONUS: Decode epoch days to readable date
# ─────────────────────────────────────────
python3 -c "import datetime; print(datetime.date(1970,1,1) + datetime.timedelta(days=20847))"
# Output: 2027-01-28
