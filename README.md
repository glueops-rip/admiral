# admiral


The Admiral cluster is a Kubernetes clusters that helps manage one or more captain instances. You could use the same admiral instance for all your environments/clusters/regions or you could even go as far as 1 per environment per region. For HA and DR reasons we could recommend: 1 Admiral cluster per region per cloud this way if you are multi-region or multi-cloud you can still upgrade/manage your captains easily.


To Deploy an Admiral we recommend keeping it simple. The Admiral can even lag behind the version of Argocd that your captain is using. We do a very bare bones/happy path deployment so that the Admiral can be recreated easily as needed.


In this example we will use Linode.com


1) Create a Linode cluster. (See image) and then just click `Create Cluster`.
<img width="1313" alt="image" src="https://user-images.githubusercontent.com/6570292/210114331-6c64d774-4127-4005-a896-bd049139bf74.png">


2) The cluster on Linode will usually spin up within a few minutes but shouldn't take more than 20minutes. Once it's online download the kubeconfig from the portal. (Note you may want to setup a VPN or some firewall rules to ensure no one else but authorized users can communicate with your kubernetes instances and the services we will be deploying ex. ArgoCD)

4. Take the YAML and save it to your home directory `~/.kube/config`. And then, assuming you have a matching kubectl version (ex. 1.24) you should be able to run something like `kubectl get pods --all-namespaces` and see that all your pods came up in the last 5-60 minutes.

5. Let's deploy argocd.
```bash
$ kubectl create namespace argocd
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.11/manifests/install.yaml
$ kubectl wait pods --all -n argocd --for condition=Ready --timeout=120s
$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type":  "LoadBalancer"}}'
```

6. Get the hostname/url for ArgoCD with:
```bash
$ kubectl get service argocd-server -n argocd --output=jsonpath="{.status.loadBalancer.ingress[0].hostname}"
```
Example output: `45-79-244-196.ip.linodeusercontent.com`

7. Go to https://45-79-244-196.ip.linodeusercontent.com and ignore any SSL errors. If you are in chrome you may need to type `thisisunsafe` so that chrome will let you proceed.

8. Get the `admin` password for argocd.
```bash
$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Example output: `ozB-Bbesadsdasi2c`

9. Login to the url in step #7 with the username `admin` and the password from #8

10. You have a working admiral cluster. It's best to have a proper firewall/security group configured so that not everyone can hit your argocd instance.

11. Last thing you will want to do is add a customer ArgoCD health check. This will help the admiral cluster know when the captain is actually healthy.

Deploy this manifest within the `argocd` namespace:

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
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
```

Login Details from above:

ArgoCD URL: https://45-79-244-196.ip.linodeusercontent.com
ArgoCD User: admin
ArgoCD Password: ozB-Bbesadsdasi2c

12. Login with the argocd CLI using:

```bash
$ argocd login 45-79-244-196.ip.linodeusercontent.com --username admin --password ozB-Bbesadsdasi2c --grpc-web --insecure
```

13. You are all set with your admiral config and can go ahead and delete your local kubeconfig with `rm -rf ~/.kube/config` and now proceed to bring up your captain cluster.




