FROM ocaml/opam:debian-12
SHELL ["/bin/bash","-lc"]
ENV OPAMYES=1

# root: paquets de base
USER root
WORKDIR /app
RUN apt-get update && apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev \
    libsqlite3-dev libgdbm-dev && \
    rm -rf /var/lib/apt/lists/*

# sources
COPY . /app
RUN chown -R opam:opam /app

# opam (user non-root)
USER opam

# Dépôt Ocsigen + switch 5.2.1 + depext + install des deps Eliom/Ocsigen
RUN opam repo add ocsigen https://github.com/ocsigen/opam-repository.git || true && \
    opam update && \
    opam switch create 5.2.1 && eval $(opam env) && \
    opam install -y opam-depext && \
    opam depext -iy eliom ocsigenserver ocsipersist-dbm && \
    opam install -y dune eliom ocsigenserver ocsipersist-dbm

# Build
RUN eval $(opam env) && make clean && make all

# Install (root si nécessaire)
USER root
RUN eval $(opam env) && make install || true

# Dossiers logs/run accessibles
RUN mkdir -p /app/local/var/log/h42n42 /app/local/var/run && \
    chown -R opam:opam /app/local/var

# Patch auto des .conf (où qu'ils soient)
RUN set -eux; \
  confs="$( { test -d /usr/local/etc/h42n42 && find /usr/local/etc/h42n42 -maxdepth 1 -name '*.conf' || true; }; \
            { test -d /app/local/etc/h42n42 && find /app/local/etc/h42n42 -maxdepth 1 -name '*.conf' || true; } )"; \
  for f in $confs; do \
    sed -i 's#/usr/local/var/log/h42n42#/app/local/var/log/h42n42#g' "$f"; \
    sed -i 's#/usr/local/var/run/h42n42#/app/local/var/run/h42n42#g' "$f"; \
    sed -i 's#/usr/local/var/run/h42n42-cmd#/app/local/var/run/h42n42-cmd#g' "$f"; \
    sed -i '/<user>.*<\/user>/d; /<group>.*<\/group>/d' "$f"; \
  done || true; \
  chown -R opam:opam /usr/local/etc/h42n42 || true

EXPOSE 80

# Lancement en user opam
USER opam
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
