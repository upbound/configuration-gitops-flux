PROJECT_NAME := configuration-gitops-flux
UPTEST_INPUT_MANIFESTS := examples/flux-xr.yaml
UPTEST_SKIP_IMPORT := true
UPTEST_SKIP_UPDATE := true
XPKG_IGNORE ?= .github/workflows/*.yaml,.github/workflows/*.yml,examples/*.yaml,.work/uptest-datasource.yaml,.cache/render/*,test/provider/*
