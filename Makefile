init:
	terraform init

plan:
	terraform plan -var-file var.tfvars

apply:
	terraform apply -var-file var.tfvars -input=false -auto-approve -parallelism=3 && cp terraform.tfstate terraform.tfstate.$$(terraform output -raw cluster_id)

destroy:
	terraform destroy -var-file var.tfvars -input=false -auto-approve -parallelism=3
