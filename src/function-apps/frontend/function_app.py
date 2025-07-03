import azure.functions as func
import logging
import requests
import os
import json
import cryptography
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="fa_adtest_frontend_trigger")
def fa_adtest_frontend_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    
    credential = DefaultAzureCredential()
    token = credential.get_token(os.getenv("BACKEND_CLIENT_ID"), tenant_id=os.getenv("TENANT_ID"))
    access_token = token.token
    logging.info("ACCESS TOKEN====")
    logging.info(access_token)


    apim_api_url = f"https://{os.getenv('APIM_NAME')}.azure-api.net/{os.getenv('BACKEND_NAME')}/{os.getenv('BACKEND_NAME')}_trigger"
    logging.info(apim_api_url)
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": os.getenv("APIM_SUBSCRIPTION_KEY"),
        "name": req.params.get('name')
    }

    response = requests.post(apim_api_url, headers=headers)
    logging.info("RESPONSE====")
    logging.info(response.status_code)
    logging.info(response.text)
    

    if response.status_code == 200:
        return func.HttpResponse(
            f"Backend call successful with status code: {response.status_code}. Response: {response.text}",
            status_code=200
        )
    else:
        return func.HttpResponse(
            f"Backend call failed with status code: {response.status_code}. Response: {response.text}",
            status_code=response.status_code
        )