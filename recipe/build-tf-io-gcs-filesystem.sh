#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2021, 2022. All Rights Reserved.
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
set -vex

#Clean up old bazel cache to avoid problems building TF
bazel clean --expunge
bazel shutdown

# Build Tensorflow from source
SCRIPT_DIR=$RECIPE_DIR/../buildscripts

# Pick up additional variables defined from the conda build environment
$SCRIPT_DIR/set_python_path_for_bazelrc.sh $SRC_DIR
$SCRIPT_DIR/set_tf_io_bazelrc.sh $SRC_DIR $PY_VER

sh ${SRC_DIR}/configure.sh

export BAZEL_OPTIMIZATION="--config=optimization"

# install using pip from the whl file
bazel --bazelrc=$SRC_DIR/tf_io.bazelrc build -s \
      --verbose_failures $BAZEL_OPTIMIZATION //tensorflow_io_gcs_filesystem/...

if [ $? -eq 0 ];
then
    echo "bazel build executed successfully"
else
    echo "bazel build terminated unsuccessfully"
    bazel clean --expunge
    bazel shutdown
fi
python setup.py bdist_wheel --data bazel-bin --project tensorflow-io-gcs-filesystem
python -m pip install dist/*.whl

bazel clean --expunge
bazel shutdown

