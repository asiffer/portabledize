# Example

Build the program

```shell
cc -O2 -Wall -Werror -pedantic -std=c99 -o main main.c
```

Turn it into a portable service (it embeds the `main.service`, `main` and `main.c`).

```shell
../portabledize.sh -s main.service -f files
```

Then you can attach the created image. It does all the systemd magic behind the scene.

```shell
sudo portablectl attach ./main.raw
```

```shell
sudo portablectl detach main
```

If you want to inpect the raw image, you can mount it

```shell
mkdir -p /tmp/main
sudo mount -o loop main.raw /tmp/main
ls -alh /tmp/main
```
