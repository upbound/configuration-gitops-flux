# Flux Configuration

This repository contains a [Crossplane configuration](https://docs.crossplane.io/latest/concepts/packages/#configuration-packages), tailored for users establishing their initial control plane with [Upbound](https://cloud.upbound.io). This configuration deploys fully managed Flux instances allowing you to integrate GitOps practices into your workflow.

## Overview

The core components of a custom API in [Crossplane](https://docs.crossplane.io/latest/getting-started/introduction/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Implements the API by orchestrating a set of Crossplane managed resources.

In this specific configuration, the Flux API contains:

- **a Flux custom resource type:** Defined in `/apis/flux/definition.yaml` as a namespaced Crossplane v2 XRD
- **Composition of the Flux resources:** Configured in `/apis/flux/composition.yaml`, it provisions Flux GitOps resources in the target namespace

This repository contains Composite Resource (XR) examples in the `examples/` directory.

## Crossplane v2 Migration

This configuration has been migrated to Crossplane v2 with the following changes:

- **Namespaced resources**: Resources now use the `.m` API group (e.g., `helm.m.crossplane.io/v1beta1`) and XRD uses `scope: Namespaced`
- **Resource naming**: Changed from `XFlux` to `Flux` (removed "X" prefix)
- **ManagementPolicies**: Replaced `deletionPolicy` with `managementPolicies` parameter to control resource lifecycle (defaults to `["*"]` for full management)
- **Provider v2**: Uses provider-helm v1 with namespaced resource support

### Breaking Changes

If upgrading from v1:
1. Resources must specify a namespace
2. Update XR kind from `XFlux` to `Flux`
3. Replace `deletionPolicy` with `managementPolicies` in parameters
4. Ensure ProviderConfig includes `kind: ProviderConfig` field

## Deployment

Deploy this configuration to your control plane:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-gitops-flux
spec:
  package: xpkg.upbound.io/upbound/configuration-gitops-flux:v0.10.0
```

## Example Usage

Create a Flux instance:

```yaml
apiVersion: gitops.platform.upbound.io/v1alpha1
kind: Flux
metadata:
  name: my-flux-instance
  namespace: default
spec:
  parameters:
    providerConfigName: my-provider-config
    managementPolicies: ["*"]
    operators:
      flux:
        version: "2.10.6"
      fluxSync:
        version: "1.7.2"
    source:
      git:
        url: https://github.com/your-org/your-repo
        ref:
          name: refs/heads/main
        interval: "5m0s"
        timeout: "60s"
        path: "/"
```

See `examples/flux-xr.yaml` for a complete example.

## Next steps

This repository serves as a foundational step. To enhance your control plane, consider:

1. creating new API definitions in this same repo
2. editing the existing API definition to your needs

Upbound will automatically detect the commits you make in your repo and build the configuration package for you. To learn more about how to build APIs for your managed control planes in Upbound, read the guide on Upbound's docs.
