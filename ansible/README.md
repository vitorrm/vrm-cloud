```bash
ansible-galaxy install -r requirements.yml
```

```bash
BASTION_SESSION_ID=$(terraform output -raw bastion_connection_session_id)
ansible-playbook -i ./inventory/prod/hosts.yml playbooks/test.yml --key-file "../.secret/id_rsa_cloud" -e "bastion_session_id=$BASTION_SESSION_ID"
```
