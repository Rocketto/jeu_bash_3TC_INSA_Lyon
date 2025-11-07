#!/usr/bin/env bash
# NetLab Quest - Terminal/UNIX mini-game (Switch + DHCP + Firewall)
# 100% Bash + outils UNIX. macOS compatible (base64 -D) & Linux (base64 -d).

set -euo pipefail

# --- Fichiers d'état ---
GAME_MARKER=".netlab_dir"     # mémorise le dossier de la partie en cours
START_FILE=".netlab_start"
META=".meta"

# --- Utilitaires ---
now(){ date +%s; }
cecho(){ local c="$1"; shift; if command -v tput >/dev/null; then tput setaf "$c"; fi; echo -e "$*"; if command -v tput >/dev/null; then tput sgr0; fi; }
decode_b64(){ if [[ "${OSTYPE:-}" == darwin* ]]; then base64 -D; else base64 -d; fi; }

exists_game(){ [[ -f "$GAME_MARKER" && -d "$(cat "$GAME_MARKER")" ]]; }
get_dir(){ cat "$GAME_MARKER"; }
need_game(){ if ! exists_game; then cecho 1 "Aucune partie active. Lance ./game.sh new"; exit 1; fi; }
need_no_game(){ if exists_game; then cecho 3 "Partie déjà en cours dans $(get_dir). Utilise ./game.sh reset"; exit 1; fi; }

# --- Réservoir de mots (pour blocs secrets) ---
WORDS=(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu
       atlas borneo cygnus draco europa gaia helix iona juno kappa luna myrrh nix orion prysm quark rhea sirius terra umbra vesta xenon zephyr)
rand_word(){ echo "${WORDS[$RANDOM % ${#WORDS[@]}]}"; }

# --- Création du "monde" NetLab ---
create_world(){
  local dir="$1"
  mkdir -p "$dir/rack_switch" "$dir/srv_dhcp" "$dir/fw" "$dir/dns" "$dir/router"

  # Palier 1 — SWITCH : fichier caché + permissions strictes
  local b1; b1="$(rand_word)"
  echo "bloc1=${b1}" > "$dir/rack_switch/.running-config"
  chmod 640 "$dir/rack_switch/.running-config"
  echo "Note: Sauvegarde régulière des configurations requise." > "$dir/rack_switch/README.txt"

  # Palier 2 — DHCP : générer 50 baux, un seul correct (MAC cible + bonne clé)
  local mac_good="02:42:ac:11:00:2a"
  local b2; b2="$(rand_word)"

  # helper: génère une MAC aléatoire sous la forme xx:xx:xx:xx:xx:xx
  rand_mac(){
    printf "%02x:%02x:%02x:%02x:%02x:%02x" \
      $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) \
      $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
  }

  # choisir une position aléatoire (1..50) qui contiendra la bonne ligne
  local total=50
  local good_pos=$((RANDOM % total + 1))

  # écrire l'entête du fichier
  : > "$dir/srv_dhcp/leases.log"
  echo "Liste de DHCP" >> "$dir/srv_dhcp/leases.log"

  for i in $(seq 1 $total); do
    # ip aléatoire dans 192.168.12.1..254
    ip="192.168.12.$((RANDOM % 254 + 1))"
    if [[ $i -eq $good_pos ]]; then
      # ligne correcte : MAC cible + bonne clé
      printf 'lease %s { hardware ethernet %s; uid "lab-pc-%d"; note "bloc2=%s"; }\n' \
        "$ip" "$mac_good" "$i" "$b2" >> "$dir/srv_dhcp/leases.log"
    else
      # ligne "leurre" : MAC aléatoire + fausse clé
      fake_mac="$(rand_mac)"
      fake_key="$(rand_word)"
      printf 'lease %s { hardware ethernet %s; uid "host-%d"; note "bloc2=%s"; }\n' \
        "$ip" "$fake_mac" "$i" "$fake_key" >> "$dir/srv_dhcp/leases.log"
    fi
  done

  echo "Mais ou est passée la bonne adresse MAC? Il y en a beaucoup, comment extraire juste la ligne correspondante?" > "$dir/srv_dhcp/README.txt"

  # Palier 3 — FIREWALL : base64 dans une ligne X-Encoded
  local b3; b3="$(rand_word)"
  local enc; enc="$(printf "bloc3=%s" "$b3" | base64 | tr -d '\n')"
  cat > "$dir/fw/fw.log" <<FW
