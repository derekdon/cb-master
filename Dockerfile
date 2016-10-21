FROM couchbase/server:community-4.1.0

MAINTAINER Derek Donnelly, derek@codex9.com

# Add bootstrap script
COPY scripts/entry.sh /opt/bin/entry.sh
RUN chmod 755 /opt/bin/entry.sh
ENTRYPOINT ["/opt/bin/entry.sh"]
CMD ["cluster-init"]