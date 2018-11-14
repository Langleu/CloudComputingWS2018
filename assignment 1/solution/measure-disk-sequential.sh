sync; dd if=/dev/zero of=tempfile bs=1M count=1024; sync #write 1GB
sudo /sbin/sysctl -w vm.drop_caches=3 #drop cache
dd if=tempfile of=/dev/null bs=1M count=1024 #read 1GB