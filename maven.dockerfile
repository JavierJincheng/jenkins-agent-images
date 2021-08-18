ARG JDK_IMAGE=ccr.ccs.tencentyun.com/tapd-devops/tencentkona11:1.0.0
ARG MAVEN_IMAGE=maven:3.6.3-openjdk-11-slim
FROM ${MAVEN_IMAGE} AS MAVEN
FROM ${JDK_IMAGE}

ARG VERSION=4.10
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN addgroup -g ${gid} ${group} \
 && adduser -h /home/${user} -u ${uid} -G ${group} -D ${user}
LABEL Description="This is a base image with maven tool, which provides the Jenkins agent executable (slave.jar) and mvn cmd" Vendor="Javier" Version="${VERSION}"

ARG AGENT_WORKDIR=/home/${user}/agent
ARG MAVEN_CONFIG=/home/${user}/.m2

COPY --from=MAVEN --chown=jenkins:jenkins /usr/share/maven /usr/share/maven

RUN echo -e https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/main/ > /etc/apk/repositories \
  && echo -e https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/community/ >> /etc/apk/repositories \ 
  && apk add --update --no-cache curl bash git git-lfs openssh-client openssl procps \
  && curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar \
  && apk del curl \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn  

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR} \
    MAVEN_HOME=/usr/share/maven \
    MAVEN_CONFIG=${AGENT_WORKDIR}

RUN mkdir /home/${user}/.jenkins \
 && mkdir -p ${MAVEN_CONFIG}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
VOLUME ${MAVEN_CONFIG}
WORKDIR /home/${user}
