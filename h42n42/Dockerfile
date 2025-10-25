FROM ocaml/opam:debian-12
SHELL ["/bin/bash","-lc"]
ENV OPAMYES=1 OPAMJOBS=2

# ---- Choix de la version d'OCaml (par défaut 5.2.0, plus compatible aujourd'hui) ----
ARG OCAML_VERSION=5.2.0

# ---- root: dépendances système ----
USER root
WORKDIR /app
RUN apt-get update && apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev \
    libsqlite3-dev libgdbm-dev curl ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# Sources
COPY . /app
RUN chown -R opam:opam /app

# ---- opam: switch + dépôts ----
USER opam
# Ajout du repo Ocsigen (prioritaire) + create switch
RUN opam repo add ocsigen https://github.com/ocsigen/opam-repository.git || true && \
    opam update && \
    opam switch create ${OCAML_VERSION} && eval $(opam env)

# Outils
RUN opam install -y opam-depext dune

# Dépendances Eliom/Ocsigen (depext + install)
RUN eval $(opam env) && \
    opam depext -iy eliom ocsigenserver ocsipersist ocsipersist-dbm && \
    opam install -y eliom ocsigenserver ocsipersist-dbm

# ---- Build / Install du projet ----
RUN eval $(opam env) && make clean && make all

USER root
RUN eval $(opam env) && make install || true

# ---- Répertoires logs/run utilisables par 'opam' ----
RUN mkdir -p /app/local/var/log/h42n42 /app/local/var/run && \
    chown -R opam:opam /app/local/var

# ---- Patch auto des .conf (usr/local ou local) ----
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
