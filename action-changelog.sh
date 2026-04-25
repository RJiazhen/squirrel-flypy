#!/usr/bin/env bash

# The release workflow runs this only for tag builds. `current` is the pushed
# tag, and `previous` is the nearest tag before it; the log between them becomes
# the draft GitHub Release body.
current=$(git describe --tags --abbrev=0)
previous=$(git describe --always --abbrev=0 --tags ${current}^)

echo "**Change log since ${previous}:**"

# Merge commits are omitted so the generated release note focuses on individual
# changes that landed since the previous tag.
git log --oneline --decorate ${previous}...${current} --pretty="format:- %h %s" | grep -v Merge
