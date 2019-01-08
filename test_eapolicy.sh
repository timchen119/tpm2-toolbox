set -x

pcr_ids="0"
alg_pcr_policy=sha256
file_pcr_value=pcr.bin
file_policy=policy.data
file_authorized_policy_1=auth_policy_1.data
file_authorized_policy_2=auth_policy_2.data
file_session_file="session.ctx"
file_private_key="signing_key_private.pem"
file_public_key="signing_key_public.pem"
file_verifying_key_name="signing_key.name"
file_verifying_key_ctx="signing_key.ctx"
file_policyref="policyref"

export TPM2TOOLS_TCTI=device:/dev/tpmrm0

cleanup() {
	rm -f  $file_pcr_value $file_policy $file_session_file $file_private_key \
	$file_public_key $file_verifying_key_name \
	$file_verifying_key_ctx $file_policyref $file_authorized_policy_1 \
	$file_authorized_policy_2
	tpm2_flushcontext -S $file_session_file 2>/dev/null || true
}

trap cleanup EXIT

cleanup

generate_policy_authorize () {
  local file_authorized_policy="$3" file_policy="$1" file_policyref="$2" file_verifying_key_name="$4"

  sudo -E tpm2_startauthsession -S $file_session_file
  sudo -E tpm2_policyauthorize -S $file_session_file -o $file_authorized_policy -f $file_policy -n $file_verifying_key_name #-q $file_policyref
  sudo -E tpm2_flushcontext -S $file_session_file
}

## Create a signing authority
openssl genrsa -out $file_private_key 2048
openssl rsa -in $file_private_key -out $file_public_key -pubout
sudo -E tpm2_loadexternal -G rsa -a o -u $file_public_key -o $file_verifying_key_ctx -n $file_verifying_key_name

## Create a policy to be authorized like a pcr policy:
sudo -E tpm2_pcrlist -L ${alg_pcr_policy}:${pcr_ids} -o $file_pcr_value
sudo -E tpm2_startauthsession -S $file_session_file
sudo -E tpm2_policypcr -S $file_session_file -L ${alg_pcr_policy}:${pcr_ids} -F $file_pcr_value -f $file_policy
sudo -E tpm2_flushcontext -S $file_session_file

## Sign the policy
openssl dgst -$alg_pcr_policy -sign $file_private_key -out pcr.signature $file_policy

## Authorize the policy in the policy digest
dd if=/dev/urandom of=$file_policyref bs=1 count=32
generate_policy_authorize $file_policy $file_policyref $file_authorized_policy_1 $file_verifying_key_name

## Create a TPM object like a sealing object with the authorized policy based authentication
sudo -E tpm2_createprimary -a o -g $alg_pcr_policy -G rsa -o prim.ctx
sudo -E tpm2_create -g $alg_pcr_policy -u sealing_pubkey.pub -r sealing_prikey.pub -I- -C prim.ctx -L $file_authorized_policy_1 <<< "secret to seal"

## Satisfy policy and unseal the secret
sudo -E tpm2_verifysignature -c $file_verifying_key_ctx -G $alg_pcr_policy -m $file_policy -s pcr.signature -t verification.tkt -f rsassa
sudo -E tpm2_startauthsession -a -S $file_session_file
sudo -E tpm2_policypcr -S $file_session_file -L ${alg_pcr_policy}:${pcr_ids} -f $file_policy
sudo -E tpm2_policyauthorize -S $file_session_file -o $file_authorized_policy_1 -f $file_policy -n $file_verifying_key_name -t verification.tkt
sudo -E tpm2_load -C prim.ctx -u sealing_pubkey.pub -r sealing_prikey.pub -o sealing_key.context
sudo -E tpm2_unseal -p"session:$file_session_file" -c sealing_key.context
sudo -E tpm2_flushcontext -S $file_session_file

### Extend PCR and create new policy

echo "Create new policy....."

sudo -E tpm2_pcrextend ${pcr_ids}:${alg_pcr_policy}=e7011b851ee967e2d24e035ae41b0ada2decb182e4f7ad8411f2bf564c56fd6f

mkdir -p new
cp $file_private_key new/
cp $file_verifying_key_name new/
cp $file_verifying_key_ctx new/
cd new

## Create a policy to be authorized like a pcr policy:
sudo -E tpm2_pcrlist -L ${alg_pcr_policy}:${pcr_ids} -o $file_pcr_value
sudo -E tpm2_startauthsession  -S $file_session_file
sudo -E tpm2_policypcr  -S $file_session_file -L ${alg_pcr_policy}:${pcr_ids} -F $file_pcr_value -f $file_policy
sudo -E tpm2_flushcontext -S $file_session_file

## Sign the policy
openssl dgst -$alg_pcr_policy -sign $file_private_key -out pcr.signature $file_policy

## Authorize the policy in the policy digest
generate_policy_authorize $file_policy $file_policyref $file_authorized_policy_2 $file_verifying_key_name

cd ..
mkdir -p unseal
cp new/$file_policy unseal/
cp new/pcr.signature unseal/
cp prim.ctx unseal/
cp sealing_pubkey.pub unseal/
cp sealing_prikey.pub unseal/
cp $file_verifying_key_ctx unseal/
cp $file_verifying_key_name unseal/
cd unseal

#test crash
#sudo -E tpm2_pcrextend ${pcr_ids}:${alg_pcr_policy}=e7011b851ee967e2d24e035ae41b0ada2decb182e4f7ad8411f2bf564c56fd11

## Satisfy policy and unseal the secret
sudo -E tpm2_verifysignature -c $file_verifying_key_ctx -G $alg_pcr_policy -m $file_policy -s pcr.signature -t verification.tkt -f rsassa
sudo -E tpm2_startauthsession -a -S $file_session_file
sudo -E tpm2_policypcr -S $file_session_file -L ${alg_pcr_policy}:${pcr_ids} -f $file_policy
sudo -E tpm2_policyauthorize -S $file_session_file -o $file_authorized_policy_2 -f $file_policy -n $file_verifying_key_name -t verification.tkt
sudo -E tpm2_load -C prim.ctx -u sealing_pubkey.pub -r sealing_prikey.pub -o sealing_key.context
sudo -E tpm2_unseal -p"session:$file_session_file" -c sealing_key.context
sudo -E tpm2_flushcontext -S $file_session_file

cd ..
diff $file_authorized_policy_1 new/$file_authorized_policy_2

exit 0


