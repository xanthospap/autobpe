try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

config = {
    'description': 'Python module to accomodate routine GNSS processing at NTUA.',
    'author': 'xp, da, vz',
    'url': 'https://github.com/xanthospap/autobpe',
    'download_url': '',
    'author_email': 'xanthos@mail.ntua.gr, danast@mail.ntua.gr, vanzach@survey.ntua.gr',
    'version': '0.1',
    'packages': ['bernutils', 'bernutils.products'],
    'scripts': [],
    'name': 'bernpy'
}

setup(**config)
