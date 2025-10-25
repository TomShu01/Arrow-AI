Arrow repo added as a subtree
```sh
git subtree add --prefix=Arrow/ https://github.com/mhgolkar/Arrow.git main --squash
```

pull new changes to Arrow
```sh
git subtree pull --prefix=Arrow/ https://github.com/mhgolkar/Arrow.git main --squash
```

Arrow.wiki added as subtree
```sh
git subtree add --prefix=Docs/Arrow.wiki https://github.com/mhgolkar/Arrow.wiki.git master --squash
```

pull new changes to Arrow.wiki
```sh
git subtree pull --prefix=Docs/Arrow.wiki https://github.com/mhgolkar/Arrow.wiki.git master --squash
```