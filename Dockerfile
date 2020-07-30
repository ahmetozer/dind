FROM debian as dindInstalling
WORKDIR /src
COPY . .
RUN ./docker-install.sh
CMD [ "/src/entrypoint.sh" ]