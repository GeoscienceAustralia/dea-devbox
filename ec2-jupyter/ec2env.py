#!/usr/bin/env python3

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
    return {'ssm://'+x['Name']:x['Value'] for x in result['Parameters']}


if __name__ == '__main__':
    import sys
    from shlex import quote

    session = get_boto3_session()
    ssm = session.client('ssm')
    ec2 = session.resource('ec2')

    tags = {x['Key']:x['Value'] for x in this_instance(ec2=ec2).tags}

    args = [arg.split('=') for arg in sys.argv[1:]]
    ssm_keys = [t for e,t in args if t.startswith('ssm://')]

    if len(ssm_keys) > 0:
        tags.update(read_ssm_params(ssm_keys, ssm=ssm))

    for env_name, key in args:
        print('{}={}'.format(env_name, quote(tags.get(key,''))))
