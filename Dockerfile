FROM couchbase/server:community-4.1.0

MAINTAINER Derek Donnelly, derek@codex9.com

# Add bootstrap script
COPY scripts/entry.sh ./entry.sh
RUN chmod 755 ./entry.sh
ENTRYPOINT ["./entry.sh"]
CMD ["cluster-init"]