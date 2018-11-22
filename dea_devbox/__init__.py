"""
Tools for dea devbox setup
"""
import botocore
import botocore.session
from urllib.request import urlopen
import json


def _fetch_text(url, timeout=0.1):
    try:
        with urlopen(url, timeout=timeout) as resp:
            if 200 <= resp.getcode() < 300:
                return resp.read().decode('utf8')
            else:
                return None
    except IOError:
        return None


def ec2_metadata(timeout=0.1):
    txt = _fetch_text('http://169.254.169.254/latest/dynamic/instance-identity/document', timeout)

    if txt is None:
        return None

    try:
        return json.loads(txt)
    except json.JSONDecodeError:
        return None


def public_ip():
    return _fetch_text('http://instance-data/latest/meta-data/public-ipv4')


def ec2_current_region():
    cfg = ec2_metadata()
    if cfg is None:
        return None
    return cfg.get('region', None)


def botocore_default_region(session=None):
    if session is None:
        session = botocore.session.get_session()
    return session.get_config_variable('region')


def auto_find_region(session=None):
    region_name = botocore_default_region(session)

    if region_name is None:
        region_name = ec2_current_region()

    if region_name is None:
        raise ValueError('Region name is not supplied and default can not be found')

    return region_name


def get_boto_session(region_name=None):
    """ Get session with correct region
    """

    if region_name is None:
        region_name = auto_find_region()

    return botocore.session.Session(session_vars=dict(
        region=('region', 'AWS_DEFAULT_REGION', region_name, None)))


def this_instance(ec2=None):
    """ Get dictionary of parameters describing current instance
    """
    if ec2 is None:
        ec2 = get_boto_session().create_client('ec2')

    info = ec2_metadata()
    if info is None:
        return None

    iid = info['instanceId']

    rr = ec2.describe_instances(InstanceIds=[iid])
    rr = rr['Reservations'][0]['Instances'][0]
    return rr


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
        route53 = get_boto_session().create_client('route53')

    domain = domain.rstrip('.') + '.'
    zone_id = find_zone_id(domain)
    if zone_id is None:
        return False

    if ip is None:
        ip = public_ip()

    update = {
        'Name': domain,
        'Type': 'A',
        'TTL': ttl,
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

    ssm = get_boto_session().create_client('ssm')
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
