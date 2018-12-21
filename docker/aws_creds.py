import botocore.session


def main():
    session = botocore.session.get_session()
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

    region = session.get_config_variable('region')
    if region is not None:
        print("export AWS_DEFAULT_REGION='{}'".format(region))


if __name__ == '__main__':
    main()
