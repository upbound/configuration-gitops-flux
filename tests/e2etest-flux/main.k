
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.gitops.v1alpha1 as gitopsv1alpha1
import file


_items = [
    metav1alpha1.E2ETest{
        metadata.name = "flux-e2e-test"
        spec = {
            crossplane.autoUpgrade.channel = "Rapid"
            defaultConditions = ["Ready"]
            manifests = [
                {
                    apiVersion = "aws.platform.upbound.io/v1alpha1"
                    kind = "Network"
                    metadata = {
                        name = "configuration-gitops-flux-network"
                        namespace = "default"
                    }
                    spec.parameters = {
                        id = "uptest-gitops-flux-cluster"
                        region = "us-west-1"
                        vpcCidrBlock = "192.168.0.0/16"
                        subnets = [
                            {
                                availabilityZone = "us-west-1b"
                                type = "public"
                                cidrBlock = "192.168.0.0/18"
                            }
                            {
                                availabilityZone = "us-west-1c"
                                type = "public"
                                cidrBlock = "192.168.64.0/18"
                            }
                            {
                                availabilityZone = "us-west-1b"
                                type = "private"
                                cidrBlock = "192.168.128.0/18"
                            }
                            {
                                availabilityZone = "us-west-1c"
                                type = "private"
                                cidrBlock = "192.168.192.0/18"
                            }
                        ]
                    }
                }
                {
                    apiVersion = "aws.platform.upbound.io/v1alpha1"
                    kind = "EKS"
                    metadata = {
                        name = "configuration-gitops-flux-cluster"
                        namespace = "default"
                    }
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
                            version = "1.33"
                        }
                    }
                }
                gitopsv1alpha1.Flux {
                    metadata = {
                        name = "test-flux-instance"
                        namespace = "default"
                    }
                    spec = {
                        parameters = {
                            providerConfigName = "uptest-gitops-flux-cluster"
                            managementPolicies = ["*"]
                            operators = {
                                flux = { version = "2.16.4" }
                                fluxSync = { version = "1.13.4" }
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
            extraResources = [
                {
                    apiVersion = "pkg.crossplane.io/v1"
                    kind = "Configuration"
                    metadata.name = "configuration-aws-eks"
                    spec.package = "xpkg.upbound.io/upbound/configuration-aws-eks:v0.0.0-v2"
                }
                {
                    apiVersion = "pkg.crossplane.io/v1"
                    kind = "Configuration"
                    metadata.name = "configuration-aws-network"
                    spec.package = "xpkg.upbound.io/upbound/configuration-aws-network:v0.0.0-v2"
                }
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = "default"
                    }
                    stringData.credentials = file.read_env("UP_CLOUD_CREDENTIALS")
                }
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Secret"
                            secretRef = {
                                key = "credentials"
                                name = "aws-creds"
                                namespace = "default"
                            }
                        }
                    }
                }
            ]
            skipDelete = False
            timeoutSeconds = 4500
        }
    }
]
items = _items
