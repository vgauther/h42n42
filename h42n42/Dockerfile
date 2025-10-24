FROM ocaml/opam:debian-12

SHELL ["/bin/bash", "-lc"]
ENV OPAMYES=1

# On passe root pour installer les paquets et copier les sources
USER root
WORKDIR /app

# Dépendances système
RUN apt-get update && apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*

# Copier le projet puis donner les droits à l'user opam
COPY . /app
RUN chown -R opam:opam /app

# Revenir à l'utilisateur opam pour opam + build
USER opam

# Créer le switch 5.2.1 et installer les deps
RUN opam update \
 && opam switch create 5.2.1 \
 && eval $(opam env) \
 && opam install -y dune eliom ocsigenserver

# Build (en user opam)
RUN eval $(opam env) && make clean && make all

# Install (souvent écrit dans /usr/local -> besoin root)
USER root
RUN eval $(opam env) && make install

# Exposition du port
EXPOSE 80

# Revenir en opam pour lancer
USER opam
CMD ["bash", "-lc", "eval $(opam env) && make run.byte"]
