resource "kubectl_manifest" "manifests" {
  for_each  = data.kubectl_path_documents.docs.manifests
  yaml_body = each.value

  #  depends_on = [
  #    module.alb_ingress_controller
  #  ]
}
