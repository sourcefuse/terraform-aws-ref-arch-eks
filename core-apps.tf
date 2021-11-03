// TODO: turn into standard module
// TODO: tighten security
// TODO: interpolate manifests where needed, convert to helm, or use native k8s app module
data "kubectl_path_documents" "docs" {
  pattern = "./manifests/*.yaml"
}


resource "kubectl_manifest" "manifests" {
  depends_on = [
    time_sleep.helm_ingress_sleep
  ]
  for_each  = data.kubectl_path_documents.docs.manifests
  yaml_body = each.value
}
