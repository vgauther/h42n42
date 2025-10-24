FROM ocaml/opam:debian-12

SHELL ["/bin/bash", "-lc"]
ENV OPAMYES=1

# Root pour paquets système et copie des sources
USER root
WORKDIR /app

# Dépendances système requises par Eliom/Ocsigen et toolchain
RUN apt-get update && apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*

# Copier le projet et donner les droits à l'utilisateur opam
COPY . /app
RUN chown -R opam:opam /app

# Passer à l'utilisateur opam pour opam et la compilation
USER opam

# Switch OCaml 5.2.1 + deps
RUN opam update \
 && opam switch create 5.2.1 \
 && eval $(opam env) \
 && opam install -y dune eliom ocsigenserver

# Build (toujours en opam)
RUN eval $(opam env) && make clean && make all

# Install (souvent écrit sous /usr/local -> besoin root)
USER root
RUN eval $(opam env) && make install \
 && mkdir -p /usr/local/var/log/h42n42 /usr/local/var/run/h42n42 \
 && chown -R opam:opam /usr/local/var/log/h42n42 /usr/local/var/run/h42n42 /usr/local/etc/h42n42

# Exposer le port configuré par la conf Ocsigen
EXPOSE 80

# Lancer en utilisateur non-root
USER opam
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
