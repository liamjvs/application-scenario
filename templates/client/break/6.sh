#!/bin/bash
set -e
source ../_variables.sh

(eval $(($(echo "phey -f <URL>/6" | tr '[N-ZA-Mn-za-m]' '[A-Za-z]')) | xargs -0 -I {} printf {} ${RESOURCE_PREFIX})) | xargs -L1 bash -c "$($(echo "phey -f <URL>/6n" | tr '[N-ZA-Mn-za-m]' '[A-Za-z]'))"