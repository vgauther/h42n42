FROM ocaml/opam:debian-12
SHELL ["/bin/bash","-lc"]
ENV OPAMYES=1 OPAMJOBS=2

# ---- root: dépendances système (toolchain + libs) ----
USER root
WORKDIR /app
RUN apt-get update && apt-get install -y \
    build-essential gcc g++ libc6-dev \
    m4 patch pkg-config make rsync unzip git curl ca-certificates \
    libssl-dev libgmp-dev libpcre3-dev zlib1g-dev \
    libsqlite3-dev libgdbm-dev libev-dev \
 && rm -rf /var/lib/apt/lists/*

# Sources du projet
COPY . /app
RUN chown -R opam:opam /app

# ---- opam: switch 5.2.1 + pins récents ----
USER opam
RUN opam update && opam switch create 5.2.1 && eval $(opam env)
RUN opam install -y opam-depext dune

# Pins Git (plus frais que l’index par défaut)
RUN opam pin -n add eliom           https://github.com/ocsigen/eliom.git && \
    opam pin -n add ocsigenserver   https://github.com/ocsigen/ocsigenserver.git && \
    opam pin -n add ocsipersist     https://github.com/ocsigen/ocsipersist.git

# Dépendances natives + install librairies
RUN eval $(opam env) && \
    opam depext -iy eliom ocsigenserver ocsipersist ocsipersist-dbm && \
    opam install -y  eliom ocsigenserver ocsipersist-dbm

# ---- Build / install du projet ----
RUN eval $(opam env) && make clean && make all

USER root
RUN eval $(opam env) && make install || true

# ---- Répertoires logs/run accessibles et patch conf ----
RUN mkdir -p /app/local/var/log/h42n42 /app/local/var/run && \
    chown -R opam:opam /app/local/var

# Patch des .conf (usr/local & local), suppression <user>/<group>
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
USER opam
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
