#!/bin/bash
Package_dir="${1}"
Save_dir="${2}"
Arch="${3}"
Name=$(echo ${Package_dir} | sed 's|.*/||g' | sed "s|_all|_${Arch}|")
cp -f "${Package_dir}" "${Save_dir}/${Name}"