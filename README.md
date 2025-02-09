# VRM Oracle CLOUD

You probably do not want to use this.

## Bastion connection

```bash
ssh -i <key-path> -N -L 2201:10.1.10.10:22 -p 22 $BASTION_SESSION_ID@host.bastion.sa-vinhedo-1.oci.oraclecloud.com &
ssh -i <key-path> ubuntu@localhost -p 2201
```
