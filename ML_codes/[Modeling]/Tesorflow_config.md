The best tutorials to prepare the system to install Tensorflow Docker:
- https://www.coursera.org/lecture/getting-started-with-tensor-flow2/coding-tutorial-running-tensorflow-with-docker-wCNhx
- https://www.youtube.com/watch?v=W3bk2pojLoU
- https://www.cloudsavvyit.com/14942/how-to-use-an-nvidia-gpu-with-docker-containers/
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker

# Use Docker in remote server:
`ssh -tL localhost:8821:localhost:8821 behzad@****`

`docker run -it --rm --gpus all --name tf -v "$PWD:/tf" -p 8821:8888 -p 6006:6006 tensorflow/tensorflow:latest-gpu`

`pip install jupyterlab`

`cd tf`

`git config --global credential.helper 'cache --timeout=999999'`

`git config --global user.email "someone@gg.com"`
`git config --global user.name "Someone"`

`jupyter lab --ip=0.0.0.0 --LabApp.password='' --LabApp.token=''`

`http://localhost:8821/`

# Use Tensorflow directly:

`virtualenv cnn_env -p 3.8`

`source cnn_env/bin/activate`

`pip install tensorflow-gpu==2.3.1`

To use new version follow the following tutorail:
https://medium.com/mlearning-ai/tensorflow-2-4-with-cuda-11-2-gpu-training-fix-87f205215419

# Useful commands:
- `nvidia-smi` to check the GPU status
