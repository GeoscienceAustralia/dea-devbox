import boto3

session = boto3.Session()
creds = session.get_credentials().get_frozen_credentials()

env_mapping = dict(
    AWS_ACCESS_KEY_ID='access_key',
    AWS_SECRET_ACCESS_KEY='secret_key',
    AWS_SESSION_TOKEN='token')

for e, p in env_mapping.items():
    if hasattr(creds, p):
        val = getattr(creds, p)
        if val is not None:
            print("export {e}='{val}'".format(e=e, val=val))
