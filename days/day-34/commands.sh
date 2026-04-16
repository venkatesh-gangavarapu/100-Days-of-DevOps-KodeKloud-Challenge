#!/bin/bash
# Day 34 — Git Hooks: post-update Release Tagging
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Merge feature→master, create post-update hook for release tags, push

# ─────────────────────────────────────────
# SSH as natasha
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to working repo
cd /usr/src/kodekloudrepos/ecommerce

# STEP 2: Inspect branches
git branch -a
git log --oneline --all --graph

# STEP 3: Merge feature into master
git checkout master
git merge feature

# STEP 4: Create post-update hook in BARE REPO (not working clone)
cat > /opt/ecommerce.git/hooks/post-update << 'EOF'
#!/bin/bash
for ref in "$@"; do
    if [ "$ref" = "refs/heads/master" ]; then
        TAG_NAME="release-$(date +%Y-%m-%d)"
        git tag "$TAG_NAME"
        echo "Created release tag: $TAG_NAME"
    fi
done
EOF

# STEP 5: Make hook executable (CRITICAL - Git ignores non-executable hooks)
chmod +x /opt/ecommerce.git/hooks/post-update

# STEP 6: Verify hook is executable and correct
ls -la /opt/ecommerce.git/hooks/post-update
# Expected: -rwxr-xr-x
cat /opt/ecommerce.git/hooks/post-update

# STEP 7: Push to origin — this TRIGGERS the hook
git push origin master
# Expected output includes:
# remote: Created release tag: release-2026-04-16

# STEP 8: Verify tag was created
git fetch --tags origin
git tag -l
# Expected: release-2026-04-16

# ALSO verify directly in bare repo
git --git-dir=/opt/ecommerce.git tag -l
# Expected: release-2026-04-16
