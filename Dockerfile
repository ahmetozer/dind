FROM alpine as dindInstalling
WORKDIR /src
COPY . .
RUN chmod +x *.sh && \
./docker-install.sh
CMD [ "/src/entrypoint.sh" ]