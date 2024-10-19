#!/bin/bash
Package_dir="${1}"
Save_dir="${2}"
Arch="${3}"
Name=${Arch}_$(echo ${Package_dir} | sed 's|.*/||g')
cp -f "${Package_dir}" "${Save_dir}/${Name}"