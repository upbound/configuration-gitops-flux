
import models.io.crossplane.helm.v1alpha1 as helmv1alpha1
import models.io.crossplane.helm.v1beta1 as helmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.gitops.v1alpha1 as gitopsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "flux-e2e-test"
        spec= {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                gitopsv1alpha1.XFlux {
                    metadata = {
                        name = "test-flux-instance"
                        namespace = "default"
                    }
                    spec = {
                        parameters = {
                            providerConfigName = "uptest-gitops-flux-cluster"
                            deletionPolicy = "Delete"
                            operators = {
                                flux = { version = "2.10.6" }
                                fluxSync = { version = "1.7.2" }
                            }
                            source = {
                                git = {
                                    url = "https://github.com/upbound/platform-ref-aws/"
                                    ref = { name = "refs/heads/main" }
                                    interval = "5m0s"
                                    timeout = "60s"
                                    path = "/"
                                }
                            }
                        }
                    }
                }
            ]
            extraResources: [
                {
                    apiVersion: "pkg.crossplane.io/v1"
                    kind: "Configuration"
                    metadata.name: "configuration-aws-eks"
                    spec.package: "xpkg.upbound.io/upbound/configuration-aws-eks:v0.18.2"
                }
                {
                    apiVersion: "pkg.crossplane.io/v1"
                    kind: "Configuration"
                    metadata.name: "configuration-aws-network"
                    spec.package: "xpkg.upbound.io/upbound/configuration-aws-network:v0.24.0"
                }
                {
                    apiVersion: "aws.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata.name: "default"
                    spec.credentials = {
                        source = "Upbound"
                        upbound = {
                            webIdentity = {
                                roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                            }
                        }
                    }
                }
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "XNetwork"
                    metadata.name: "configuration-gitops-flux-network"
                    spec.parameters = {
                        id: "uptest-gitops-flux-cluster"
                        region: "us-west-1"
                        vpcCidrBlock: "192.168.0.0/16"
                        subnets: [
                            {
                                availabilityZone: "us-west-1b"
                                type: "public"
                                cidrBlock: "192.168.0.0/18"
                            }
                            {
                                availabilityZone: "us-west-1c"
                                type: "public"
                                cidrBlock: "192.168.64.0/18"
                            }
                            {
                                availabilityZone: "us-west-1b"
                                type: "private"
                                cidrBlock: "192.168.128.0/18"
                            }
                            {
                                availabilityZone: "us-west-1c"
                                type: "private"
                                cidrBlock: "192.168.192.0/18"
                            }
                        ]
                    }
                }
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "XEKS"
                    metadata.name: "configuration-gitops-flux-cluster"
                    spec = {
                        parameters = {
                            accessConfig = {
                                authenticationMode = "API_AND_CONFIG_MAP"
                                bootstrapClusterCreatorAdminPermissions = True
                            }
                            id = "uptest-gitops-flux-cluster"
                            nodes = {
                                count = 1
                                instanceType = "t3.small"
                            }
                            region = "us-west-1"
                            version = "1.27"
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-gitops-flux-kubeconfig"
                            namespace = "upbound-system"
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items= _items