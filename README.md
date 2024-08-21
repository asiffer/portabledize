# portabledize

Bundle your app in a [systemd portable service](https://systemd.io/PORTABLE_SERVICES/)!

## Installation

```sh
wget https://raw.githubusercontent.com/asiffer/portabledize/master/portabledize.sh
```

## Get started

You need to provide two files:

- The systemd service file (like `my-service.service`)
- Extra files you want to map to the target image (you need to provide one binary at least)

Here is an example with a single binary to copy.

```ini
# files.txt
./my-binary /usr/bin/my-binary
```

Then you can run the script.

```shell
portabledize.sh -s my-service.service -f files.txt
```

It creates an image file `my-service.raw` in the current directory. You can modify the output directory with the `-d` option.

> [!IMPORTANT]  
> It is important to keep this naming convention (if you provide `wtf.service`, it builds `wtf.raw`). Systemd won't accept image with filename different from service name.

Finally you can attach your service anywhere (where systemd runs!).

```shell
sudo portablectl attach ./my-service.raw
# sudo portablectl detach my-service
```

You can look at the [./example](./example/) directory to see a true but basic sample.

## Github Action

This repo follows the structure of a custom github action. So basically you can integrate `portabledize` to your CI/CD.

```yaml
on: [push]

jobs:
  portabledize_job:
    runs-on: ubuntu-latest
    name: portabledize
    steps:
      - name: Build image
        id: systemd_image
        uses: actions/portabledize@v1
        with:
          service_file: "my-service.service"
          install_file: "files.txt"
      # Use the output from the `systemd_image` step
      - name: Print the image file
        run: echo "${{ steps.systemd_image.outputs.image }}"
```
