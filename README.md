# portabledize

Bundle your app in a [systemd portable service](https://systemd.io/PORTABLE_SERVICES/)!

## Get started

**Prepare your files.** You must declare the systemd service file and possibly the files you need to run your app (you may have at least an entrypoint file, like a statically compiled binary). Example:

```ini
# files.txt
./my-binary /usr/bin/my-binary
```

**Bundle it**. Give the files as input and set the name of the output file.

> [!IMPORTANT]  
> The output file will have the following format: `SERVICE_NAME.raw` where `SERVICE_NAME` is merely the name of your service file (without the `.service` extension)

```sh
portabledize.sh -s my-service.service -f files.txt
```

**Attach your service**. Then you can start it!

```sh
sudo portablectl attach my-service.raw
sudo systemctl start my-service
```
