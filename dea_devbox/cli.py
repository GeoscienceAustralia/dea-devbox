from . import get_boto3_session, this_instance, read_ssm_params


def main_ec2env():
    import sys
    from shlex import quote

    session = get_boto3_session()
    ssm = session.client('ssm')
    ec2 = session.resource('ec2')

    tags = {x['Key']: x['Value'] for x in this_instance(ec2=ec2).tags}

    args = [arg.split('=') for arg in sys.argv[1:]]
    ssm_keys = [t for e, t in args if t.startswith('ssm://')]

    if len(ssm_keys) > 0:
        tags.update(read_ssm_params(ssm_keys, ssm=ssm))

    for env_name, key in args:
        print('{}={}'.format(env_name, quote(tags.get(key, ''))))
