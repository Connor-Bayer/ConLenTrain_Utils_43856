import boto3
import json


if __name__ == "__main__":
    endpoint = "sklearn-knn-dev"
    client = boto3.client("sagemaker-runtime")

    response = client.invoke_endpoint(EndpointName=endpoint, ContentType="application/json", Body='{"dataframe_records":[[0.344,331], [0.43, 401]]}')
    print(str(json.loads(response["Body"].read())))