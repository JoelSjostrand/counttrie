from setuptools import find_packages
from glob import glob
from distutils.core import setup
from distutils.extension import Extension
try:
    from Cython.Distutils import build_ext
except ImportError:
    use_cython = False
else:
    use_cython = True
#from Cython.Distutils.extension import Extension
#from Cython.Distutils import build_ext
#from Cython.Build import cythonize


cmdclass = { }
ext_modules = [ ]


if use_cython:
    ext_modules += [
    Extension("counttrie.counttrie",   ["counttrie/counttrie.pyx"]),
    Extension("counttrie.trienode",   ["counttrie/trienode.pyx"])
    ]
    cmdclass.update({ 'build_ext': build_ext })
else:
    ext_modules += [
    Extension("counttrie.counttrie",   ["counttrie/counttrie.c"]),
    Extension("counttrie.trienode",    ["counttrie/trienode.c"])
    ]


setup(
	name="counttrie",
	version = '0.1.0',
	author = 'Joel Sjostrand',
	author_email = 'joel.sjostrand@gmail.com',
	license = 'Open BSD',
    description = 'Trie (prefix tree) implementation with some special features for e.g. bioinformatics',
    url = 'https://github.com/JoelSjostrand/counttrie',
    download_url = 'https://github.com/JoelSjostrand/counttrie/0.1.0',
	scripts = glob("scripts/*.py"),
    packages = ['counttrie'],
    package_data = {'': ['*.pyx', '*.pxd', '*.h', '*.c'], },
	install_requires = [
	    'setuptools',
	],
	test_suite = 'tests',
	cmdclass = cmdclass,
    ext_modules=ext_modules,
	include_dirs = ['.'],
    keywords = ['trie', 'prefix tree', 'bioinformatics']
    )
