from setuptools import setup, find_packages

setup(
    name="serverless",
    version="0.0.1",
    author="Yassir Sennoun",
    author_email="ysennoun@xebia.fr",
    description=("An IoT platform built on Kubernetes"),
    license="BSD",
    keywords="IoT, Kubernetes, Knative",
    url="https://github.com/ysennoun/smart-agriculture-with-k8s",
    packages=find_packages('src'),
    package_dir={'': 'src'},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Topic :: Utilities",
        "License :: OSI Approved :: BSD License",
    ],
    python_requires='>=3.7',
)