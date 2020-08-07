# Compile Streamies Wallet
Feuille de route pour compiler le wallet de la cryptomonnaie Streamies (STRMS).
Certains utilisateurs rencontre des trojans lorsqu'ils utilisent la version précompiler du wallet sur Github. La version compilée soit-même ne semble pas être infecté, voilà la raison d'être de ce guide
Je n'ai pas trouver d'instructions complètes pour compiler  le wallet alors j'ai creer les miennes. Ces instructions sont tirés de ce que j'ai pu trouver dans les sources (Streamies-x-x-x/depends/README.md), dans la documentation PIVX, et tiré des recherches que j'ai effectuer sur internet pour corriger certaines erreures qui se sont affichées.
Pour l'instant n'as été tester que pour la plateforme linux x86_64 et sans le wallet GUI QT. Compilé sur Ubuntu 20.04 par la platforme WSL2.

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
Il faut télécharger tous les outils nécéssaires à la compilation du wallet en ligne de commande. Pour generer le wallet QT il faudra surement plus de dépendances à installer, j'y reviendrai peut-être si quelqu'un le demande..

```
sudo apt-get update
sudo apt-get install make automake cmake curl g++-multilib libtool binutils-gold bsdmainutils pkg-config python3 patch libboost-all-dev libssl-dev libgmp-dev
```

## Compilation
### Etape 1: Récuperation des sources:
Placez vous dans un dossier de votre choix, récuperez les sources du dernier wallet streamies (Version de l'exemple: 2.4.3) et decompressez le tout:

```
wget https://github.com/Streamies/Streamies/archive/v2.4.3.tar.gz
tar -xzvf v2.4.3.tar.gz
```

### Etape 2: Configuration
Une fois les fichiers décompressés, aller dans la racine du nouveau répertoire créé par la décompression du fichier tar.gz, et nous allons rendre executables différents scripts contenus dans ce dossier pour que l'opération de déroule sans erreurs:

```
# On entre dans le dossier
cd Streamies-2.4.3/
# On applique des droits d'executions a plusieurs scripts
chmod +x autogen.sh contrib/install_db4.sh share/genbuild.sh
```

### Etape 3: Génération des fichiers configure et makefile
On va maintenant utiliser les scripts pour préparer l'installation:
```
./autogen.sh
#Génere le fichier "configure" dont nous aurons besoin plus bas
```
Le wallet utilise une ancienne version de la base de donnée BerkeleyDB (v4.8), celle-ci n'etant plus disponible dans les repo officiels, il faut la générer.Par chance un script est fourni avec les sources, nous allons le lancer:
```
# Verifiez avant de lancer que vous êtes toujours dans le dossier Streamies-x-x-x/
./contrib/install_db4.sh `pwd`
```
Apres quelques minutes/secondes en fonction la puissance de votre système, le script devrait se terminer en vous affichant quelque chose du genre :
```
  export BDB_PREFIX='/<PWD>/Streamies-2.4.3/db4'
# <PWD> representera votre chemin personalisé
  ./configure BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include"
# Il s'agit de la commande personalisé pour vous pour forcer la compilation avec la base de donnée que nous venons de générer.
```
Maintenant que nous avons le fichier configure, la base de donnée dans la bonne version et la ligne de commande pour l'utiliser, executons-la avec les informations que nous avons récuperées:

```
# Premierement on exporte la variable BDB_PREFIX, pour cela on copie-colle simplement la ligne "export ..." et on valide par entrée
export BDB_PREFIX='/<PWD>/Streamies-2.4.3/db4'
# Puis on lance configure avec ces arguments pour generer le makefile
./configure BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include"

# D'apres la documentation PIVX, si vous manquez de ram pour creer et/ou compiler vous pouvez tenter d'ajouter l'argument suivant apres ./configure CXXFLAGS="--param ggc-min-expand1 --param gcc-min-heapsize=32768"
# Je n'ai jamais essayé! 
```

### Etape 4: Compilation !
On y est presque! il ne reste plus que le vrai travail et par chance c'est l'ordinateur qui fait tout (ou presque) maintenant!
Pour lancer la compilation il suffit de lancer la commande:
```
make
```
En fonction de la puissance de votre ordinateur, cela peut prendre de quelques minutes à quelques heures. A la fin si tout c'est bien passer, vous devriez trouver dans le dossier src/ beaucoup de fichiers y compris ceux qui nous interessent a savoir:
- streamiesd
- strealies-cli
- streamies-tx

Vous remarquerez sans doutes que les fichiers sont assez lourd, je pensais avoir fait une erreur au début, mais en réalité les fichiers sont compilés avec beaucoup d'infos de debug, qui ne sont pas utiles en utilisation générale. Nous pouvons nettoyer ces fichiers et ainsi gagner (beaucoup) d'espace disque, pour cela nous allons utiliser l'outil strip:
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
tar -czvf streamies-2.4.3.tar.gz src/streamies-cli src/streamies-tx src/streamiesd
```
**NOTE:** Pour une utilisation en mode portable, le wallet demande a acceder a la "libboost" qui n'etait pas sur le serveur sur lequel j'ai telecharger mes fichiers. J'ai pu résoudre le problème avec un "sudo apt-get install libboost-all-dev" mais cela nécéssite de telecharger beaucoup de données, j'imagine qu'il y as une meilleure solution mais je ne la connais pas pour le moment.
