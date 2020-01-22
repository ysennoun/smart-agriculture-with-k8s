#!/bin/bash

set -eax

source deploy/code/deployer_code.sh

# Install python and maven requirements
install_python_requirements
install_deps

# Run python and spark unit tests
launch_python_unit_tests
launch_spark_unit_tests
