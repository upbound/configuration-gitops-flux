
import models.io.crossplane.helmm.v1beta1 as helmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "flux-test"
        spec= {
            assertResources: [
                helmv1beta1.Release {
                    metadata = {
                        name = "release-flux"
                    }
                    spec = {
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "configuration-gitops-flux"
                        }
                        managementPolicies = ["*"]
                        forProvider = {
                            chart = {
                                name = "flux2"
                                version = "2.10.6"
                                url = "https://github.com/fluxcd-community/helm-charts/releases/download/flux2-2.10.6/flux2-2.10.6.tgz"
                            }
                            namespace = "flux-system"
                            values = {
                                imageAutomationController = { create = False }
                                imageReflectionController = { create = False }
                            }
                        }
                    }
                }
                helmv1beta1.Release {
                    metadata = {
                        name = "sync-flux"
                    }
                    spec = {
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "configuration-gitops-flux"
                        }
                        managementPolicies = ["*"]
                        forProvider = {
                            chart = {
                                name = "flux2-sync"
                                version = "1.7.2"
                                repository = "https://fluxcd-community.github.io/helm-charts"
                            }
                            namespace = "flux-system"
                            values = {
                                gitRepository = {
                                    spec = {
                                        gitImplementation = "go-git"
                                        timeout = "60s"
                                        interval = "5m0s"
                                        url = "https://github.com/upbound/platform-ref-aws/"
                                        ref = {
                                            name = "refs/heads/main"
                                            branch = ""
                                        }
                                    }
                                }
                                kustomization = {
                                    spec = {
                                        sourceRef = { kind = "GitRepository" }
                                        interval = "5m0s"
                                        path = "/"
                                    }
                                }
                            }
                        }
                    }
                }
            ]
            compositionPath: "apis/flux/composition.yaml"
            xrPath: "examples/flux-xr.yaml"
            xrdPath: "apis/flux/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
]
items= _items
