################################################
# Imports
################################################
load('ext://uibutton', 'cmd_button')
load('packages/tilt/podman.tiltfile', 'podman_build')
load('packages/tilt/common.tiltfile', 'REGISTRY', 'NAMESPACE', 'TF_ROOT_DIR')

################################################
# INIT
################################################
allow_k8s_contexts('terraform-dev-ue2')
if k8s_context() != 'terraform-dev-ue2':
  fail("You can only use the 'terraform-dev-ue2' context when using Tilt. Switch by running 'kubectx terraform-dev-ue2'")

default_registry (REGISTRY)
update_settings ( max_parallel_updates = 3 , k8s_upsert_timeout_secs = 900 , suppress_unused_image_warnings = None )

LABELS = ['monolith']
TF_DIR = "{}/monolith_deployment".format(TF_ROOT_DIR)
IMAGE = "{}/monolith".format(REGISTRY)

################################################
# Cluster resources
################################################

podman_build(
  IMAGE,
  "packages/monolith",
  extra_flags=[
    "-f", "packages/monolith/Containerfile"
   ],
  deps=  [
     "packages/monolith",
   ],
   live_update = [
     sync('packages/monolith', '/src')
   ]
)

k8s_custom_deploy(
  "monolith",
  ["bash", "-c", "terragrunt apply -auto-approve -no-color --terragrunt-non-interactive 1>&2 && kubectl get -n {}-monolith deployments -o yaml".format(NAMESPACE)],
  "terragrunt destroy -auto-approve -no-color --terragrunt-non-interactive",
  [
    TF_DIR,
    'packages/terraform/monolith_deployment',
    'packages/terraform/kubernetes_namespace',
    'packages/terraform/kubernetes_deployment',
    'packages/terraform/kubernetes_ingress',
    'packages/terraform/kubernetes_irsa',
    'packages/terraform/kubernetes_redis',
    'packages/terraform/aws_s3_private_bucket',
  ],
  apply_dir=TF_DIR,
  delete_dir=TF_DIR,
  image_deps = [IMAGE]
)

load('ext://uibutton', 'cmd_button')
cmd_button('force-apply-monolith',
          argv=["bash", "-c", "cd {}; terragrunt init".format(TF_DIR)],
          resource='monolith',
          icon_name='arrow_circle_up',
          text='force apply',
)
cmd_button('force-build-monolith',
          argv=["bash", "-c", "cd src; echo $RANDOM > tilt.trigger"],
          resource='monolith',
          icon_name='deployed_code',
          text='Force Rebuild',
)

k8s_resource(
  workload='monolith',
  new_name="monolith",
  labels=LABELS,
  links = [
    "dev.hudsonts.com/{}-monolith".format(NAMESPACE),
  ]
)