## Note:

All files in this repo are from the mlops training file - this is my place to play with settings. See bayer's central repo for the full training materials.

# Bringing MLOps practices 
There are multiple tools that are helpful when introducing MLOps practices. In our use case [MLFlow](https://mlflow.org/) is going to act as an example. It is a real Swiss Knife of MLOps and it is going to exceed our needs.

We are goign to use this framework to track the experiments, set up pipelines, host a model registry and to deploy a model with ease (in multiple ways).

## Checking environment
To check the environment run the script prepared. One can use the commands listed below:
```bash
git clone https://github.com/deepsense-ai/MLOPS-Bayer-training # or use SSH
cd environment checks
source check_environment.sh‎
```

## Prerequisites
1. Ensure you are running Python 3.10.6.
2. Setup virtual environment (`python -m venv .venv`).
3. Activate the venv: `source .venv/bin/activate`.
3. Install requirements with `pip install -r requirements.txt`.

For each shell we are using we need environment variables. To set them run:
```bash
source mlflow_env_vars.sh
```
One can verify if ports are occupied with the following command:

```bash
netstat -anpe | grep <port_number> | grep LISTEN
```


## Running local MLFlow server instance
We specify artifact root and backend store URI. This makes it possible to store models.

After running this command tracking server will be accessible at `localhost:5000`

```bash
mlflow server --host 0.0.0.0 \
    --port 5000 \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./mlruns
```

## Specifying pipelines - `MLProject` file

When going beyond a single python script or Jupyter notebook we usually end up with some kind of pipeline.

With `MLproject` file we can define the pipeline steps (called *entrypoints*) as well as configure the environment. In our example each entrypoint in this file corresponds to a shell command.

Entry points can be ran using

```
mlflow run -e <ENTRYPOINT>
```

By default `mlflow run` command runs the `main` entrypoint. We are going to use Bike Sharing Dataset which can be downloaded from [here](https://archive.ics.uci.edu/ml/datasets/bike+sharing+dataset). This allows to define the download process as simple entrypoint using bash script. To perform the step run:


```bash
mlflow run .  -e download_data --env-manager=local
```

## Training
The training of kNN models for $k \in \{1, 2, ..., 10\}$ using *temperature* and *casual* features is the main step of a pipeline:
```bash
mlflow run . -e main --env-manager=local
```

Once it is run the Web UI of MLFlow will signal the need to refresh - afterwards one can see the runs for each training.


### Inspecting the models stored

The interaction with MLFlow is not limited to UI. The runs as well as trained models are stored in `mlruns/0`.
The directories contain artifacts and configuration files that are needed to serve the models of choice.

```bash
last_model_path=$(ls -tr mlruns/0/ | tail -1)
cat mlruns/0/$last_model_path/artifacts/knn/MLmodel
```

### Loading a model from registry into Python object
```python
model_uri = f"models:/{model_name}/latest"

model = mlflow.pyfunc.load_model(model_uri)
```

## Serving the model

Having chosen a model that suits our needs we can go to *Models* page on MLFLow UI (http://localhost:5000/#/models).

Click *sklearn_knn* on this page, choose a model and move it to *Production* stage.

The following command will serve the model at localhost on port 5001.

```bash
mlflow models serve -m models:/sklearn_knn/Production -p 5001 --env-manager=local
```

### Prediction

At this stage we can verify if the model is served properly and responds as expected.
We can predict for first winter day and first non-winter day (first rows of previously analyzed dataframes)

> **Warning: this might fail at first because the prediction server didn't spin up; in this case wait a minute**

```bash
data='[[0.344,331], [0.43, 401]]'
curl -d "{\"dataframe_records\": $data}" -H 'Content-Type: application/json' 127.0.0.1:5001/invocations
```

*Voila!* We see that the model outputs correct predictions.

## Preparing a container for deployment
One of the problems with just Jupyter notebooks is that they do not bring any information about environment. To make the solutions portable and independent of the setup one uses [Docker containers](https://www.docker.com/resources/what-container/) that are created based on *blueprints* - Docker images. Some MLOps tools (including MLFlow) provide the blueprints and build the images for you thus making the deployment even easier!
```bash
# Optional:
# mlflow models generate-dockerfile --env-manager=local

mlflow models build-docker --name "sklearn-knn-docker-image" --env-manager=local
```
The command above runs `docker build` command under the hood to prepare the image and make it usable both through Docker and MLFlow.

```bash
mlflow deployments run-local -t sagemaker --name sklearn_knn_deployment -m models:/sklearn_knn/Production -C image=sklearn-knn-docker-image -C port=5002
```

## Cloud deployment for inference
### Pushing the image to the cloud
The commands use `boto3` python package either explicitly or implicitly. This package is going to take care for the AWS authentication part. By default it is going to look for `AWS Access Key ID` and `AWS Secret Access Key` that were set with `aws configure` command.
```bash
mlflow sagemaker build-and-push-container
```
Once executed the command puts the docker image in remote Docker registry - [Amazon ECR](https://aws.amazon.com/ecr/).


### Running the containerized model in the cloud
Even if MLflow provides a means to deploy the model to [AWS Sagemaker](https://aws.amazon.com/sagemaker/) the command and parameters are lengthy enough to put them in a separate `create_sagemaker_deployment.sh`. We can display a list of deployments afterwards to see one created.
```bash
source create_sagemaker_deployment.sh
mlflow deployments list --target sagemaker:/eu-central-1
```
Testing of the deployment is handled by `get_inference_from_sagemaker.py` python script. The script sends a request to the [Sagemaker Endpoint](https://docs.aws.amazon.com/sagemaker/latest/dg/deploy-model.html#deploy-model-options). Run it to see that the deployment was successful and the predictions received are same as the ones obtained with local conainer deployment (expected as this is the same docker image).:
```bash
python get_inference_from_sagemaker.py 
```
Once you don't need it anymore delete the endpoint:
```bash
mlflow deployments delete --name sklearn-knn-dev
```
