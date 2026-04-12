#!/usr/bin/env bash
# Create a dummy ext image with a deleted file that contains secret message
# User prompt:
# Recover deleted text files from a small ext image and extract \
# its secret password

dd if=/dev/zero of=disk.img bs=1M count=50
mkfs.ext4 disk.img

ls --help > ls.txt
grep --help > grep.txt
(strings --help; echo "password is 1234") > strings.txt

debugfs -w disk.img << 'EOF'
write ls.txt ls.txt
write grep.txt grep.txt
write strings.txt strings.txt
rm strings.txt
quit
EOF