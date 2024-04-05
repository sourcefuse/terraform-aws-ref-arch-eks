<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.44.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.13.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.27.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.11.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_health_check"></a> [health\_check](#module\_health\_check) | git::https://github.com/sourcefuse/terraform-k8s-app.git | 0.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.app_domain_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [helm_release.ingress_nginx](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress) | resource |
| [kubernetes_namespace.ingress_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [time_sleep.nlb_provisioning_time](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_lb.eks_nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ACM certificate ARN for the ingress controller to use for L7 load balancing. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster that the ingress controller will be deployed into. This value will also be used for the 'Name' tag of the NLB. | `string` | n/a | yes |
| <a name="input_health_check_domains"></a> [health\_check\_domains](#input\_health\_check\_domains) | List of A record domains to create for the health check service | `list(string)` | n/a | yes |
| <a name="input_health_check_image"></a> [health\_check\_image](#input\_health\_check\_image) | Image version for Nginx | `string` | `"nginx:alpine"` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Version of nginx ingress helm chart to use. Set a value matching your kubernetes version | `string` | `"4.6.0"` | no |
| <a name="input_ingress_namespace_name"></a> [ingress\_namespace\_name](#input\_ingress\_namespace\_name) | Namespace name | `string` | `"ingress-nginx"` | no |
| <a name="input_route_53_zone_id"></a> [route\_53\_zone\_id](#input\_route\_53\_zone\_id) | Route 53 zone ID to use when making an A record for the health check. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nlb_dns_name"></a> [nlb\_dns\_name](#output\_nlb\_dns\_name) | DNS name of the NLB created for ingress. |
| <a name="output_nlb_zone_id"></a> [nlb\_zone\_id](#output\_nlb\_zone\_id) | Route53 zone ID of the NLB created for ingress. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
