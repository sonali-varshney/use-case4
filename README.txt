wget https://raw.githubusercontent.com/apache/devlake/main/docker-compose.yml   # it will not work instead ni
git clone https://github.com/apache/incubator-devlake.git
vi docker-compose-dev.yml  #comment 5432 (the port which is overlapping(postgres ko rehne dena h dusre wale ko dlt kr do)
sudo docker-compose -f docker-compose-dev.yml up -d
sudo docker ps -a
sudo docker-compose -f docker-compose-dev.yml down
openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1

To check if a specific repository exists, you can provide its name to the command. It will return an error if the repository is not found
aws ecr describe-repositories --repository-names your-repo-name

# Create a repository named 'my-repo' and ignore the error if it already exists.
aws ecr create-repository --repository-name my-repo || true

By default, the failed command will print an error message to your terminal's standard error stream. To suppress this output and have a completely clean command, you can redirect the error stream to /dev/null
aws ecr create-repository --repository-name my-app >/dev/null 2>&1 || true


aws ecr create-repository --repository-name appointment >/dev/null 2>&1 || true

docker build -t appointmentLocalName .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <URI> 
docker tag appointmentLocalName:latest  <URI>/appointment:latest


aws ecr create-repository --repository-name appointmentrepo >/dev/null 2>&1 || true
docker build -t appo .
docker tag appo:latest  561947681169.dkr.ecr.us-east-1.amazonaws.com/appointmentrepo/appointmentrepo:latest
docker push 561947681169.dkr.ecr.us-east-1.amazonaws.com/appointmentrepo:latest


error-name unknown: The repository with name 'appointmentrepo/appointmentrepo' does not exist in the registry with



kubernetes.io/role/elb, kubernetes.io/role/internal-elb ->Subnet tags are required for aws load blncr controller to pick correct subnets



provider "helm" {
    kubernetes = {
        host  = data.aws_eks_cluster.eks_cluster.endpoint
        token = data.aws_eks_cluster_auth.eks_auth.token
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
        load_config_file = false
    }
}

host
 This is the address for your Kubernetes cluster's API server.
 
cluster_ca_certificate
The Certificate Authority (CA) certificate is used to securely verify the identity of the Kubernetes API server. It ensures that you are connecting to the legitimate cluster and that your communication is secure.
base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data) retrieves the cluster's CA certificate from the same EKS data source. It then decodes the certificate from its base64 format, which is the correct format needed for authentication
here are we creating certificate or how it is?I didnt understand this certificate is already created or wde are creating. Help me in understanding eassy way
The creation of the certificate
Who creates it? The certificate is created and managed by the Amazon EKS service itself when it provisions your Kubernetes cluster. You can think of this as EKS giving your cluster its own identification card.
What is it for? This "ID card," or Certificate Authority (CA) certificate, is a security credential. Its job is to prove to anyone trying to connect that they are talking to the real, legitimate EKS cluster and not an imposter. This ensures secure, encrypted communication.

token
and for token, we need to provide token for authentication but we are asking for token from k8s itself. I didnt understand. please help me understand in layman terms
That's an insightful question. It seems like a loop: you need a token to talk to Kubernetes, but you need to talk to Kubernetes to get a token. The answer is that it's a two-step, automated process that relies on your existing AWS credentials. 
Here is the process broken down in a simple, step-by-step manner:
The big picture
Terraform is a tool, and just like you, it needs to prove who it is to AWS before it can get a token to talk to your EKS cluster. The critical part is that you have already set up authentication for Terraform with AWS separately.
Once AWS has confirmed Terraform's identity, Terraform is granted permission to request a special, short-lived token for your EKS cluster. This is what the data.aws_eks_cluster_auth.eks_auth.token block does. 
This data source specifically tells Terraform: "Hey, AWS, please generate a temporary token for the EKS cluster we are about to manage, and give me the token so I can use it to authenticate with Kubernetes.
The flow is like this:
Terraform: (to AWS) "Hello, here are my AWS credentials."
AWS: (to Terraform) "Alright, I recognize you. What do you need?"
Terraform: (to AWS) "I need a temporary token to talk to the EKS cluster named eks_cluster."
AWS: (to Terraform) "Here is your token. It is only valid for a short time."
Terraform: (to Helm provider) "Hello, Helm provider. Here is the EKS token from AWS, here is the cluster address, and here is the certificate for security. Let's get to work."
