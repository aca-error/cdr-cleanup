#!/bin/bash
# Create test files dengan berbagai umur dalam 3 direktori
for i in {1..1000}; do
    touch -d "$((RANDOM % 365)) days ago" /home/cdrsbx/random1/file_$i.txt
    touch -d "$((RANDOM % 365)) days ago" /home/cdrsbx/random2/file_$i.txt
    touch -d "$((RANDOM % 365)) days ago" /home/cdrsbx/random3/file_$i.txt
done
