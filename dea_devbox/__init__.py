"""
Tools for dea devbox setup
"""
import requests

def get_boto3_session():
    """ Get session with correct region
    """
    import boto3
    region = requests.get('http://169.254.169.254/latest/meta-data/hostname').text.split('.')[1]
    return boto3.Session(region_name=region)


def this_instance(ec2=None):
    """ Get EC2 instance for current instance
    """
    if ec2 is None:
        ec2 = get_boto3_session().resource('ec2')

    iid = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    return ec2.Instance(iid)

def public_ip():
    return requests.get('http://instance-data/latest/meta-data/public-ipv4').text


def update_dns(domain, ip=None, route53=None, ttl=300):
    def find_zone_id(domain):
        zone_name = '.'.join(domain.split('.')[1:])
        zone_name = zone_name.rstrip('.') + '.'
        rr = route53.list_hosted_zones()
        for z in rr['HostedZones']:
            if z['Name'] == zone_name:
                return z['Id']

        return None

    if route53 is None:
        route53 = get_boto3_session().client('route53')

    domain = domain.rstrip('.') + '.'
    zone_id = find_zone_id(domain)
    if zone_id is None:
        return False

    if ip is None:
        ip = public_ip()

    update = {
        'Name': domain,
        'Type': 'A',
        'TTL' : ttl,
        'ResourceRecords': [{'Value': ip}]
    }
    changes = {"Changes": [{"Action": "UPSERT",
                            "ResourceRecordSet": update}]}

    rr = route53.change_resource_record_sets(HostedZoneId=zone_id,
                                             ChangeBatch=changes)

    return rr['ResponseMetadata']['HTTPStatusCode'] == 200


def read_ssm_params(params, ssm):
    """Build dictionary from SSM keys in the form `ssm://{key}` to value in the
    paramater store.
    """
    result = ssm.get_parameters(Names=[s[len('ssm://'):] for s in params],
                                WithDecryption=True)
    if result['InvalidParameters']:
        raise ValueError('Failed to lookup some keys: ' + ','.join(result['InvalidParameters']))
    return {'ssm://'+x['Name']: x['Value'] for x in result['Parameters']}


def maybe_ssm(*args):
    """ For every string in the form `ssm://{parameter-name}` lookup `{parameter-name}` in SSM,
        pass through the rest
    """
    ssm_params = [s for s in args if (s is not None) and s.startswith('ssm://')]

    if not ssm_params:
        return tuple(args)

    ssm = get_boto3_session().client('ssm')
    mm = read_ssm_params(ssm_params, ssm)
    return tuple(mm.get(s, s) for s in args)


def system_user_exists(username):
    """ Check if username exists
    """
    import pwd
    try:
        pwd.getpwnam(username)
    except KeyError:
        return False

    return True
