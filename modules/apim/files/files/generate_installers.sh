#!/bin/bash

# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------

# This script acts as product installer generator for ubuntu x64.

set -e

# Configurations
# ~~~~~~~~~~~~~~
JDK="jdk8u212-b03"
BALLERINA_JRE="jdk8u202-b08-jre"
USE_WUM_UPDATES="false"

WORKING_DIR=$(pwd)
PRODUCT_HOME="${WORKING_DIR}/products/"
PRODUCT_INSTALLER_DIR="${WORKING_DIR}/updated_installers/"
CP=`which cp`
ECHO=`which echo`
RM=`which rm`
ERROR_FLAG="false"
# - - - - - - - -

# check the WUM update option and copy WUM updated products
if [ ${USE_WUM_UPDATES} == "true" ]; then
  # delete previously build product packages
  [ "$(ls -A ${PRODUCT_HOME})" ] && ${RM} -f ${PRODUCT_HOME}/*
  bash ${WORKING_DIR}/run-wum.sh
fi

# [ -f ${PRODUCT_INSTALLER_DIR}/* ] && ${RM} -f ${PRODUCT_INSTALLER_DIR}/* || continue

# read product list and build installers for each given product
while read product; do
  echo -e "\n<- - - - - Starting Installer Build - - - - ->"
  PRODUCT_NAME=$(echo $product | cut -f1 -d_)
  PRODUCT_VERSION=$(echo $product | cut -f2 -d_)
  echo "Product Name: ${PRODUCT_NAME}"
  echo "Product Version: ${PRODUCT_VERSION}"

  if [[ ${PRODUCT_NAME} == "wso2am-micro-gw-toolkit" ]]; then
      JDK=${BALLERINA_JRE}
      echo "JDK version change to JRE version that Ballerina using : ${BALLERINA_JRE}"
  fi

  # run the build rpm installer script with parameters
  bash ${WORKING_DIR}/build_centOS_x86_64.sh -n ${PRODUCT_NAME} -v ${PRODUCT_VERSION} -j ${JDK}
  # copying rpm installer
  echo "Adding RPM installer to the installer directory"
  [ -f ${WORKING_DIR}/${PRODUCT_NAME}/rpmbuild/RPMS/x86_64/*.rpm ] && mv ${WORKING_DIR}/${PRODUCT_NAME}/rpmbuild/RPMS/x86_64/*.rpm ${PRODUCT_INSTALLER_DIR}/
done <product_list.txt

exit 0

# Copy product installers to the infra location
[ -f ${PRODUCT_INSTALLER_DIR}/transfer_done.txt ] && rm ${PRODUCT_INSTALLER_DIR}/transfer_done.txt
scp ${PRODUCT_INSTALLER_DIR}/* packs_to_dist_usr@192.168.8.20:/home/packs_to_dist_usr/rpm/
if [ $? -eq 0 ]
then
  echo "Successfully transferred files"
  echo "$(date +%s)" > ${PRODUCT_INSTALLER_DIR}/transfer_done.txt
  scp ${PRODUCT_INSTALLER_DIR}/transfer_done.txt packs_to_dist_usr@192.168.8.20:/home/packs_to_dist_usr/rpm/
else
  echo "File transferring failed"
fi
