FROM restreamio/gstreamer:2022-11-30T16-57-31Z-prod

RUN apt update
RUN apt install bc -y

COPY stream.sh /stream.sh
RUN chmod +x /stream.sh

CMD ["/stream.sh", "you"]
