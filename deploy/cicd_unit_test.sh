#!/bin/bash

set -eax

source deploy/platform/deployer_platform.sh
source deploy/front-end-code/deployer_front_end.sh

# Install python, maven and nodejs requirements
install_python_requirements
install_deps
install_vue_deps

# Run python, spark and vue unit tests
launch_python_unit_tests
launch_spark_unit_tests
launch_vue_unit_tests
