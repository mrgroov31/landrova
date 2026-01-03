#!/bin/bash

# Quick Deep Link Testing Script
# Usage: ./test_deep_link.sh [token] [room]

TOKEN=${1:-"test123"}
ROOM=${2:-"101"}

echo "Testing deep link with token: $TOKEN, room: $ROOM"

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - iOS Simulator
    echo "Testing on iOS Simulator..."
    xcrun simctl openurl booted "ownhouse://tenant/register?token=$TOKEN&room=$ROOM"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "android"* ]]; then
    # Android
    echo "Testing on Android..."
    adb shell am start -W -a android.intent.action.VIEW -d "ownhouse://tenant/register?token=$TOKEN&room=$ROOM" com.example.own_house
else
    echo "Platform not supported. Please test manually."
    echo "Android: adb shell am start -W -a android.intent.action.VIEW -d \"ownhouse://tenant/register?token=$TOKEN&room=$ROOM\" com.example.own_house"
    echo "iOS: xcrun simctl openurl booted \"ownhouse://tenant/register?token=$TOKEN&room=$ROOM\""
fi

