from setuptools import setup, find_packages

setup(
    name='dea-devbox',
    version='0.2',
    license='Apache License 2.0',
    url='https://github.com/GeoscienceAustralia/dea-devbox/',
    packages=find_packages(),
    include_package_data=True,
    author='Kirill Kouzoubov',
    author_email='kirill.kouzoubov@ga.gov.au',
    description='Misc tools to assist in setup of devboxes for DEA',
    python_requires='>=3.5',
    install_requires=['botocore'],
    tests_require=['pytest'],
    extras_require=dict(),
    entry_points={
        'console_scripts': [
            'ec2env = dea_devbox.cli:main_ec2env',
            'ec2update_dns = dea_devbox.cli:main_update_dns',
        ],
    }
)
