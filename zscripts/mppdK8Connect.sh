#!/bin/bash

export AWS_PROFILE=mppd
export KUBECONFIG=$HOME/.kube/mppd

echo "Environment variables set:"
echo "  AWS_PROFILE=$AWS_PROFILE"
echo "  KUBECONFIG=$KUBECONFIG"
