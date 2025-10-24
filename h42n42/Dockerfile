FROM ocaml/opam:debian-12

SHELL ["/bin/bash", "-lc"]
ENV OPAMYES=1

USER root
WORKDIR /app

# Deps système (ajout de libgdbm-dev pour ocsipersist-dbm)
RUN apt-get update && apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev \
    libsqlite3-dev libgdbm-dev \
 && rm -rf /var/lib/apt/lists/*

# Copier le projet
COPY . /app
# Donner l'app à l'utilisateur opam
RUN chown -R opam:opam /app

USER opam

# Switch OCaml 5.2.1 + deps opam (ajout ocsipersist-dbm)
RUN opam update \
 && opam switch create 5.2.1 \
 && eval $(opam env) \
 && opam install -y dune eliom ocsigenserver ocsipersist-dbm

# Build
RUN eval $(opam env) && make clean && make all

# Install (root si nécessaire)
USER root
RUN eval $(opam env) && make install

# --- Rendre la conf et les répertoires utilisables par 'opam' ---
# Dossiers de log/run sous /app (writable)
RUN mkdir -p /app/local/var/log/h42n42 /app/local/var/run \
 && chown -R opam:opam /app/local/var

# Patcher la conf installée pour pointer vers /app/local/var/...
# (Log dir, PID file, command_pipe) + retirer <user>/<group>
RUN CONF="/usr/local/etc/h42n42/h42n2*.conf" ; \
    for f in $CONF; do \
      sed -i 's#/usr/local/var/log/h42n42#/app/local/var/log/h42n42#g' "$f"; \
      sed -i 's#/usr/local/var/run/h42n42#/app/local/var/run/h42n42#g' "$f"; \
      sed -i 's#/usr/local/var/run/h42n42-cmd#/app/local/var/run/h42n42-cmd#g' "$f"; \
      # supprimer balises <user> et <group> (dépréciées)
      sed -i '/<user>.*<\/user>/d; /<group>.*<\/group>/d' "$f"; \
    done

# Donner la conf à opam
RUN chown -R opam:opam /usr/local/etc/h42n42

EXPOSE 80

# Lancer en 'opam' avec l'env opam chargé
USER opam
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
