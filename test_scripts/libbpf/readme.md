
## Finding mangled Name:

```sh
nm -D /usr/bin/mariadbd | grep dispatch_command | awk -F " " '{ print $3 }'
```
