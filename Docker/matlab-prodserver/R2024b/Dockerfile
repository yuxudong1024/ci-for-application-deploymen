# Copyright 2019 - 2022 The MathWorks, Inc.

# To specify which MATLAB release to install in the container, edit the value of the MATLAB_RELEASE argument.
# Use lower case to specify the release, for example: ARG MATLAB_RELEASE=r2022a

ARG MATLAB_RELEASE=r2024b
ARG RUNTIME_URL=https://ssd.mathworks.com/supportfiles/downloads/R2024b/Release/0/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2024b_glnxa64.zip
ARG AGREE_TO_LICENSE=yes
ARG RUNTIME_VERSION=R2024b
ARG LICENSE_SERVER=27000@20.0.1.128

# When you start the build stage, this Dockerfile by default uses the Ubuntu-based matlab-deps image.
# To check the available matlab-deps images, see: https://hub.docker.com/r/mathworks/matlab-deps
# However, since this is release R2022b, so the TAG for r2022b is not exist yet
FROM mathworks/matlab-deps:${MATLAB_RELEASE}
ENV MATLAB_BASE /usr/local/MATLAB
ENV PROD_SERVER_ROOT /usr/local/MATLAB/MATLAB_Production_Server/R2024b
ENV MATLAB_RUNTIME_ROOT /usr/local/MATLAB/MATLAB_Runtime

# Declare the global argument to use at the current build stage
ARG AGREE_TO_LICENSE
ARG RUNTIME_URL
ARG MATLAB_RELEASE
ARG RUNTIME_VERSION
ARG LICENSE_SERVER

# Install mpm dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && \
    apt-get install --no-install-recommends --yes \
        wget \
        unzip \
        ca-certificates && \
    apt-get clean && apt-get autoremove

# Run mpm to install MATLAB Production Server in the target location and delete the mpm installation afterwards
RUN mkdir -p ${PROD_SERVER_ROOT}
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm && \
    ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=${PROD_SERVER_ROOT} \
        --products MATLAB_Production_Server && \
    rm -f mpm /tmp/mathworks_root.log 

# Add a user other than root to run Production Server
RUN useradd -ms /bin/bash matlab

# Copy existing preinstalled MATLAB Runtime (Since it's pre-release) to image
# Install MATLAB Runtime
WORKDIR /matlab-runtime
RUN wget -q  ${RUNTIME_URL} && \
    unzip -q *.zip && \
    ./install \
        -mode silent \
        -agreeToLicense ${AGREE_TO_LICENSE} \
        -destinationFolder ${MATLAB_RUNTIME_ROOT} && \
    cd / && \
    rm -rf /matlab-runtime

# Add bless that user with sudo powers
RUN echo "matlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/matlab \
    && chmod 0440 /etc/sudoers.d/matlab \ 
    && chown -R matlab:matlab ${PROD_SERVER_ROOT}

#FROM base-stage as deploy-stage 

ENV PROD_SERVER_INSTANCE /opt/mpsinstance/mps
ENV PROD_SERVER_CONFIG ${PROD_SERVER_INSTANCE}/config/
ENV START_REDIS_SERVER true

RUN chown matlab:matlab /opt

USER matlab
WORKDIR /home/matlab

RUN mkdir -p /opt/mpsinstance
COPY startmps.sh stopmps.sh /opt/

COPY main_config /opt
COPY mps_cache_config /opt

ENTRYPOINT ["/opt/startmps.sh"]
EXPOSE 9910
# Copyright 2019-2022 The MathWorks, Inc.
