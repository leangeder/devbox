# devops-kubernetes-vault
Hashicorp vault kubernetes manifests

## Obtaining access to vault
In order to obtain access to vault, you will require the root token to be able login initially.
To obtain the root token key, you will need to do the following:
```sh
gsutil cat gs://beamery-vault-storage/root-token.enc | base64 -d | gcloud kms decrypt --project beamery-global --location global --keyring vault --key vault-init --ciphertext-file - --plaintext-file -
```

In order to do this, you will need permission inside `beamery-global` for:
- Google KMS
- Cloud Storage


## Files stored inside Google Cloud Storage
In the event that you need to manually fix or interact as root with Vault, you may need to access these files:

- `gs://beamery-vault-storage/root-token.enc`
- `gc://beamery-vault-storage/unseal-key.json.enc`

These files have been encrypted with a key stored inside kms.
In order to decrypt them, you will need access to kms in beamery global.

## External Documments
In building vault, we have created some documentation external from this repo referenced here:
- [Vault at Beamery](https://paper.dropbox.com/doc/Vault-at-Beamery-fzhVaBdBtLk5IWoYPbFQM)
- [Learning how to use Vault](https://paper.dropbox.com/doc/Vault-implementation-vrGZRxzhqOIId4EWyHUKj)
- [Architecture Slides](https://docs.google.com/presentation/d/1M06Nmoyz7b33nb2C6MRCEigsla475QhhG_X5GnMVh1A/edit#slide=id.g3722881b24_0_228)
