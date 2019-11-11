# Raspbian system backup

## requirement:

- rsync
- dosfstools
- parted
- kpartx
- exfat-fuse

## tested system

- Debian 9 (strech)
- Debian 10 (buster)

## PS

- MUST RUN AS **ROOT**

```bash
# example
sudo su
chmod +x backup.sh
./backup.sh /dev/sda1
```

- always use a not-mounted device to backup

- need to expand file system after writing to a new SD card

```bash
sudo raspi-config
```

## reference

https://github.com/conanwhf/RaspberryPi-script/blob/master/rpi-backup.sh 
