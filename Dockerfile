FROM Debian as dindInstalling
WORKDIR /src
COPY . .
RUN docker-install.sh
ENTRYPOINT [ "/src/entrypoint.sh" ]