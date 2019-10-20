from setuptools import setup, find_packages

setup(
    name="redis-to-minio",
    version="0.0.1",
    author="Yassir Sennoun",
    author_email="ysennoun@xebia.fr",
    description=("A sinker to copy message from redis to minIO"),
    license="BSD",
    keywords="IoT, Kubernetes, Redis, minIO",
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