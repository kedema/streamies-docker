# Compile Streamies Wallet
Feuille de route pour compiler le wallet de la cryptomonnaie Streamies (STRMS).
Certains utilisateurs rencontre des trojans lorsqu'ils utilisent la version précompiler du wallet sur Github. La version compilée soit-même ne semble pas être infecté, voilà la raison d'être de ce guide
Je n'ai pas trouver d'instructions complètes pour compiler  le wallet alors j'ai creer les miennes. Ces instructions sont tirés de ce que j'ai pu trouver dans les sources (Streamies-x-x-x/depends/README.md), dans la documentation PIVX, et tiré des recherches que j'ai effectuées sur internet pour corriger certaines erreures qui se sont affichées.
Pour l'instant n'as été tester que pour la plateforme linux x86_64. Compilé sur Ubuntu 20.04 par la platforme WSL2.

## Pré-requis
Il vous faut de l'espace disque, au moins 2,5Go de libre (la compilation me laisse un dossier de 2.1G)
Il faut également une bonne quantité de ram, au moins 2-3Go, si vous faites ça sur ordinateur avec peu de mémoire, vérifiez que vous avez un fichier de swap actif avec:
```
swapon --show
```
Si il n'y as pas de sorti c'est qu'il n'y as pas de fichier swap, dans ce cas nous allons en creer un, mon VPS dispose de 2Go de ram, la bonne pratique veut que le swap fasse le double de la ram, mais cela me semble éxageré donc j'en ai fait un de 3Go:
```
sudo fallocate -l 3G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```
Vous pouvez verifier que tout c'est bien passé en retapant la commande swapon --show, vous devriez y voir votre "fichier swap".
Si vous avez suffisament de memoire (3G ou +), et/ou que votre fichier de swap et prêt alors vous pouvez passer à la suite.

## Dépendances
Il faut télécharger tous les outils nécéssaires à la compilation du wallet.
```
sudo apt-get update
sudo apt-get install make automake cmake curl g++-multilib libtool binutils-gold bsdmainutils pkg-config python3 patch libssl-dev libgmp-dev
```
Il y a d'autres dépendances, mais nous allons les compiler plus tard.

