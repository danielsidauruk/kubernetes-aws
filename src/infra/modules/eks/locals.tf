locals {
  oidc_provider_host = replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")
}
