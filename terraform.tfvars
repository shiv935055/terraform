project_id = "shiv-test-457317"
region     = "asia-south1"

domains = [
  "tf-deploy-1.plutos.one",
  "tf-deploy-2.plutos.one",
  "tf-deploy-3.plutos.one",
  "tf-cloud-run.plutos.one"
]

cloud_run_service = "tf-test"
cloud_run_domain  = "tf-cloud-run.plutos.one"
network           = "default"
target_tags       = ["gke-backend"]

gke_services = {
  service1 = {
    health_check_port = 8080
    health_check_path = "/health1"
    domain            = "tf-deploy-1.plutos.one"
    negs = [
      {
        zone = "asia-south1-a"
        name = "k8s1-7041f46b-nginx-deployment-svc-1-80-bd66c9a4"
      },
      {
        zone = "asia-south1-b"
        name = "k8s1-7041f46b-nginx-deployment-svc-1-80-bd66c9a4"
      }
    ]
  }
  service2 = {
    health_check_port = 8081
    health_check_path = "/health2"
    domain            = "tf-deploy-2.plutos.one"
    negs = [
      {
        zone = "asia-south1-a"
        name = "k8s1-7041f46b-nginx-deployment-svc-2-80-0c77f13f"
      },
      {
        zone = "asia-south1-b"
        name = "k8s1-7041f46b-nginx-deployment-svc-2-80-0c77f13f"
      }
    ]
  }
  service3 = {
    health_check_port = 8082
    health_check_path = "/health3"
    domain            = "tf-deploy-3.plutos.one"
    negs = [
      {
        zone = "asia-south1-a"
        name = "k8s1-7041f46b-nginx-deployment-svc-3-80-e0735884"
      },
      {
        zone = "asia-south1-b"
        name = "k8s1-7041f46b-nginx-deployment-svc-3-80-e0735884"
      }
    ]
  }
}
