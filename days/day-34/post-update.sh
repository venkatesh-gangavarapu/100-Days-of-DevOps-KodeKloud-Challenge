#!/bin/bash
# post-update hook — /opt/ecommerce.git/hooks/post-update
# Creates a release tag whenever master branch is pushed to

for ref in "$@"; do
    if [ "$ref" = "refs/heads/master" ]; then
        TAG_NAME="release-$(date +%Y-%m-%d)"
        git tag "$TAG_NAME"
        echo "Created release tag: $TAG_NAME"
    fi
done

