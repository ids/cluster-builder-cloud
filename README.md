# Cluster Builder Cloud

The original [cluster-builder](github.com/ids/cluster-builder) project became a bit bloated, and with VMWare struggling to find a footing in the new world, it was deprecated in 2020.  The best bits from the concept have been cherry picked into this new lightweight cloud based approach.

There are a lot of great K8s offerings among the major cloud providers, but none really well suited for the developer or DevOps professional wanting to play or go a bit deeper into K8s.  

And there is nothing quite like building your own clusters from scratch for developing a better understanding of the platform and digging into the architecture.

This simple little _IaC_ codebase is intended to forkable and immediately hackable for just that purpose.

> Of course there is always a locally run k8s, like `microK8s`, which is very easy to get up and running... great for development, but not quite the same for infrastructure as a true `kubeadm` based cluster.    

In this approach, we use:

1) Packer to build the AWS Ubuntu 20.22 Server based Node AMI
2) Terraform to create the AWS EC2 resources required
3) Ansible to provision the EC2 Instances with Kubernetes

> And when you are done experimenting, a simple `terraform destory` will save you large AWS bills :)

## Tools Required:

-  [Packer](https://www.packer.io/downloads) 
-  [Terraform](https://www.terraform.io/downloads)
-  [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

All easily downloaded/installed for the platform of your choice.  I grab the Hashicorp binaries directly from them, but usually just `sudo snap/apt-get install ansible` on Ubuntu.

## Setup

- Install [Packer](https://www.packer.io/downloads), [Terraform](https://www.terraform.io/downloads) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) for your platform
- Put your AWS `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` into ENV variables:

eg.
```
export AWS_ACCESS_KEY_ID=AKIASZNNDR4N7H5DOXXX
export AWS_SECRET_ACCESS_KEY=TP/PY3+BJnprPqJA9eKGXXX
```

# Instructions

This currently builds a very barebones Kubernetes EC2 cluster, but can be further customized and extended.

## Phase 1 - Packing the AMI

The __node-packer__ folder is the place to start, it will build up the AMI and publish it to your region.

`cd node-packer && packer build node-ubuntu.pkr.hcl`

The output will be used in the next phase.


## Phase 2 - Terraforming your EC2 Environment

Copy the AMI ID from the Packer output, or you can grab it from the `aws_manifest.json` file.  You will need to add it to the __Terraform__ `variables.tf` file, along with other key user specific settings such as __KeyPair__, __AWS Region__, etc.

> See the [variables.tf](terraform/ec2-k8s/variables.tf) for all current configuration variables

Once the variables have been set correctly, execute:

```
$ cd terraform/ec2-k8s
$ terraform init && terraform validate
```

and then

```
$ terraform apply
```

And observe the EC2 resources being created.  Terrform will output configuration lines that can be directly used in the Ansible inventory `hosts` file in the final phase.

> One of the great things about Terraform is that once you have deployed your EC2 resources, you can still make adjustments and changes and Terraform will track the deltas and apply the required changes.  Much better then imperative tools like Ansible for provisioning infrastructure resources with a GitOps mindset and really compliments the IaS nature of K8s.


## Phase 3 - Kubernetes Up and Running
There is a [hosts.sample](clusters/ec2-k8s/hosts.sample) to use as the template.

The final stage of the Terraform deployment produces output lines for the __[k8s-masters]__ and __[k8s-workers]__ sections of the Ansible inventory `hosts` file, which is used by the ansible scripts for provisioning __Kubernetes__.

Eg.
```
Outputs:

k8s_master_lines = {
  "0" = "ec2-99-79-9-250.ca-central-1.compute.amazonaws.com  ansible_host=99.79.9.250"
}
k8s_worker_lines = {
  "0" = "ec2-35-183-101-234.ca-central-1.compute.amazonaws.com  ansible_host=35.183.101.234"
}
ssh_to_master = "ssh ubuntu@ec2-99-79-9-250.ca-central-1.compute.amazonaws.com"

```

Copy and paste each of the corresponding lines into their respective sections in the inventory hosts file.

> Likely to be automated in the future. 

Eg. __Hosts__

```
[all:vars]
cluster_name=ec2-k8s
remote_user=ubuntu

k8s_workloads_on_master=true

[k8s_masters]
ec2-99-79-9-250.ca-central-1.compute.amazonaws.com  ansible_host=99.79.9.250

[k8s_workers]
ec2-35-183-101-234.ca-central-1.compute.amazonaws.com  ansible_host=35.183.101.234

```

When your `clusters/ec2-k8s/hosts` file is updated and in place, there is a simple bash script that wraps the ansible playbook:

```
$ bash deploy-k8s
```

Which is really just a bash wrapper for the `ubuntu-k8s` playbook, ported largely from the original `cluster-builder` project:
```
    ansible-playbook -i $INVENTORY_FILE ansible/ubuntu-k8s.yml  --extra-vars="cluster_pkg_folder=${CLUSTER_PKG_FOLDER}"

```

At the end of the deployment, the script will output some useful information about your new K8s cluster:

```
Deployed in: 4 min 18 sec
------------------------------------------------------------

The kube-config file can be found at clusters/ec2-k8s/kube-config

kubectl --kubeconfig=clusters/ec2-k8s/kube-config get pods --all-namespaces

------------------------------------------------------------
```

> Just like old [cluster-builder](github.com/ids/cluster-builder) used to.