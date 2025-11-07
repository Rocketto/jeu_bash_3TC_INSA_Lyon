#  NetLab Quest  
> *Jeu d’exploration UNIX sur le thème du réseau*

---

##  Objectif du jeu

**NetLab Quest** est un mini-jeu 100 % Bash, inspiré d’un TP en salle réseau.  
Le joueur incarne un technicien chargé de restaurer la connectivité d’un laboratoire virtuel.  
Pour y parvenir, il doit retrouver trois fragments de code — `bloc1`, `bloc2`, et `bloc3` — cachés dans différents fichiers systèmes.

La clé finale est la combinaison suivante :
```
bloc1-bloc2-bloc3
```

---

##  Structure du laboratoire

Lors de la création d’une partie, le jeu génère une arborescence comme :

```
netlab_<timestamp>/
├── rack_switch/      → Switch (bloc1)
│   ├── .running-config
│   └── README.txt
├── srv_dhcp/         → Serveur DHCP (bloc2)
│   ├── leases.log
│   └── README.txt
├── fw/               → Pare-feu (bloc3)
│   └── fw.log
├── dns/
└── router/
```

Chaque dossier correspond à un équipement réseau contenant une énigme UNIX à résoudre.

---

##  Commandes UNIX utilisées

Les énigmes du jeu nécessitent uniquement des **commandes standards UNIX**.

| Commande | Rôle principal |
|-----------|----------------|
| `ls -la` | Afficher tous les fichiers (y compris cachés) |
| `ls -l` | Afficher les permissions et propriétaires |
| `find` | Rechercher des fichiers selon leur nom ou permissions |
| `cat` | Lire le contenu d’un fichier |
| `grep` | Chercher du texte dans un fichier |
| `cut` | Extraire une colonne d’une ligne |
| `awk` | Extraire des motifs et filtrer du texte |
| `chmod` | Modifier les permissions d’un fichier |
| `base64 -D` *(macOS)* / `base64 -d` *(Linux)* | Décoder un texte encodé en Base64 |
| `echo`, `tr`, `head`, `tail` | Commandes d’affichage et de traitement simples |

 Ces commandes suffisent pour terminer le jeu sans aucun outil externe.

---

##  Commandes du jeu (`game.sh`)

| Commande | Description |
|-----------|-------------|
| `./game.sh new` | Crée une nouvelle partie NetLab |
| `./game.sh start` | Affiche le briefing et les instructions |
| `./game.sh hint <n>` | Donne un indice pour le palier *n* (1 = Switch, 2 = DHCP, 3 = Firewall) |
| `./game.sh check bloc1-bloc2-bloc3` | Vérifie la clé finale |
| `./game.sh reset` | Supprime la partie en cours |
| `./game.sh help` | Affiche l’aide du jeu |

---

##  Règles du jeu

1. **Tout se joue dans le terminal.**  
   Aucune interface graphique : seules les commandes UNIX sont autorisées.

2. **Le joueur ne doit pas modifier les fichiers** du jeu.  
   L’objectif est d’explorer et de lire, pas d’éditer ou de supprimer.

3. **Une seule partie à la fois.**  
   Le fichier `.netlab_dir` indique la session active.  
   Pour recommencer : `./game.sh reset` puis `./game.sh new`.

4. **Les indices coûtent des points.**  
   Chaque utilisation de `./game.sh hint <n>` inflige une pénalité.

5. **Le score final** dépend du temps écoulé et du nombre d’indices utilisés.

---

##  Déroulement du jeu

###  Étape 1 — Le Switch (bloc1)
- Le joueur explore le dossier `rack_switch/`.
- Il doit trouver un **fichier caché** nommé `.running-config`.
- En inspectant les **permissions (640)** et le contenu du fichier, il découvre une ligne :
  ```
  bloc1=<mot_secret>
  ```
- Exemple de commande :
  ```bash
  ls -la rack_switch
  cat rack_switch/.running-config
  ```

---

###  Étape 2 — Le Serveur DHCP (bloc2)
- Le joueur consulte le fichier `srv_dhcp/leases.log`.
- Son objectif : repérer le **bail DHCP** correspondant à une **adresse MAC donnée** (affichée dans le briefing).
- Dans la ligne correspondante, le champ `note` contient `bloc2=<mot>`.
- Exemple de commande :
  ```bash
  grep "02:42:ac:11:00:2a" srv_dhcp/leases.log
  ```

---

###  Étape 3 — Le Pare-feu (bloc3)
- Le fichier `fw/fw.log` contient une ligne encodée en **Base64** :
  ```
  X-Encoded: YmxvYzM9ZGVsdGE=
  ```
- En la décodant, le joueur obtient :
  ```
  bloc3=delta
  ```
- Exemple de commande :
  ```bash
  grep X-Encoded fw/fw.log | awk -F': ' '{print $2}' | base64 -D
  ```

---

### 🏁 Étape finale — Vérification
Une fois les trois blocs trouvés, le joueur assemble la clé :
```bash
./game.sh check bloc1-bloc2-bloc3
```
Le jeu affiche :
-  si la clé est correcte,  
-  le temps total,  
-  le nombre d’indices utilisés,  
-  et le score final.

---

## 💡 Exemple de session complète

```bash
./game.sh new
./game.sh start

# Palier 1 : Switch
cat netlab_1730/rack_switch/.running-config

# Palier 2 : DHCP
grep "02:42:ac:11:00:2a" netlab_1730/srv_dhcp/leases.log

# Palier 3 : Firewall
grep X-Encoded netlab_1730/fw/fw.log | awk -F': ' '{print $2}' | base64 -D

# Vérification
./game.sh check bravo-hotel-delta
```

Sortie :
```
 Correct !
 temps:42s |  indices: 1 |  score: 9258
```

---

##  Auteur
**Ugo Martin**  
Projet PIT — INSA Lyon, 2025  
Jeu écrit entièrement en **Bash** pour macOS.
