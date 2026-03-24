#!/bin/bash
# Day 17 — PostgreSQL Database User & Privilege Setup
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Create user kodekloud_rin, database kodekloud_db2, grant full access
# Note: Do NOT restart PostgreSQL service

# ─────────────────────────────────────────
# STEP 1: SSH into database server
# ssh peter@stdb01    (Password: Sp!dy)
# ─────────────────────────────────────────

# STEP 2: Switch to postgres OS user (peer auth)
sudo su - postgres

# STEP 3: Connect to PostgreSQL
psql

# ─────────────────────────────────────────
# INSIDE psql — Run these SQL commands
# ─────────────────────────────────────────

# Create user with password
# CREATE USER kodekloud_rin WITH PASSWORD 'B4zNgHA7Ya';

# Create database
# CREATE DATABASE kodekloud_db2;

# Grant full privileges on database to user
# GRANT ALL PRIVILEGES ON DATABASE kodekloud_db2 TO kodekloud_rin;

# Verify user created
# \du

# Verify database created and check access privileges
# \l kodekloud_db2

# Exit psql
# \q

# ─────────────────────────────────────────
# ONE-SHOT METHOD (non-interactive)
# Run all SQL commands without entering psql prompt
# ─────────────────────────────────────────
psql -c "CREATE USER kodekloud_rin WITH PASSWORD 'B4zNgHA7Ya';"
psql -c "CREATE DATABASE kodekloud_db2;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE kodekloud_db2 TO kodekloud_rin;"

# ─────────────────────────────────────────
# VERIFY
# ─────────────────────────────────────────
# List users
psql -c "\du"

# List databases with privileges
psql -c "\l kodekloud_db2"

# ─────────────────────────────────────────
# TEST CONNECTION AS NEW USER
# ─────────────────────────────────────────
psql -U kodekloud_rin -d kodekloud_db2 -h localhost
# Password: B4zNgHA7Ya
# Expected: clean connection prompt
