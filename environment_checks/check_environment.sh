#!/bin/bash

# Function to check if a command exists
command_exists () {
    type "$1" &> /dev/null ;
}

am_i_in_venv () {
echo $(python <<EOF
import sys
if sys.prefix == sys.base_prefix:
    print("No, you are not in a virtual environment.")
else:
    print("Yes, you are in a virtual environment.")
EOF
)
}

# Check for Python with a specific version
desired_python_version="3.10.6" # replace with your actual version
if command_exists python; then
    python_version=$(python --version 2>&1 | awk '{print $2}')
    if [[ $python_version == *$desired_python_version* ]]; then
        echo "Python is installed with version $desired_python_version"
    else
        echo "Python is installed, but not with version $desired_python_version"
    fi
else
    echo "Python is not installed"
fi

# Check for Python packages
packages=("boto3" "fire" "mlflow")
versions=("1.28.84" "0.5.0" "2.8.0") # replace with your actual versions

for i in ${!packages[@]}; do
    package_version=$(python -c "import ${packages[$i]}; print(${packages[$i]}.__version__)" 2>&1)
    if [[ $package_version == *${versions[$i]}* ]]; then
        echo "${packages[$i]} is installed with version ${versions[$i]}"
    else
        echo "${packages[$i]} is not installed with version ${versions[$i]}"
    fi
done

# Check for Docker with a specific version
desired_docker_version="24.0.7" # replace with your actual version
if command_exists docker; then
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    if [[ $docker_version == *$desired_docker_version* ]]; then
        echo "Docker is installed with version $desired_docker_version"
    else
        echo "Docker is installed, but not with version $desired_docker_version"
    fi
else
    echo "Docker is not installed"
fi

am_i_in_venv

echo "Setting up and activating Virtual Environment."
python -m venv .venv-mlops-training
source .venv-mlops-training/bin/activate
am_i_in_venv

pip install -q -r ../requirements.txt

# Check for Python packages
packages=("boto3" "fire" "mlflow")
versions=("1.28.84" "0.5.0" "2.8.0") # replace with your actual versions

for i in ${!packages[@]}; do
    package_version=$(python -c "import ${packages[$i]}; print(${packages[$i]}.__version__)" 2>&1)
    if [[ $package_version == *${versions[$i]}* ]]; then
        echo "${packages[$i]} is installed with version ${versions[$i]}"
    else
        echo "${packages[$i]} is not installed with version ${versions[$i]}"
    fi
done

deactivate
rm -rf .venv-mlops-training
echo "Virtual Environment deactivated and removed"

docker build -t env-testing-docker-build --no-cache .

if [ $? -eq 0 ]; then
    echo "Docker build succeeded"
else
    echo "Docker build failed"
fi

docker rmi -f env-testing-docker-build
