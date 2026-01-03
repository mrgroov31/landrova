#!/bin/bash

# Script to configure git with a different account for this repository

echo "Current Git Configuration:"
echo "Name: $(git config user.name)"
echo "Email: $(git config user.email)"
echo ""

# Prompt for new credentials
read -p "Enter new Git username: " NEW_USERNAME
read -p "Enter new Git email: " NEW_EMAIL

# Configure for this repository only
git config user.name "$NEW_USERNAME"
git config user.email "$NEW_EMAIL"

echo ""
echo "New Git Configuration:"
echo "Name: $(git config user.name)"
echo "Email: $(git config user.email)"
echo ""
echo "Configuration updated! You can now commit and push with the new account."
echo ""
echo "To push, you'll need to authenticate with GitHub."
echo "You can use a Personal Access Token (PAT) instead of password."
echo ""
echo "To push, run:"
echo "  git push origin main"
echo ""
echo "When prompted for credentials:"
echo "  Username: Your GitHub username"
echo "  Password: Your Personal Access Token (not your GitHub password)"

