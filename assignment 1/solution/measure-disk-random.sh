fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=random --filename=randomFile --bs=4k --iodepth=64 --size=1024M --readwrite=randrw -rwmixread=75