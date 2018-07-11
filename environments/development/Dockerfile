FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y ruby make perl
RUN cpan App::cpanminus
RUN cpanm Carton
USER jenkins
