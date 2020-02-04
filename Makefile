.SILENT:

init:
	scripts/init.sh

validate:
	scripts/validate.sh

apply:
	scripts/apply.sh

invoke:
	scripts/invoke.sh

destroy:
	cd terraform && terraform destroy -auto-approve