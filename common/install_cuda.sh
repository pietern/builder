#!/bin/bash

set -ex

# install CUDA 9.2 in the same container
wget -q https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_396.37_linux -O setup
chmod +x setup
./setup --silent --no-opengl-libs --toolkit
rm -f setup

# patch 1
wget -q https://developer.nvidia.com/compute/cuda/9.2/Prod2/patches/1/cuda_9.2.148.1_linux -O setup
chmod +x setup
./setup -s --accept-eula
rm -f setup

# install CUDA 9.2 CuDNN
# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
mkdir tmp_cudnn && cd tmp_cudnn
wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.6.2.24-1+cuda9.2_amd64.deb -O cudnn-dev.deb
wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.6.2.24-1+cuda9.2_amd64.deb -O cudnn.deb
ar -x cudnn-dev.deb && tar -xvf data.tar.xz
ar -x cudnn.deb && tar -xvf data.tar.xz
mkdir -p cuda/include && mkdir -p cuda/lib64
cp -a usr/include/x86_64-linux-gnu/cudnn_v7.h cuda/include/cudnn.h
cp -a usr/lib/x86_64-linux-gnu/libcudnn* cuda/lib64
mv cuda/lib64/libcudnn_static_v7.a cuda/lib64/libcudnn_static.a
ln -s libcudnn.so.7 cuda/lib64/libcudnn.so
chmod +x cuda/lib64/*.so
cp -a cuda/include/* /usr/local/cuda/include/
cp -a cuda/lib64/* /usr/local/cuda/lib64/
cd ..
rm -rf tmp_cudnn
ldconfig

# install CUDA 10.0 in the same container
wget -q https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux
chmod +x cuda_10.0.130_410.48_linux
./cuda_10.0.130_410.48_linux --silent --no-opengl-libs --toolkit
rm -f cuda_10.0.130_410.48_linux

# install CUDA 10.0 CuDNN
# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
mkdir tmp_cudnn && cd tmp_cudnn
wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.6.2.24-1+cuda10.0_amd64.deb -O cudnn-dev.deb
wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.6.2.24-1+cuda10.0_amd64.deb -O cudnn.deb
ar -x cudnn-dev.deb && tar -xvf data.tar.xz
ar -x cudnn.deb && tar -xvf data.tar.xz
mkdir -p cuda/include && mkdir -p cuda/lib64
cp -a usr/include/x86_64-linux-gnu/cudnn_v7.h cuda/include/cudnn.h
cp -a usr/lib/x86_64-linux-gnu/libcudnn* cuda/lib64
mv cuda/lib64/libcudnn_static_v7.a cuda/lib64/libcudnn_static.a
ln -s libcudnn.so.7 cuda/lib64/libcudnn.so
chmod +x cuda/lib64/*.so
cp -a cuda/include/* /usr/local/cuda/include/
cp -a cuda/lib64/* /usr/local/cuda/lib64/
cd ..
rm -rf tmp_cudnn
ldconfig

# # install CUDA 10.1 in the same container
wget -q https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_418.67_linux.run
chmod +x cuda_10.1.168_418.67_linux.run
./cuda_10.1.168_418.67_linux.run    --extract=/tmp/cuda
rm -f cuda_10.1.168_418.67_linux.run
mv /tmp/cuda/cuda-toolkit /usr/local/cuda-10.1
rm -rf /tmp/cuda
rm -f /usr/local/cuda && ln -s /usr/local/cuda-10.1 /usr/local/cuda

# install CUDA 10.1 CuDNN
# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
mkdir tmp_cudnn && cd tmp_cudnn
wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.6.2.24-1+cuda10.1_amd64.deb -O cudnn-dev.deb
wget -q http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.6.2.24-1+cuda10.1_amd64.deb -O cudnn.deb
ar -x cudnn-dev.deb && tar -xvf data.tar.xz
ar -x cudnn.deb && tar -xvf data.tar.xz
mkdir -p cuda/include && mkdir -p cuda/lib64
cp -a usr/include/x86_64-linux-gnu/cudnn_v7.h cuda/include/cudnn.h
cp -a usr/lib/x86_64-linux-gnu/libcudnn* cuda/lib64
mv cuda/lib64/libcudnn_static_v7.a cuda/lib64/libcudnn_static.a
ln -s libcudnn.so.7 cuda/lib64/libcudnn.so
chmod +x cuda/lib64/*.so
cp -a cuda/include/* /usr/local/cuda/include/
cp -a cuda/lib64/* /usr/local/cuda/lib64/
cd ..
rm -rf tmp_cudnn
ldconfig

#####################################################################################
# CUDA 9.2 prune static libs
#####################################################################################
export NVPRUNE="/usr/local/cuda-9.2/bin/nvprune"
export CUDA_LIB_DIR="/usr/local/cuda-9.2/lib64"

export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70"
export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70"

# all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "cusolver" \
| xargs -I {} bash -c \
"echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

# prune CuDNN and CuBLAS
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcudnn_static.a -o $CUDA_LIB_DIR/libcudnn_static.a
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_device.a -o $CUDA_LIB_DIR/libcublas_device.a

#####################################################################################
# CUDA 10.0 prune static libs
#####################################################################################
export NVPRUNE="/usr/local/cuda-10.0/bin/nvprune"
export CUDA_LIB_DIR="/usr/local/cuda-10.0/lib64"

export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"
export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"

# all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
# curand cannot be pruned, as there's a bug in 10.0 + curand_static + nvprune. Filed with nvidia at 2460767
ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "metis" | grep -v "curand"  \
| xargs -I {} bash -c \
"echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

# prune CuDNN and CuBLAS
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcudnn_static.a -o $CUDA_LIB_DIR/libcudnn_static.a
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a

#################################################################################################

#####################################################################################
# CUDA 10.1 prune static libs
#####################################################################################
export NVPRUNE="/usr/local/cuda-10.1/bin/nvprune"
export CUDA_LIB_DIR="/usr/local/cuda-10.1/lib64"

export GENCODE="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"
export GENCODE_CUDNN="-gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75"

# all CUDA libs except CuDNN and CuBLAS (cudnn and cublas need arch 3.7 included)
ls $CUDA_LIB_DIR/ | grep "\.a" | grep -v "culibos" | grep -v "cudart" | grep -v "cudnn" | grep -v "cublas" | grep -v "metis"  \
| xargs -I {} bash -c \
"echo {} && $NVPRUNE $GENCODE $CUDA_LIB_DIR/{} -o $CUDA_LIB_DIR/{}"

# prune CuDNN and CuBLAS
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcudnn_static.a -o $CUDA_LIB_DIR/libcudnn_static.a
$NVPRUNE $GENCODE_CUDNN $CUDA_LIB_DIR/libcublas_static.a -o $CUDA_LIB_DIR/libcublas_static.a

#################################################################################################
