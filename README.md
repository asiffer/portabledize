# portabledize

Bundle your app in a [systemd portable service](https://systemd.io/PORTABLE_SERVICES/)!

## Get started

**Prepare your files.** You must declare the files you need to run your app. You have at least an entrypoint file (ex: a statically compiled binary) and a systemd service file.

```ini
# files.txt
./my-binary /usr/bin/my-binary
./my-service.service /usr/lib/systemd/system/my-service.service
```

**Bundle it**. Give the files as input and set the name of the output file.

> [!IMPORTANT]  
> The output file must have the following format: `SERVICE_NAME.raw` where `SERVICE_NAME` is merely the name of your service file (without the `.service` extension)

```sh
portabledize.sh -f files.txt -o my-service.raw
```

**Attach your service**. Then you can start it!

```sh
sudo portablectl attach my-service.raw
sudo systemctl start my-service
```
