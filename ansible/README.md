ansible-galaxy install -r requirements.yml

ansible-playbook -i ./inventory/prod/hosts.yml playbooks/test.yml --key-file "~/.ssh/id_rsa"

## to retrive the sessionId

export BASTION_SESSION_ID=$(terraform output -raw bastion_connection_session_id)
