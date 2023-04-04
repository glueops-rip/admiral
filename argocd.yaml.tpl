crds:
  install: false

# many of these ignored values can be found in the argo-cd helm chart docs: https://artifacthub.io/packages/helm/argo/argo-cd
# @ignored
dex:
  enabled: false
redis-ha:
  enabled: true
# @ignored
controller:
  replicas: 1
# @ignored
repoServer:
  autoscaling:
    enabled: true
    minReplicas: 2
# @ignored
applicationSet:
  replicaCount: 2
server:
  # @ignored
  autoscaling:
    enabled: true
    minReplicas: 2
  config:
    # @ignored
    exec.enabled: "true"
    # This helps argocd know what resources it should be manging. This way if argocd manages an operator and that operator creates a pvc, it won't try and manage the pvc.
    # https://argo-cd.readthedocs.io/en/stable/user-guide/resource_tracking/#choosing-a-tracking-method
    # @ignored
    application.resourceTrackingMethod: "annotation+label"
    # https://argo-cd.readthedocs.io/en/stable/operator-manual/health/#argocd-app
    # https://github.com/argoproj/argo-cd/issues/3781
    # enables health check assessment for argocd applications as we are using sync-waves
    # @ignored
    resource.customizations.health.argoproj.io_Application: |
      hs = {}
      hs.status = "Progressing"
      hs.message = ""
      if obj.status ~= nil then
        if obj.status.health ~= nil then
          hs.status = obj.status.health.status
          if obj.status.health.message ~= nil then
            hs.message = obj.status.health.message
          end
        end
      end
      return hs
    # This is a bit of a hack but allows the external-secret to never error out and always appear healthy to argocd. We probably want to remove this.
    # @ignored
    resource.customizations.health.external-secrets.io_ExternalSecret: |
      hs = {}
      hs.status = "Healthy"
      return hs
    url: "https://argocd.<cluster_env>.<tenant-name-goes-here>.onglueops.rocks"
    # -- To create a clientID and clientSecret please reference: https://github.com/GlueOps/github-oauth-apps
    # This dex.config is to create a GitHub connector for SSO to ArgoCD.
    # @default -- `''` (See [values.yaml])
    oidc.config: |
      name: GitHub SSO
      issuer: https://dex.<cluster_env>.<tenant-name-goes-here>.onglueops.rocks
      clientID: argocd
      clientSecret: XXXXXXXXXXXXXXXXXXXXXXXXXX
      redirectURI: https://argocd.<cluster_env>.<tenant-name-goes-here>.onglueops.rocks/api/dex/callback
  rbacConfig:
    # -- A good reference for this is: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/
    # This default policy is for GlueOps orgs/teams only. Please change it to reflect your own orgs/teams.
    # `development` is the project that all developers are expected to deploy under
    # @default -- `''` (See [values.yaml])
    policy.csv: |
      g, GlueOps:argocd_super_admins, role:admin
      g, glueops-rocks:developers, role:developers
      p, role:developers, clusters, get, *, allow
      p, role:developers, *, get, development, allow
      p, role:developers, repositories, *, development/*, allow
      p, role:developers, applications, *, development/*, allow
      p, role:developers, exec, *, development/*, allow
  # @ignored
  extraArgs:
    - --insecure
  # @ignored
  service:
    type: ClusterIP
  ingress:
    hosts: ["argocd.<cluster_env>.<tenant-name-goes-here>.onglueops.rocks"]
    # @ignored
    enabled: true
    # this public-authenticated leverages the authentication proxy (pomerium)
    # @ignored
    ingressClassName: public-authenticated
    # standard annotations for pomerium: https://www.pomerium.com/docs/deploying/k8s/ingress
    # @ignored
    annotations:
      ingress.pomerium.io/allow_any_authenticated_user: 'true'
      ingress.pomerium.io/pass_identity_headers: 'true'