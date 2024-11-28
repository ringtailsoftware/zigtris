FROM alpine:3.17
WORKDIR /app
ENV SSHUSER=zigtris
# The SSH user to create
RUN echo "/bin/zigtris" > /etc/shells
RUN apk --no-cache add dropbear &&\
    mkdir -p /home/$SSHUSER/.ssh &&\
    adduser -s /bin/sh -D $SSHUSER --home /home/$SSHUSER --shell /bin/zigtris &&\
    chown -R $SSHUSER:$SSHUSER /home/$SSHUSER
RUN echo 'zigtris:' | chpasswd
RUN echo -e "https://github.com/ringtailsoftware/zigtris\r\nUse empty password" > /etc/banner
COPY zig-out/bin/zigtris /bin/zigtris
CMD ["/bin/sh", "-c", "/usr/sbin/dropbear -RFEwgjk -G ${SSHUSER} -p 22 -b /etc/banner"]

