FROM swift:5.7.3-amazonlinux2 as builder
RUN yum -y update && \
    yum -y install git zip