## Compilation
### Etape 1: Récuperation des sources:
Placez vous dans un dossier de votre choix, récuperez les sources du dernier wallet streamies (Version de l'exemple: 2.4.3) et decompressez le tout:

```
wget https://github.com/Streamies/Streamies/archive/v2.4.3.tar.gz
tar -xzvf v2.4.3.tar.gz
```

Une fois les fichiers décompressés, aller dans la racine du nouveau répertoire créé par la décompression du fichier tar.gz, et nous allons rendre executables différents scripts contenus dans ce dossier pour que les opérations de compilations se déroulent sans erreurs:

```
# On entre dans le dossier
cd Streamies-2.4.3/
# On applique des droits d'executions a plusieurs scripts
chmod +x autogen.sh contrib/install_db4.sh share/genbuild.sh
```

### Etape 2: Génération des dépendances, fichiers configure et makefile
Nous allons en premier generer les dépendance afin de les inclures dans le binaire final.
Pour cela il faut ce rendre dans le dossier "depends" et faire un make, le script va se charger de telecharger et compiler les dépendances nécéssaires.
```
cd depends/
make
#Ce processus est assez long! Vous pouvez l'accelerer en ajoutant -jX à make, où X est le nombre de vos coeurs réels, exemple "make -j4" pour un processeur 4 coeurs
```
***Windows WSL2 Note:*** Si vous rencontrez une erreur du style "/bin/bash: 1 Syntax error:"(" unexpected", c'est sûrement que vous êtes sous WSL, le probleme vient du fait que windows ajoute des chemins "windows" dans votre $PATH, ceux-ci contiennent des espaces et semblent être a l'origine de ce bug. J'ai pu resoudre mon probleme en tapant "echo $PATH", j'ai modifier la sortie pour enlever les path avec espaces (exemple: C:/Program Files/...) puis j'ai exporter mes path corrigés avec "export $PATH="<MesPathCorrigés>"". Cette modification n'est pas persistente, si vous faites un erreur qui provoque des bugs, fermer vos terminal WSL, rouvrez-les et remodifier les paths en faisant attention à la syntaxe.

On va maintenant utiliser les scripts inclus dans la source pour préparer l'installation, pour cela on revient dans le dossier racine et on lance autogen:
```
cd ..
./autogen.sh
#Génere le fichier "configure" dont nous aurons besoin plus bas
```
Le wallet utilise une ancienne version de la base de donnée BerkeleyDB (v4.8), celle-ci n'étant plus disponible dans les repo officiels, il faut la générer. Par chance un script est fourni avec les sources, nous allons l'éxecuter:
```
# Vérifiez avant de lancer que vous êtes toujours dans le dossier Streamies-x-x-x/
./contrib/install_db4.sh `pwd`
```
Après quelques minutes/secondes en fonction la puissance de votre système, le script devrait se terminer en vous affichant quelque chose du genre :
```
  export BDB_PREFIX='/<PWD>/Streamies-2.4.3/db4'
# <PWD> representera votre chemin personalisé
  ./configure BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include"
# Il s'agit de la commande personalisé pour vous pour forcer la compilation avec la base de donnée que nous venons de générer.
```

On génère le Makefile, avec configure, la ligne générée par le script pour la bdd et nous allons y ajouter la liaison vers les dépendances que nous avons génerées, ainsi qu'un flag reduisant les sortis de débug pour réduire la taille des binaires:
```
# Vérifiez avant de lancer que vous êtes toujours dans le dossier Streamies-x-x-x/
# Premierement on exporte la variable BDB_PREFIX, pour cela on copie-colle simplement la ligne "export ..." générée précedemment et on valide par entrée
export BDB_PREFIX=$PWD/db4
# On ajoute notre repertoire de dépendances
export CONFIG_SITE=$PWD/depends/x86_64-linux-gnu/share/config.site
# Puis on lance configure avec ces arguments pour generer le makefile, j'ai ajouter CXXFLAGS="-O2" pour eviter d'ecrire le debug dans les binaires et ainsi gagner (beaucoup) de place
./configure --prefix=/ BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include" CXXFLAGS="-O2" 

# D'apres la documentation PIVX, si vous manquez de ram pour creer et/ou compiler vous pouvez tenter d'ajouter les arguments suivants après ./configure CXXFLAGS="--param ggc-min-expand1 --param gcc-min-heapsize=32768"
# Je n'ai jamais essayé! 
```

### Etape 3: Compilation !
On y est presque! il ne reste plus que le wallet à compiler!
Pour lancer la compilation il suffit de lancer la commande make dans le dossier racine:
```
make
#Ce processus est assez long! Vous pouvez l'accelerer en ajoutant -jX à make, où X est le nombre de vos coeurs réels, exemple "make -j4" pour un processeur 4 coeurs
```
En fonction de la puissance de votre ordinateur, cela peut prendre de quelques minutes à quelques heures. A la fin si tout c'est bien passé, vous devriez trouver dans le dossier src/ beaucoup de fichiers y compris ceux qui nous interessent à savoir:
- streamiesd
- strealies-cli
- streamies-tx

Vous trouverez également streamies-qt dans le sous-dossier "src/qt/"

Vous remarquerez sans doutes que les fichiers sont assez lourd, surtout si vous n'avez pas mis le flag CXXFLAGS="-O2" à configure, je pensais avoir fait une erreur au début, mais en réalité les fichiers sont compilés avec beaucoup d'infos de debug, qui ne sont pas utiles en utilisation générale. Nous pouvons nettoyer ces fichiers et ainsi les reduires en taille, pour cela nous allons utiliser l'outil strip:
```
# Toujours dans le dossier Streamies-x-x-x
strip -v src/streamies-cli src/streamies-tx src/streamiesd
```
Vous voila maintenant avec votre wallet compilé spécialement pour vous et dans une taille acceptable.
Si vous comptez l'utiliser sur cette machine, alors vous pouvez lancer la commande:
```
sudo make install
```
Ce qui va copier les fichiers binaires au bons endroits (/usr/local/bin/) pour que vous puissiez l'utiliser facilement de n'importe quel dossier et installer les fichiers "man" pour avoir la documentation.

Si vous comptez l'utiliser ailleurs vous pouvez compresser les fichiers et les déplacer ou bon vous semble:
```
tar -czvf streamies-2.4.3.tar.gz src/streamies-cli src/streamies-tx src/streamiesd src/qt/streamies-qt
```
