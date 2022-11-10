#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************
set -ex
# Set python path variables from conda build environment
BAZEL_RC_DIR=$1
PY_VER=$2

#Determine architecture for specific options
ARCH=`uname -p`

##
## Use centralized optimization settings
##
NL=$'\n'
BUILD_COPT="build:optimization --copt="
BUILD_HOST_COPT="build:optimization --host_copt="
if [ -z "${cpu_opt_tune}"]; then
     CPU_ARCH_OPTION='';
     CPU_ARCH_HOST_OPTION='';
else
     if [[ "${ARCH}" == 'x86_64' || "${ARCH}" == 's390x' ]]; then
          CPU_ARCH_FLAG="-march=${cpu_opt_arch}"
     fi
     if [[ "${ARCH}" == 'ppc64le' ]]; then
          CPU_ARCH_FLAG="-mcpu=${cpu_opt_arch}"
     fi

     CPU_ARCH_OPTION=${BUILD_COPT}${CPU_ARCH_FLAG}
     CPU_ARCH_HOST_OPTION=${BUILD_HOST_COPT}${CPU_ARCH_FLAG}
fi

if [ -z "${cpu_opt_tune}"]; then
     CPU_TUNE_OPTION='';
     CPU_TUNE_HOST_OPTION='';
else
     CPU_TUNE_FLAG="-mtune=${cpu_opt_tune}";
     CPU_TUNE_OPTION=${BUILD_COPT}${CPU_TUNE_FLAG}
     CPU_TUNE_HOST_OPTION=${BUILD_HOST_COPT}${CPU_TUNE_FLAG}
fi

cat >> $BAZEL_RC_DIR/tf_io.bazelrc << EOF
${CPU_ARCH_OPTION}
${CPU_ARCH_HOST_OPTION}
${CPU_TUNE_OPTION}
${CPU_TUNE_HOST_OPTION}
build --copt="-fvisibility=hidden"
build --copt="-D_GLIBCXX_USE_CXX11_ABI=1"
#build --copt="-DEIGEN_MAX_ALIGN_BYTES=64"
build --action_env TF_HEADER_DIR="$PREFIX/lib/python${PY_VER}/site-packages/tensorflow/include"
build --action_env TF_SHARED_LIBRARY_DIR="$PREFIX/lib/python${PY_VER}/site-packages/tensorflow"
build --action_env TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"
build --cxxopt="-std=c++17"
build --experimental_repo_remote_exec
build --enable_platform_specific_config
build:optimization --compilation_mode=opt
build --noshow_progress
build --noshow_loading_progress
build --verbose_failures
build --test_output=errors
build --experimental_ui_max_stdouterr_bytes=-1
EOF
