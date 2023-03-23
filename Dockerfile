FROM occlum/occlum:latest-ubuntu20.04-conda as builder

WORKDIR /app

COPY . .

RUN ./python-occlum/bin/pip3 install -r requirement.txt && chmod u+x ./rest_api.py

RUN rm -rf occlum_instance && occlum new occlum_instance

WORKDIR /app/occlum_instance
RUN new_json="$(jq '.resource_limits.user_space_size = "640MB" | .resource_limits.kernel_space_heap_size = "256MB" | .env.default += ["PYTHONHOME=/opt/python-occlum"]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json


RUN rm -rf image && copy_bom -f ../occlum_python_ml_flask.yaml --root image --include-dir /opt/occlum/etc/template && occlum build
RUN occlum package --debug occlum_instance



FROM ubuntu:20.04

# Install SGX DCAP and Occlum runtime
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends gnupg wget ca-certificates jq && \
    echo 'deb [arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu focal main' | tee /etc/apt/sources.list.d/intel-sgx.list && \
    wget -qO - https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | apt-key add - && \
    echo 'deb [arch=amd64] https://occlum.io/occlum-package-repos/debian focal main' | tee /etc/apt/sources.list.d/occlum.list && \
    wget -qO - https://occlum.io/occlum-package-repos/debian/public.key | apt-key add - && \
    apt update && \
    apt install -y libsgx-uae-service && \
    apt install -y libsgx-dcap-ql && \
    apt install -y libsgx-dcap-default-qpl && \
    apt install -y occlum-runtime && \
    apt install -y libgl1-mesa-glx && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
ENV PATH="/opt/occlum/build/bin:/usr/local/occlum/bin:$PATH"

# Users need build their own applications and generate occlum package first.
#ARG OCCLUM_PACKAGE
#ADD $OCCLUM_PACKAGE /
COPY --from=builder /app/occlum_instance/occlum_instance.tar.gz /
# COPY --from=builder /app/docker-entrypoint.sh /usr/local/bin/
RUN tar -xvf /occlum_instance.tar.gz

ENV PCCS_URL="https://localhost:8081/sgx/certification/v3/"

#ENTRYPOINT ["docker-entrypoint.sh"]
WORKDIR /occlum_instance
