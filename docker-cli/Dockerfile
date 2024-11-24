FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update

RUN apt-get -y install wget ca-certificates
RUN apt-get -y install gnupg
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" >>  /etc/apt/sources.list.d/pgdg.list
# RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

RUN apt-get -y update && apt-get -y upgrade

RUN apt-get -y install curl unzip ssh apt-transport-https gnupg software-properties-common jq sudo groff
RUN apt-get -y install less
RUN apt-get -y install gcc python3 python3-pip rsync
RUN apt-get -y install git

RUN apt-get -y install postgresql-client

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get -y update && apt-get -y install terraform

RUN pip3 install --upgrade pip; \
    pip3 install --upgrade virtualenv; \
    pip3 install pywinrm[kerberos]; \
    pip3 install pywinrm; \
    pip3 install jmspath; \
    pip3 install requests; \
    python3 -m pip install ansible;

# RUN pip3 install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN rm awscliv2.zip

RUN pip3 install checkov

RUN useradd --shell /bin/bash --groups sudo --create-home tf_user
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN touch /home/tf_user/.sudo_as_admin_successful

RUN mkdir /home/tf_user/.ssh && chown tf_user:tf_user /home/tf_user/.ssh && chmod 700 /home/tf_user/.ssh

COPY entrypoint.sh /home/tf_user/entrypoint.sh
RUN chown tf_user:tf_user /home/tf_user/entrypoint.sh
RUN chmod +x /home/tf_user/entrypoint.sh

USER tf_user
CMD /home/tf_user/entrypoint.sh


