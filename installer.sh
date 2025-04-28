#!/bin/bash

# === CONFIGURATION ===
PROJECT_REPO="https://github.com/charlesvdd/neosaas-dev.git"
INSTALL_DIR="$HOME/.local/share/neosaas"
BIN_DIR="$HOME/.local/bin"

# === COLORS ===
GREEN="\033[32m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

# === FONCTIONS ===
die() {
    printf "${RED}%b${RESET}\n" "$@" >&2
    exit 1
}

info() {
    printf "%b\n" "$@"
}

create_dir_if_missing() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1" || die "Impossible de créer le dossier $1."
    fi
}

check_or_install_pnpm() {
    if ! command -v pnpm &> /dev/null; then
        info "pnpm n'est pas installé, tentative d'installation..."
        npm install -g pnpm || die "Impossible d'installer pnpm, merci de le faire manuellement."
    fi
}

clone_or_update_repo() {
    if [ ! -d "$INSTALL_DIR" ]; then
        git clone "$PROJECT_REPO" "$INSTALL_DIR" || die "Échec du clonage du projet."
    else
        cd "$INSTALL_DIR" || die "Impossible d'entrer dans $INSTALL_DIR."
        git pull || die "Échec de la mise à jour du projet."
    fi
}

install_dependencies() {
    cd "$INSTALL_DIR" || die "Dossier projet introuvable."
    pnpm install || die "Échec de l'installation des dépendances."
}

create_neosaas_command() {
    create_dir_if_missing "$BIN_DIR"
    echo "#!/bin/bash
cd \"$INSTALL_DIR\"
pnpm dev" > "$BIN_DIR/neosaas"
    chmod +x "$BIN_DIR/neosaas"

    if ! grep -q "$BIN_DIR" <<< "$PATH"; then
        info "\n${RED}ATTENTION${RESET}: '$BIN_DIR' n'est pas dans ton PATH. Ajoute ceci à ton ~/.bashrc ou ~/.zshrc :"
        info "    ${BOLD}export PATH=\$PATH:$BIN_DIR${RESET}"
    fi
}

update_main_neosaas() {
    cd "$INSTALL_DIR" || die "Dossier projet introuvable."

    LAST_UPDATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    GIT_COMMIT=$(git rev-parse --short HEAD)
    DEPENDENCIES_COUNT=$(pnpm list --depth=0 | grep -v "deduped" | wc -l)
    PROJECT_NAME=$(basename "$INSTALL_DIR")
    NODE_VERSION=$(node -v)
    PNPM_VERSION=$(pnpm -v)

    cat > main.neosaas.json <<EOL
{
  "lastUpdate": "${LAST_UPDATE}",
  "gitCommit": "${GIT_COMMIT}",
  "dependenciesCount": ${DEPENDENCIES_COUNT},
  "projectName": "${PROJECT_NAME}",
  "nodeVersion": "${NODE_VERSION}",
  "pnpmVersion": "${PNPM_VERSION}"
}
EOL
}

# === SCRIPT PRINCIPAL ===

info "${GREEN}=== Installation de Neosaas ===${RESET}"

check_or_install_pnpm
clone_or_update_repo
install_dependencies
create_neosaas_command
update_main_neosaas

info "\n${GREEN}✅ Neosaas est installé avec succès ! Lance 'neosaas' pour démarrer.${RESET}"
