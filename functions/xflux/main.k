
import models.io.upbound.platform.gitops.v1alpha1 as gitopsv1alpha1
import models.io.crossplane.helmm.v1beta1 as helmv1beta1

# Note: avoid casting the full OXR (e.g. Flux{**oxr}) because the
# auto-generated model types status.conditions as a typed list which is
# incompatible with the generic list Crossplane passes at runtime.
# Instead, keep the raw OXR and cast only the sub-fields we need.
oxr = option("params").oxr
_params = gitopsv1alpha1.Flux.spec.parameters{**oxr.spec?.parameters}

_metadata = lambda name: str -> any {
    {
        name = name
        annotations = { "krm.kcl.dev/composition-resource-name" = name }
        labels = oxr.metadata?.labels or {}
    }
}

# Extract parameters from XR spec
_providerConfigName = _params?.providerConfigName or ""
_managementPolicies = _params?.managementPolicies or ["*"]

# Flux operator configuration
_fluxVersion = _params?.operators?.flux?.version or "2.10.6"
_fluxSyncVersion = _params?.operators?.fluxSync?.version or "1.7.2"

# Git source configuration
_gitUrl = _params?.source?.git?.url or ""
_gitRef = _params?.source?.git?.ref?.name or ""
_gitPath = _params?.source?.git?.path or "/"
_gitInterval = _params?.source?.git?.interval or "5m0s"
_gitTimeout = _params?.source?.git?.timeout or "60s"

# KubeConfig secret reference
_kubeConfigName = _params?.kubeConfigSecretRef?.name or ""
_kubeConfigKey = _params?.kubeConfigSecretRef?.key or "kubeconfig"

_items = [
    helmv1beta1.Release {
        metadata = _metadata("release-flux")
        spec = {
            providerConfigRef = {
                kind = "ProviderConfig"
                name = _providerConfigName
            }
            managementPolicies = _managementPolicies
            rollbackLimit = 15            # More rollback attempts for resilience
            forProvider = {
                chart = {
                    name = "flux2"
                    version = _fluxVersion
                    url = "https://github.com/fluxcd-community/helm-charts/releases/download/flux2-${_fluxVersion}/flux2-${_fluxVersion}.tgz"
                }
                namespace = "flux-system"
                values = {
                    imageAutomationController = { create = False }
                    imageReflectionController = { create = False }
                }
                # Resilience configurations to handle webhook race conditions and rate limiting
                wait = True               # Wait for resources to be ready
                waitTimeout = "1800s"     # 30 minute timeout to handle webhook delays and rate limiting
            }
        }
    }

    helmv1beta1.Release {
        metadata = _metadata("sync-flux") | {
            annotations = _metadata("sync-flux").annotations | {
                "crossplane.io/external-name" = _providerConfigName
            }
        }
        spec = {
            providerConfigRef = {
                kind = "ProviderConfig"
                name = _providerConfigName
            }
            managementPolicies = _managementPolicies
            rollbackLimit = 15            # More rollback attempts for resilience
            forProvider = {
                chart = {
                    name = "flux2-sync"
                    version = _fluxSyncVersion
                    repository = "https://fluxcd-community.github.io/helm-charts"
                }
                namespace = "flux-system"
                values = {
                    gitRepository = {
                        spec = {
                            gitImplementation = "go-git"
                            timeout = _gitTimeout
                            interval = _gitInterval
                            url = _gitUrl
                            ref = {
                                name = _gitRef
                                branch = ""
                            }
                        }
                    }
                    kustomization = {
                        spec = {
                            sourceRef = { kind = "GitRepository" }
                            interval = _gitInterval
                            path = _gitPath
                            **({kubeConfig = {
                                secretRef = {
                                    name = _kubeConfigName
                                    key = _kubeConfigKey
                                }
                            }} if _kubeConfigName else {})
                        }
                    }
                }
                # Resilience configurations to handle webhook race conditions and rate limiting
                wait = True               # Wait for resources to be ready
                waitTimeout = "1800s"     # 30 minute timeout to handle webhook delays and rate limiting
            }
        }
    }
]

items = _items
