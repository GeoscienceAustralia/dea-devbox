import sys
import os
from shlex import quote
from . import (get_boto_session,
               this_instance,
               read_ssm_params,
               dns_update,
               dns_delete)


def main_update_dns(argv=None):
    if argv is None:
        argv = sys.argv

    if len(argv) > 1:
        domain = argv[1]
    else:
        domain = os.environ.get('DOMAIN', None)

    ip = argv[2] if len(argv) > 2 else None

    if domain is None:
        print('No domain supplied')
        sys.exit(1)

    if ip == 'delete':
        action = 'delete'
        r = dns_delete(domain)
    else:
        action = 'update'
        r = dns_update(domain, ip)

    if not r:
        print('Failed to {} DNS: {}'.format(action, domain))
        sys.exit(2)


def main_ec2env(argv=None):
    if argv is None:
        argv = sys.argv

    session = get_boto_session()
    ssm = session.create_client('ssm')
    ec2 = session.create_client('ec2')

    instance = this_instance(ec2=ec2)

    if instance is None:
        tags = {}
    else:
        tags = {x['Key']: x['Value'] for x in instance.get('Tags', [])}

    args = [arg.split('=') for arg in argv[1:]]
    ssm_keys = [t for e, t in args if t.startswith('ssm://')]

    if len(ssm_keys) > 0:
        tags.update(read_ssm_params(ssm_keys, ssm=ssm))

    for env_name, key in args:
        print('{}={}'.format(env_name, quote(tags.get(key, ''))))


def main_dispatch():
    """ busybox-style dispatcher call either
         - ec2env        -> main_ec2env
         - ec2update_dns -> main_update_dns

         based on the name of the executable being invoked
    """
    progs = dict(ec2env=main_ec2env,
                 ec2update_dns=main_update_dns)

    prog_name = sys.argv[0].split('/')[-1]
    main = progs.get(prog_name, None)

    if main is not None:
        return main()

    if len(sys.argv) < 2:
        print("Not sure what to run: {}".format(prog_name))
        sys.exit(1)

    prog_name = sys.argv[1]
    main = progs.get(prog_name, None)

    if main is not None:
        argv = sys.argv[1:]
        return main(argv)

    print("Not sure what to run: {}".format(prog_name))
    sys.exit(1)
