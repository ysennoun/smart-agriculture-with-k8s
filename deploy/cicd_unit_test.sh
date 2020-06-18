#!/bin/bash

set -eax

source deploy/platform/deployer_platform.sh
source deploy/front-end/deployer_front_end.sh
source deploy/device/deployer_device.sh

# Install python, maven and nodejs requirements
#install_python_requirements
#install_deps
#install_vue_deps
install_device_deps
install_device_python_requirements

# Run python, spark and vue unit tests
#launch_python_unit_tests
#launch_spark_unit_tests
#launch_vue_unit_tests
launch_device_python_unit_tests