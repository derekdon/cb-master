FROM couchbase/server:community-4.1.0

MAINTAINER Derek Donnelly, derek@codex9.com

# Add bootstrap script
COPY scripts/entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cluster-init"]