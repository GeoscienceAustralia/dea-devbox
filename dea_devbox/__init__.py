"""
Tools for dea devbox setup
"""

def get_boto3_session():
    import requests
    import boto3
    region = requests.get('http://169.254.169.254/latest/meta-data/hostname').text.split('.')[1]
    return boto3.Session(region_name=region)


def this_instance(ec2=None):
    import requests
    if ec2 is None:
        ec2 = get_boto3_session().resource('ec2')

    iid = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    return ec2.Instance(iid)


def read_ssm_params(params, ssm):
    result = ssm.get_parameters(Names=[s[len('ssm://'):] for s in params],
                                WithDecryption=True)
    if len(result['InvalidParameters']) > 0:
        raise ValueError('Failed to lookup some keys: ' + ','.join(result['InvalidParameters']))
    return {'ssm://'+x['Name']: x['Value'] for x in result['Parameters']}


def maybe_ssm(*args):
    """ For every string in the form `ssm://{parameter-name}` lookup `{parameter-name}` in SSM,
        pass through the rest
    """
    ssm_params = [s for s in args if (s is not None) and s.startswith('ssm://')]

    if len(ssm_params) == 0:
        return tuple(args)

    ssm = get_boto3_session().client('ssm')
    mm = read_ssm_params(ssm_params, ssm)
    return tuple(mm.get(s, s) for s in args)


def system_user_exists(username):
    import pwd
    try:
        pwd.getpwnam(username)
    except KeyError:
        return False

    return True

