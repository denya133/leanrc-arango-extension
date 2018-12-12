leanrc-arango-extension
================================

LeanRC extension for creating application based on ArangoDB platform.


## Usefull command in console for creation ssh agent
```
eval `ssh-agent -s`; ssh-add ~/.ssh/id_rsa

```

## Additional packages
```
$ sudo aptitude install redis-server graphicsmagick mc git build-essential
$ sudo npm install -g n
$ sudo n 6.10
$ npm install -g gulp coffee-script mocha gulp scaffolt forever
```

## Testing
```
$ npm test
```

## ArangoDB upgrading
это надо выполнять после добавления репозитория в список (см. на офиц сайте как)
```
apt-get update
apt-get install arangodb3=3.3.20
```
