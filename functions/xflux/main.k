
import models.io.upbound.platform.gitops.v1alpha1 as gitopsv1alpha1
import models.io.crossplane.helm.v1beta1 as helmv1beta1

oxr = gitopsv1alpha1.XFlux{**option("params").oxr}

_metadata = lambda name: str -> any {
    {
        name = name
        annotations = { "krm.kcl.dev/composition-resource-name" = name }
        labels = oxr.metadata?.labels or {}
    }
}

# Extract parameters from XR spec
_providerConfigName = oxr.spec?.parameters?.providerConfigName or ""
_deletionPolicy = oxr.spec?.parameters?.deletionPolicy or "Delete"

# Flux operator configuration
_fluxVersion = oxr.spec?.parameters?.operators?.flux?.version or "2.10.6"
_fluxSyncVersion = oxr.spec?.parameters?.operators?.fluxSync?.version or "1.7.2"

# Git source configuration
_gitUrl = oxr.spec?.parameters?.source?.git?.url or ""
_gitRef = oxr.spec?.parameters?.source?.git?.ref?.name or ""
_gitPath = oxr.spec?.parameters?.source?.git?.path or "/"
_gitInterval = oxr.spec?.parameters?.source?.git?.interval or "5m0s"
_gitTimeout = oxr.spec?.parameters?.source?.git?.timeout or "60s"

# KubeConfig secret reference
_kubeConfigName = oxr.spec?.parameters?.kubeConfigSecretRef?.name or ""
_kubeConfigKey = oxr.spec?.parameters?.kubeConfigSecretRef?.key or "kubeconfig"

_items = [
    helmv1beta1.Release {
        metadata = _metadata("release-flux")
        spec = {
            providerConfigRef = { name = _providerConfigName }
            deletionPolicy = _deletionPolicy
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
                # Resilience configurations to handle webhook race conditions
                wait = True               # Wait for resources to be ready
                waitTimeout = "900s"      # 15 minute timeout to handle webhook delays
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
            providerConfigRef = { name = _providerConfigName }
            deletionPolicy = _deletionPolicy
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
                            kubeConfig = {
                                secretRef = {
                                    name = _kubeConfigName
                                    key = _kubeConfigKey
                                }
                            } if _kubeConfigName else None
                        }
                    }
                }
                # Resilience configurations to handle webhook race conditions
                wait = True               # Wait for resources to be ready
                waitTimeout = "900s"      # 15 minute timeout to handle webhook delays
            }
        }
    }
]

items = _items
