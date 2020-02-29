# Streamies-docker

Easily launch a [Streamies](https://streamies.io) crypto wallet using Docker

## Quickstart from Docker Hub

**Prerequisite:**
- Platform: x86_64
- Your User/Group ID is 1000
- The directory ~/.streamies exist and chown by user (user with ID 1000:1000)

If you **not have** theses prerequisites go to further step. If you match just do a:

```
docker run --restart=always -d -v ~/.streamies:/home/strmsu/.streamies --name=streamies-docker kdmfr/streamies-docker
```

## Build your own image

**Prerequisite:**
- Have the link of streamies wallet for your architecture (Visit [Streamies Github](https://github.com/Streamies/Streamies/releases))
- Have your user and group ID (See bellow)

**Find User/Group ID on linux**

In your favorite terminal type
```
cat /etc/passwd
```

The output should be like
```
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
[...]
kedema:x:1337:1338::/home/kedema:/bin/bash
```
In our example, user "kedema" have "1337" for user ID and "1338" for group ID.

### Step 1: Download/Create Dockerfile

If you have git:
```
git clone https://github.com/kedema/streamies-docker.git && cd streamies-docker
```

If you not have git:
Go to file "Dockerfile", copy the content, then create the file on a free folder of your disk

### Step 2: Edit Dockerfile

Open "Dockerfile" with your favorite editor and edit the line below to adapt for you

```
ENV STRMS_URL= #streamies wallet link
ENV USER_ID= #Your user ID
ENV GROUP_ID #Your user group ID
```

### Step 3: Build

Run the following command:
```
docker build -t streamies-docker .
```

If all are good docker should be tell you
```
Successfully tagged streamies-docker:latest
```

### Step 4: Run container

**Ensure directory "~/.streamies" exist and is owned by you** (your user), if not create it (mkdir ~/.streamies). 

**Option 1: cmd-line**
```
docker run --restart=always -d -p 55297:55297 -v ~/.streamies:/home/strmsu/.streamies --name=streamies-docker streamies-docker
```

**Option 2: docker-compose.yml**

You can use the example docker-compose.yml in this github or create your own, then do a:
```
docker-compose up -d
```

Enjoy! if no issue your container is running, you can verify with "docker ps", in case of problems check out the logs with "docker logs streamies-docker".
At first start streamiesd look for files (wallet.dat, blocks ...), if they don't exist, it creates them.

### Step 5: Interact with container

**Option 1: by docker cmd**

You case use docker to pass the commands for interract with "streamies-cli" with the following
```
docker exec streamies-docker streamies-cli help
docker exec streamies-docker streamies-cli getbalance
[...]
```

**Option 2: enter in the container**

You can enter in your container and then interract direct with "streamies-cli" command with the following
```
docker exec -ti streamies-docker /bin/bash
```

## Configure staking
TODO

## Update wallet
TODO

## Tips

x If the container not start is often due to a permission issue, verify twice User/group ID and if the volume/directory you have choose for wallet files have rights permissions.

x Exposing the port "55297" is usefull only if you want do some staking.

x Use existing wallet : just copy/move your wallet.dat to the folder your selected for your volume before 1st start of container and let him sync.

## Q&A

**Q: Why creating user and complex the process instead just using root in container?**

**A:** I'm just a little paranoid about security :)

## Donation

If you like, you can send me a crypto-donation:

Streamies:SjSbRjlPRP2JpNbZYBEVUZwc4bxie3aKWE

Bitcoin:bc1qaaed5gsv8qqnn6tpn5q628ykdkvrf6u8588dvf 
