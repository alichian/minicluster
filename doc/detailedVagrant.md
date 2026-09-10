# Vagrant configuration
**Vagrant** is a ready-to-use VMs manager. Under Fedora Linux the
straightforward provider to use is **libvirt**. Once the machines are
up it is possible to use them as a substrate to run a *Kubernetes*
cluster.
Because the hardware in my specific case is limited, the best choice is
to use the *k3s* implementation: lighter and adapted to small uses. 

## Vagrantfile
After the installation of :
- vagrant 
- vagrant-libvirt
- libvirt-daemon-driver-network 
- dnsmasq
It is necessary to make the libvir daemon a stable process. In order
to do this just enable and start the service responsible for it with the following commands :
```
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```
Now it is possible to configure a system of some VMs. To begin with
the simplest structure 
The configuration file *Vagrantfile* has this structure:
```
Vagrant.configure("2") do |config|
  config.vm.box = "debian/trixie64"

  nodes = {
    "planer"  => { memory: 2048, cpus: 2 },
    "worker1" => { memory: 4096, cpus: 2 },
    "worker2" => { memory: 4096, cpus: 2 }
  }

  nodes.each do |name, spec|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.provider :libvirt do |lv|
        lv.memory = spec[:memory]
        lv.cpus = spec[:cpus]
      end
    end
  end
end
```
Where 

## *K3s* installation and configuration
Once connected on the *planer* we have to install the *k3s* flavor of
**kubernetes** and save certain infos to authorize the communication
between the three VMs
```
curl -sfL https://get.k3s.io | sh -
sudo cat /var/lib/rancher/k3s/server/node-token 
```
And save somewhere on the host. 
Then we have to assign a taint to the planer that should be just a
manager and should never run any pod. 
```
kubectl taint nodes planer \
node-role.kubernetes.io/control-plane=:NoSchedule
```

Instead on *worker1* and *worker2*, pointing at admin's IP: 
```
curl -sfL https://get.k3s.io | K3S_URL=https://<admin-ip>:6443 \ K3S_TOKEN=<token-from-above> sh -
```

Now it is time to pull the kubeconfig back to the host so it is possible
to concretely call *kubectl* from outside, from the host machine 
```
scp admin:/etc/rancher/k3s/k3s.yaml ~/.kube/minicluster.yaml
sed -i 's/127.0.0.1/<admin-ip>/' ~/.kube/minicluster.yaml
export KUBECONFIG="~/.kube/minicluster.yaml"
kubectl get nodes
```
Now a *kubernetes* cluster should be visible : the control-plane *planer* and two workers.

## Test a simple docker container
In order to test the right setup of *k3s* it is a good thing to run a
simple, one-shot container but with the interesting feature that it
needs to mount a host directory in order to accomplish its job.
First of all, the image of the container has to be "exported" and
delivered and then "imported" on each worker:
```
docker save -o test-job.tar test-job:latest
scp -i ~/.ssh/id_ed25519 test-job.tar vagrant@<worker1-ip>:/tmp/
vagrant ssh <workerX> -c "sudo k3s ctr images import /tmp/test-job.tar"
```
Then prepare a host directory that will be mounted on the pod on one
of the two worker
```
mkdir -p /path/to/vagrant-project/test-job-data
cp /path/to/data/*  /path/to/vagrant-project/test-job-data
```
then in the *manifesto.yaml* it is necessary just to update the
eventual "pathHost" with /vagrant. In fact, the nfs-service provide a
transparent way to share data in the host with the VMs that will run
the actual pods. 

To be precise is a *nfs-service* is running correctly it is possible
to avoid use *scp* and simply upload the image puts under the vagrant
directory: 
```vagrant ssh <workerX> -c "sudo k3s ctr images import
/vagrant/test-job.tar"``` 
