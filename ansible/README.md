```bash
ansible-galaxy install -r requirements.yml
```

```bash
#From root:
source ./scripts/start-ssh-session.sh
#from ansible folder
ansible-playbook -i ./inventory/prod/hosts.yml --key-file "../.secret/id_rsa_cloud" -e "bastion_session_id=$BASTION_SESSION_ID" -e "main_domain=<domain-url>" main.yml
```
