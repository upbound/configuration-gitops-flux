#!/usr/bin/env bash
set -aeuo pipefail

echo "Running setup.sh"
CROSSPLANE_NAMESPACE="upbound-system"
SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )

echo "Waiting until all configurations are healthy/installed..."
"${KUBECTL}" wait configuration.pkg --all --for=condition=Healthy --timeout 5m
"${KUBECTL}" wait configuration.pkg --all --for=condition=Installed --timeout 5m

echo "Waiting until all installed provider packages are healthy..."
"${KUBECTL}" wait provider.pkg --all --for condition=Healthy --timeout 5m

echo "Waiting for all pods to come online..."
"${KUBECTL}" -n upbound-system wait --for=condition=Available deployment --all --timeout=5m

echo "Waiting for all XRDs to be established..."
"${KUBECTL}" wait xrd --all --for condition=Established

echo "Installing providerconfigs"
"${KUBECTL}" apply -f ${SCRIPT_DIR}/provider/providerconfigs.yaml
echo "Installed providerconfigs"

echo "Adding provider-helm Service Account permissions"
SA=$("${KUBECTL}" -n ${CROSSPLANE_NAMESPACE} get sa -o name|grep provider-helm | sed -e "s|serviceaccount\/|${CROSSPLANE_NAMESPACE}:|g")
"${KUBECTL}" create clusterrolebinding provider-helm-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
echo "Added provider-helm Service Account permissions"
