> NOTE: Below is tested on WSL2 with Ubuntu 24.04.2 LTS

* Check CUDA
    ```
    nvcc --version
    ```
* Install `nvidia-cuda-toolkit` if not found
    ```
    sudo apt install nvidia-cuda-toolkit
    ```
* Also HDF5
    ```
    sudo apt install libhdf5-dev hdf5-tools
    ```
* 
    ```
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    ```
