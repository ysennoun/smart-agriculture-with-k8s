from setuptools import setup, find_packages

setup(
    name="device code",
    version="0.0.1",
    author="Yassir Sennoun",
    author_email="ysennoun@xebia.fr",
    description=("An IoT platform built on Kubernetes"),
    license="BSD",
    keywords="IoT, Kubernetes",
    url="https://gitlab.com/ysennoun/smart-agriculture-with-k8s",
    packages=find_packages('src'),
    package_dir={'': 'src'},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Topic :: Utilities",
        "License :: OSI Approved :: BSD License",
    ],
    package_data={
        # If any package contains clientId files, include them:
        '': ['clientId'],
    },
    python_requires='>=3.7',
)
