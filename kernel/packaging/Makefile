obj-m := applesmc-als.o

KERNEL_DIR ?= /lib/modules/$(KERNELRELEASE)/build

.PHONY: all clean

all:
	$(MAKE) -C $(KERNEL_DIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KERNEL_DIR) M=$(CURDIR) clean
