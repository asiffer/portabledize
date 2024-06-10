IMAGE=main.raw
MOUNTPOINT=/mnt/test0
FILES=files 
PORTABLE=/etc/portables/$(IMAGE)

.DEFAULT_GOAL := $(IMAGE)

main: main.c
	cc -O2 -Wall -Werror -pedantic -std=c99 -o $@ $^

clean:
	rm -f *.raw

$(MOUNTPOINT):
	sudo mkdir -p $@

$(IMAGE): $(FILES)
	../portabledize.sh -o $@ -f $^ -v 

mount: $(IMAGE) $(MOUNTPOINT)
	sudo mount -o loop $(IMAGE) $(MOUNTPOINT)

umount: $(MOUNTPOINT)
	sudo umount $^

unmount:umount

attach: $(PORTABLE)

$(PORTABLE): $(IMAGE)
	sudo portablectl attach ./$^

detach: $(IMAGE) $(PORTABLE)
	sudo portablectl detach ./$<