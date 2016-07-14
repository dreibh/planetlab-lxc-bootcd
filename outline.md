Just a few notes on how the whole boot sequence is organized

# overall sequence (sysV init / systemd)

* `pl_sysinit`
* `pl_boot`

# `pl_sysinit`

* udev
* **PY** `pl_hwinit`
  * loads modules / blacklisted
  * modprobe `sd_mod`, `usb_storage`, `floppy`
  * wait 10' for USB subsystem to come up
* initrd
* block-devices
* device-mapper-node
* sysctl
* rsyslog
* **SH** `pl_netinit`
  * locate network config
  * IPMI 
  * determine interface name<>
* clock

# `pl_boot`
