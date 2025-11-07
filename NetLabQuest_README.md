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
## Note Préliminaire
 J'ai légèrement amélioré le jeu par rapport à ce midi concernant la génération du troisième bloc de la clé finale. La génération est maintenant aléatoire contrairement à ce midi ou le bloc 3 était toujours le même.

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

Les énigmes du jeu nécessitent uniquement des **commandes standards UNIX**, telles que:

| Commande | Rôle principal |
|-----------|----------------|
| `ls -la` | Afficher tous les fichiers (y compris cachés) |
| `ls -l` | Afficher les permissions et propriétaires |
| `find` | Rechercher des fichiers selon leur nom ou permissions |
| `cat` | Lire le contenu d’un fichier |
| `grep` | Chercher du texte dans un fichier |
| `cut` | Extraire une colonne d’une ligne |
| `chmod` | Modifier les permissions d’un fichier |
| `base64 -D` *(macOS)* / `base64 -d` *(Linux)* | Décoder un texte encodé en Base64 |
| `echo` | Afficher du texte dans le terminal (ou ailleurs)|

 Ces commandes suffisent pour terminer le jeu sans aucun outil externe.

---

##  Commandes du jeu (`game.sh`)

| Commande | Description |
|-----------|-------------|
| `./game.sh new` | Crée une nouvelle partie NetLab |
| `./game.sh start` | Affiche le briefing et les instructions |
| `./game.sh check bloc1-bloc2-bloc3` | Vérifie la clé finale |
| `./game.sh reset` | Supprime la partie en cours |
| `./game.sh help` | Affiche l’aide du jeu |

---

##  Règles du jeu

1. **Tout se joue dans le terminal.**  
   Aucune interface graphique : seules les commandes UNIX sont autorisées(et à la limite copier et coller des lignes).

2. **Le joueur ne doit pas modifier les fichiers** du jeu.  
   L’objectif est d’explorer et de lire, pas d’éditer ou de supprimer.

3. **Une seule partie à la fois.**  
   Le fichier `.netlab_dir` indique la session active.  
   Pour recommencer : `./game.sh reset` puis `./game.sh new`.

4. **Une fois la partie terminée** vous aurez un message de félicitations ainsi que le temps que vous avez mis à terminer le jeu.

---

##  Déroulement du jeu(Comment pouvoir le terminer)

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
  <message encodé>> base64 -D
  ```

---

### 🏁 Étape finale — Vérification
Une fois les trois blocs trouvés, le joueur assemble la clé :
```bash
./game.sh check bloc1-bloc2-bloc3
```
Le jeu affiche :
-  si la clé est correcte,  
-  le temps total

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
 temps:42s
```

---

##  Auteur
**Ugo Martin**  
Projet PIT — INSA Lyon, 2025  
Jeu écrit entièrement en **Bash** pour macOS et Linux.
