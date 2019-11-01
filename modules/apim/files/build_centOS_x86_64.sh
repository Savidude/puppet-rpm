#!/bin/bash
# ----------------------------------------------------------------------------------
# Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------------
#
#Generate WSO2 Product Installers for CentOS.

# Configuration Variables and Parameters

function printUsage() {
    echo "Usage:"
    echo "$0 [options]"
    echo "options:"
    echo "    -v (--version)"
    echo "        version of the product distribution. ex : 2.5.0"
    echo "    -n (--name)"
    echo "        name of the product distribution. ex : ws02am"
    echo "    -j (--jdk)"
    echo "        name of jdk directory. ex : jdk1.8.0_192"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -v|--version)
        VERSION="$2"
        shift # past argument
        shift # past value
        ;;
        -n|--name)
        PRODUCT="$2"
        shift # past argument
        shift # past value
        ;;
        -j|--jdk)
        JDK="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "Please enter the version of the product pack"
    printUsage
    exit 1
fi

if [ -z "$PRODUCT" ]; then
    echo "Please enter the name of the product."
    printUsage
    exit 1
fi

if [ -z "$JDK" ]; then
    echo "Please enter the name of the jdk directory."
    printUsage
    exit 1
fi


# _ _ _ _ _ _ _  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
#Functions

function printSignature() {
  cat ./utils/ascii_art.txt
  echo
}

