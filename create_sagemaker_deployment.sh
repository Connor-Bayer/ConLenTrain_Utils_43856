#!/bin/bash

mlflow deployments create --target sagemaker:/eu-central-1 \
        --name sklearn-knn-dev \
        --model-uri ./mlruns/0/aeb9b09d16ee4f0aa656fc1bf89b9612/artifacts/knn \
        --flavor python_function\
        -C execution_role_arn=arn:aws:iam::516323849325:role/AmazonSageMaker-ExecutionRole-20231113 \
        -C bucket_name=mlops-training-dev \
        -C image_url=516323849325.dkr.ecr.eu-central-1.amazonaws.com/mlflow-pyfunc:2.8.0 \
        -C region_name=eu-central-1 \
        -C archive=False \
        -C instance_type=ml.m5.large \
        -C instance_count=1 \
        -C synchronous=True \
        -C timeout_seconds=600 \
        -C variant_name=dev-variant-1 
