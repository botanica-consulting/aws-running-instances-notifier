#!/bin/bash

# Exit on error, treat unset variables as an error, print executed commands
set -eux

# Make sure we're in the right directory
ls -al aws_tracker.py

# Create a directory to hold dependencies
mkdir -p package

# Install dependencies into the package directory
pipenv requirements > requirements.txt
pipenv run pip install -r requirements.txt --target ./package

# Copy the python script into the package directory
cp aws_tracker.py package/

# Change to the package directory
pushd package

ls -al

# Zip the contents of the package directory
zip -r ../lambda_function_payload.zip .

# Go back to the original directory
popd

# Remove the package directory
rm -rf package requirements.txt

