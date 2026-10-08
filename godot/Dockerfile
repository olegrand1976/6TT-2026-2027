FROM barichello/godot-ci:4.7.2

# Godot cherche fontconfig meme en headless : sans ce paquet, chaque demarrage
# journalise « libfontconfig.so.1: cannot open shared object file ».
RUN apt-get update \
    && apt-get install -y --no-install-recommends libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /project

COPY prepare-stack.sh entrypoint-headless.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/prepare-stack.sh /usr/local/bin/entrypoint-headless.sh

COPY . .

EXPOSE 8999

# --headless : aucun serveur d'affichage requis ; main.gd en deduit qu'il doit
#              endosser le role de serveur dedie.
# --path     : lance le projet situe la (main_scene de project.godot).
ENTRYPOINT ["/usr/local/bin/entrypoint-headless.sh"]
CMD ["godot", "--headless", "--path", "/project"]
