#!/bin/bash

# Script to start localtunnel for the Fedha backend

echo "Starting localtunnel for Fedha..."

# First check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "ERROR: npm not found. Please install Node.js and npm first."
    echo "Visit: https://nodejs.org/ to download and install Node.js"
    exit 1
fi

echo "Using npx to run localtunnel..."
npx localtunnel --port 8000 --subdomain tired-dingos-beg

# If we got here, something went wrong
echo "Localtunnel stopped or failed. Check for errors above."
