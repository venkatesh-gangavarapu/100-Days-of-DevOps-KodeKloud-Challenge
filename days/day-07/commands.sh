#!/bin/bash
# Day 07 — Passwordless SSH Authentication Setup
# Challenge: KodeKloud 100 Days of DevOps
# Task: Configure passwordless SSH from thor (jump host) to all 3 app servers

# ─────────────────────────────────────────
# CONTEXT
# Jump Host user : thor
# stapp01        : tony    / Ir0nM@n
# stapp02        : steve   / Am3ric@
# stapp03        : banner  / BigGr33n
# ─────────────────────────────────────────

# ─────────────────────────────────────────
# STEP 1: Confirm identity on jump host
# ─────────────────────────────────────────
whoami      # Expected: thor
hostname    # Expected: jump host

# ─────────────────────────────────────────
# STEP 2: Generate SSH key pair for thor
# -t rsa     : RSA algorithm
# -b 4096    : 4096-bit key strength
# -f         : output file
# -N ""      : no passphrase (required for automation)
# ─────────────────────────────────────────
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# View the generated public key
cat ~/.ssh/id_rsa.pub

# ─────────────────────────────────────────
# STEP 3: Copy public key to all app servers
# Enter each server's password when prompted
# (This is the last time you'll need it)
# ─────────────────────────────────────────
ssh-copy-id tony@stapp01      # Password: Ir0nM@n
ssh-copy-id steve@stapp02     # Password: Am3ric@
ssh-copy-id banner@stapp03    # Password: BigGr33n

# ─────────────────────────────────────────
# STEP 4: Test passwordless SSH (no password prompt)
# ─────────────────────────────────────────
ssh tony@stapp01 "whoami && hostname"
ssh steve@stapp02 "whoami && hostname"
ssh banner@stapp03 "whoami && hostname"

# ─────────────────────────────────────────
# STEP 5: Verify authorized_keys on remote
# ─────────────────────────────────────────
ssh tony@stapp01 "cat ~/.ssh/authorized_keys"
ssh steve@stapp02 "cat ~/.ssh/authorized_keys"
ssh banner@stapp03 "cat ~/.ssh/authorized_keys"

# ─────────────────────────────────────────
# MANUAL METHOD (if ssh-copy-id unavailable)
# ─────────────────────────────────────────
# PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
# ssh tony@stapp01 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
#   echo '$PUB_KEY' >> ~/.ssh/authorized_keys && \
#   chmod 600 ~/.ssh/authorized_keys"

# ─────────────────────────────────────────
# BONUS: Debug if passwordless auth fails
# ─────────────────────────────────────────
# ssh -vvv tony@stapp01     # Verbose output shows exact auth flow
# ssh -i ~/.ssh/id_rsa tony@stapp01   # Explicitly specify key file
