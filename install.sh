#!/bin/bash

echo "Installing npm dependencies..."
npm install

echo "Compiling contracts..."
npx hardhat compile

echo "Running tests..."
npx hardhat test
