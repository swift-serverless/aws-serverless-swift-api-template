FROM swift:6.2.0-amazonlinux2 as builder
RUN yum -y update && \
    yum -y install git zip