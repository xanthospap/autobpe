try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

config = {
    'description': 'Python modules to accomodate Bernese5.2 wrappers.',
    'author': 'xp, da',
    'url': 'https://github.com/xanthospap/autobpe',
    'download_url': '',
    'author_email': 'xanthos@mail.ntua.gr, danast@mail.ntua.gr',
    'version': '0.1',
    'packages': ['bernutils'],
    'scripts': [],
    'name': 'bernpy'
}

setup(**config)