function deleteSourceFromDirectory() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Deleting source and installer spec file from source directory..."
    [ -d ${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SOURCES/${PRODUCT_NAME} ] && rm -rf ${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SOURCES/${PRODUCT_NAME}
    [ -f ${SPEC_FILE_LOC} ] && rm -f ${SPEC_FILE_LOC}
}

function createSourceDirectory() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Creating source directory..."
    mkdir -p ${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SOURCES/${PRODUCT_NAME}
    mv ${WORKING_DIR}/${PRODUCT_NAME}/* ${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SOURCES/${PRODUCT_NAME} && rm -rf ${WORKING_DIR}/${PRODUCT_NAME}
    if [[ ${PRODUCT} == "wso2ei" ]]; then
	echo "Copying Ballerina Integrator components"
        echo ""
        echo "Following jar files will be copied: "
        ls ${WORKING_DIR}/components/*.jar | xargs -n 1 basename
        echo ""
        cp ${WORKING_DIR}/components/*.jar ${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SOURCES/${PRODUCT_NAME}/ballerina-integrator/distributions/jballerina-1.0.1/bre/lib
    fi
}

function setupInstallerSpec() {
    cp ${WORKING_DIR}/${PRODUCT}/resources/${SPEC_FILE} ${SPEC_DIRECTORY}
    sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SPEC_FILE_LOC}
    sed -i -e 's/__VERSION__/'${VERSION}'/g' ${SPEC_FILE_LOC}
}

function createInstaller() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Creating Product Platform Installer"
    deleteSourceFromDirectory
    createSourceDirectory
    setupInstallerSpec
    # start building the rpm installer
    rpmbuild -bb --define "_topdir  $(pwd)/rpmbuild" ${SPEC_FILE_LOC}
}

function unzipProduct() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Unzipping product-pack to working directory..."
    unzip -q ${WORKING_DIR}/products/${PRODUCT}-${VERSION}.zip -d ${WORKING_DIR}/
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Unzipping process finished."
}

function copyJDK() {
    if [[ ${PRODUCT} != "wso2am-micro-gw" ]]; then
    	mkdir -p ${WORKING_DIR}/${PRODUCT}-${VERSION}/jdk/
    	cp -r ${JDK} ${WORKING_DIR}/${PRODUCT}-${VERSION}/jdk/${JDK}
    fi
}

function updateLauncherFiles() {
    [ -d ${WORKING_DIR}/tmp ] && rm -rf ${WORKING_DIR}/tmp
    mkdir ${WORKING_DIR}/tmp
    cp ${WORKING_DIR}/launcher_files/* ${WORKING_DIR}/tmp/
    sed -i "s/__JDK_NAME__/${JDK}/g" ${WORKING_DIR}/tmp/*.sh
    chmod 755 ${WORKING_DIR}/tmp/*.sh
}

function clearProductDir() {
    # clear product directory after installer generating process
    [ -f ${SPEC_FILE_LOC} ] && rm ${SPEC_FILE_LOC}
    [ -d ${SOURCES_DIRECTORY}/${PRODUCT_NAME} ] && rm -rf ${SOURCES_DIRECTORY}/${PRODUCT_NAME}
}

# - - - - - - - - - - - - - - - -  - - - - - - - -  - - - - - - - -  - - - - - - - -
# Main script

# Parameters
WORKING_DIR=$(pwd)
PRODUCT_NAME=${PRODUCT}-${VERSION}
TITLE=${PRODUCT}
RPM_PRODUCT_VERSION=$(echo "${VERSION//-/.}")
PRODUCT_DISTRIBUTION_LOCATION=${WORKING_DIR}/${PRODUCT}
SPEC_FILE="installer.spec"
SPEC_DIRECTORY="${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SPECS/"
SOURCES_DIRECTORY="${PRODUCT_DISTRIBUTION_LOCATION}/rpmbuild/SOURCES/"
SPEC_FILE_LOC=${SPEC_DIRECTORY}/${SPEC_FILE}
SERVICE_SCRIPT_PATH=${WORKING_DIR}/${PRODUCT_NAME}/

# start th process in working directory
cd $WORKING_DIR

# start the generator with signature
printSignature

# check necessary files before start the building
if [ ! -f products/${PRODUCT}-${VERSION}.zip ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: [ERROR] Product pack not found...!"
    exit 1
fi
if [ ! -d ${JDK} ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: [ERROR] JDK directory not found...!"
    exit 1
fi
if [ ! -d launcher_files ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: [ERROR] Launcher files directory not found...!"
    exit 1
fi

# copy product zip file and unzip
unzipProduct
# copy JDK to the products
copyJDK
# update launcher files
updateLauncherFiles

# copying launcher files and WUM inplace to product distribution
case "$PRODUCT" in
    wso2am) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product API Manager is selected. Process started..."
            cp tmp/launcher_wso2server.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__SERVICE__|'bin/wso2server'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            ;;
    wso2am-analytics) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product API Manager - Analytics is selected. Process started..."
            cp tmp/launcher_dashboard.sh $PRODUCT-$VERSION/bin
            cp tmp/launcher_worker.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-dashboard
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-worker

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's|__SERVICE__|'bin/dashboard'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-dashboard
            sed -i -e 's|__SERVICE__|'bin/worker'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-worker
            ;;
    wso2is) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Identity Server is selected. Process started..."
            cp tmp/launcher_wso2server.sh $PRODUCT-$VERSION/bin
            cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__SERVICE__|'bin/wso2server'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            ;;
    wso2is-analytics) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Identity Server - Analytics is selected. Process started..."
            cp tmp/launcher_dashboard.sh $PRODUCT-$VERSION/bin
            cp tmp/launcher_worker.sh $PRODUCT-$VERSION/bin
	    cp tmp/launcher_manager.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-dashboard
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-manager
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-worker

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's|__SERVICE__|'bin/dashboard'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-dashboard
            sed -i -e 's|__SERVICE__|'bin/manager'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-manager
            sed -i -e 's|__SERVICE__|'bin/worker'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-worker
            ;;
    wso2is-km) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Identity Server as a Key Manager is selected. Process started..."
            cp tmp/launcher_wso2server.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__SERVICE__|'bin/wso2server'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            ;;
    wso2ei) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Enterprise Integrator is selected. Process started..."
            cp tmp/launcher_server.sh $PRODUCT-$VERSION/streaming-integrator/bin
            cp tmp/launcher_micro-integrator.sh $PRODUCT-$VERSION/micro-integrator/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT_EI ${SERVICE_SCRIPT_PATH}/wso2si
            cp ${WORKING_DIR}/service_script/SCRIPT_EI ${SERVICE_SCRIPT_PATH}/wso2mi

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/wso2*
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/wso2*
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/wso2*

	    sed -i -e 's/__INTEGRATOR_TYPE__/streaming-integrator/g' ${SERVICE_SCRIPT_PATH}/wso2si
            sed -i -e 's/__INTEGRATOR_TYPE__/micro-integrator/g' ${SERVICE_SCRIPT_PATH}/wso2mi
            
	    sed -i -e 's|__SERVICE__|'wso2/server/bin/carbon'|g' ${SERVICE_SCRIPT_PATH}/wso2si
            sed -i -e 's|__SERVICE__|'bin/micro-integrator'|g' ${SERVICE_SCRIPT_PATH}/wso2mi
            ;;
    wso2sp) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Stream Processor is selected. Process started..."
            cp tmp/launcher_editor.sh $PRODUCT-$VERSION/bin
            cp tmp/launcher_dashboard.sh $PRODUCT-$VERSION/bin
            cp tmp/launcher_worker.sh $PRODUCT-$VERSION/bin
            cp tmp/launcher_manager.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-dashboard
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-editor
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-manager
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-worker

            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-*
            sed -i -e 's|__SERVICE__|'bin/dashboard'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-dashboard
            sed -i -e 's|__SERVICE__|'bin/editor'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-editor
            sed -i -e 's|__SERVICE__|'bin/manager'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-manager
            sed -i -e 's|__SERVICE__|'bin/worker'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION-worker
            ;;
    wso2mi) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Micro Integrator is selected. Process started..."
            cp tmp/launcher_micro-integrator.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/update_linux $PRODUCT-$VERSION/bin
            # copy micro-integrator cli file
            cp mi_cli/mi $PRODUCT-$VERSION/bin
	    sudo chmod 755 $PRODUCT-$VERSION/bin/mi

            # copy and configure service script
            mkdir -p ${SERVICE_SCRIPT_PATH}
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__SERVICE__|'bin/micro-integrator'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            ;;
    wso2am-micro-gw) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product APIM Microgateway is selected. Process started..."
            # cp tmp/launcher_gateway.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin

            # copy and configure service script
            cp ${WORKING_DIR}/service_script/SCRIPT_MG ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION

            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__SERVICE__|'bin/gateway'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            ;; 
    wso2am-micro-gw-toolkit) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product APIM Microgateway Toolkit is selected. Process started..."
            cp tmp/launcher_micro-gw.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/* $PRODUCT-$VERSION/bin
            ;;
    wso2si-tooling) echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product Streaming Integrator Tooling is selected. Process started..."
            cp tmp/launcher_tooling.sh $PRODUCT-$VERSION/bin
            # cp wum_inplace/update_linux $PRODUCT-$VERSION/bin

            # copy and configure service script
            mkdir -p ${SERVICE_SCRIPT_PATH}
            cp ${WORKING_DIR}/service_script/SCRIPT ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__JAVA_HOME__|'/usr/lib64/wso2/${TITLE}/${VERSION}/jdk/${JDK}'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's/__PRODUCT_VERSION__/'${VERSION}'/g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            sed -i -e 's|__SERVICE__|'bin/tooling'|g' ${SERVICE_SCRIPT_PATH}/$PRODUCT-$VERSION
            ;;
esac

# remove tmp directory in working directory
rm -rf ${WORKING_DIR}/tmp
echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Product preparation finished."

echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Installer Generating process started."
cd $PRODUCT_DISTRIBUTION_LOCATION
echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Working directory changes to : ${PRODUCT_DISTRIBUTION_LOCATION}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Build started..."
# rpm package builder start
createInstaller
# remove source files and spec files after package creation
clearProductDir
echo "[$(date +'%Y-%m-%d %H:%M:%S')]: Build completed."

exit 0
