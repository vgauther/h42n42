# Image officielle contenant OCaml + opam
FROM ocaml/opam:debian-12

# Utiliser bash -lc pour charger correctement l'environnement opam
SHELL ["/bin/bash", "-lc"]

# Pas de confirmation interactive pour opam
ENV OPAMYES=1

# Dossier de travail
WORKDIR /app
COPY . /app

# Installer les dépendances système nécessaires à Ocsigen/Eliom
RUN sudo apt-get update && sudo apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev libsqlite3-dev \
 && sudo rm -rf /var/lib/apt/lists/*

# Créer un switch OCaml 5.2.1 et installer Eliom + Ocsigenserver
RUN opam update \
 && opam switch create 5.2.1 \
 && eval $(opam env) \
 && opam install -y dune eliom ocsigenserver

# Compiler et installer le projet
RUN eval $(opam env) && make clean && make all && make install

# Le serveur écoute sur le port 80
EXPOSE 80

# Lancer le serveur (bytecode)
CMD ["bash", "-lc", "eval $(opam env) && make run.byte"]
