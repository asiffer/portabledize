IMAGE=main.raw
MOUNTPOINT=/tmp/portabledize
FILES=files 
SERVICE_FILE=main.service
PORTABLE=/etc/portables/$(IMAGE)

.DEFAULT_GOAL := $(IMAGE)

main: main.c
	cc -O2 -Wall -Werror -pedantic -std=c99 -o $@ $^

clean:
	rm -f *.raw
	rm -f $(MOUNTPOINT)

$(MOUNTPOINT):
	sudo mkdir -p $@

$(IMAGE): $(FILES)
	../portabledize.sh -s $(SERVICE_FILE) -f $^ -v 

mount: $(IMAGE) $(MOUNTPOINT)
	sudo mount -o loop $(IMAGE) $(MOUNTPOINT)

umount: $(MOUNTPOINT)
	sudo umount $^

unmount: umount

attach: $(PORTABLE)

$(PORTABLE): $(IMAGE)
	sudo portablectl attach ./$<

detach: $(IMAGE) $(PORTABLE)
	sudo portablectl detach ./$<