[ACCEPT] TCP 10.0.0.5:443 <- 192.168.12.23
[DROP]   UDP 0.0.0.0:68 <- 255.255.255.255
X-Encoded: $enc
FW

  # Leurres (facultatifs)
  echo '@ IN A 192.168.12.10' > "$dir/dns/zone.local"
  echo 'default via 192.168.12.1 dev eth0' > "$dir/router/route.txt"

  # META (pour check)
  printf "B1=%s\nB2=%s\nB3=%s\nMAC=%s\n" "$b1" "$b2" "$b3" "$mac_good" > "$dir/$META"

  # Briefing
  cat > "$dir/start.txt" <<MSG
Bienvenue en salle réseau (NetLab).
Trouve la clé finale au format: bloc1-bloc2-bloc3

Paliers:
  1) SWITCH  : config cachée (permissions strictes) -> bloc1
  2) DHCP    : baux ; retrouve le bon MAC: $mac_good -> bloc2
  3) FIREWALL: décoder la ligne X-Encoded (base64)    -> bloc3

Commandes utiles:
  ls -la, find -perm, cat, grep, awk, base64 (macOS: -D)

Valide ensuite:
  ./game.sh check bloc1-bloc2-bloc3
MSG
}

# --- Commandes utilisateur ---
cmd_new(){
  need_no_game
  local ts dir
  ts="$(now)"; dir="netlab_${ts}"
  mkdir -p "$dir"
  echo "$dir" > "$GAME_MARKER"
  echo "$ts" > "$START_FILE"
  create_world "$dir"
  cecho 2 "Nouvelle partie créée: $dir"
  cecho 6 "Lance ./game.sh start pour le briefing."
}

cmd_start(){
  need_game
  local dir; dir="$(get_dir)"
  cecho 6 "Objectif: récupère bloc1, bloc2, bloc3 puis ./game.sh check bloc1-bloc2-bloc3"
  echo "Chemin du lab: $dir"
  echo "Briefing: $dir/start.txt"
  echo
  echo "Piste: SWITCH -> DHCP -> FIREWALL"
}

cmd_check(){
  need_game
  local attempt="${1:-}"
  if [[ -z "$attempt" ]]; then
    cecho 3 "Usage: ./game.sh check bloc1-bloc2-bloc3"
    exit 1
  fi
  local dir; dir="$(get_dir)"
  # Lire la solution depuis META
  # shellcheck disable=SC1090
  source "$dir/$META"
  local solution="${B1}-${B2}-${B3}"
  local norm_attempt="${attempt,,}"
  if [[ "$norm_attempt" == "$solution" ]]; then
    local t0 t1 dt
    t0="$(cat "$START_FILE")"; t1="$(now)"; dt=$((t1 - t0))
    cecho 2 "Correct !"
    cecho 6 "Solution: $solution"
    cecho 6 "Temps: ${dt}s"
    return 0
  else
    cecho 1 "Mauvaise clé. Format attendu: bloc1-bloc2-bloc3"
    return 1
  fi
}

cmd_reset(){
  need_game
  local dir; dir="$(get_dir)"
  rm -rf "$dir" "$GAME_MARKER" "$START_FILE"
  cecho 2 "Partie supprimée."
}

cmd_help(){
  cat <<'EOF'
Usage: ./game.sh <commande>
  new           Créer une nouvelle partie NetLab
  start         Afficher le briefing et les pistes
  check CODE    Vérifier la clé finale (bloc1-bloc2-bloc3)
  reset         Supprimer la partie en cours
  help          Afficher cette aide
EOF
}

main(){
  local cmd="${1:-help}"; shift || true
  case "$cmd" in
    new)   cmd_new   "$@" ;;
    start) cmd_start "$@" ;;
    check) cmd_check "$@" ;;
    reset) cmd_reset "$@" ;;
    help|*) cmd_help ;;
  esac
}
main "$@"