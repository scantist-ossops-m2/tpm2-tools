# SPDX-License-Identifier: BSD-3-Clause

source helpers.sh

file_primary_key_ctx=context.p_B1
file_rsaencrypt_key_pub=opuB1_B8
file_rsaencrypt_key_priv=oprB1_B8
file_rsaencrypt_key_ctx=context_loadext_out_B1_B8
file_rsadecrypt_key_ctx=context_load_out_B1_B8
file_rsaencrypt_key_name=name.load.B1_B8

file_rsa_en_output_data=rsa_en.out
file_rsa_de_output_data=rsa_de.out
file_input_data=secret.data

alg_hash=sha256
alg_primary_key=rsa
alg_rsaencrypt_key=rsa

cleanup() {
    rm -f $file_input_data $file_primary_key_ctx $file_rsaencrypt_key_pub \
    $file_rsaencrypt_key_priv $file_rsaencrypt_key_ctx \
    $file_rsaencrypt_key_name $file_output_data $file_rsa_en_output_data \
    $file_rsa_de_output_data $file_rsadecrypt_key_ctx label.dat

    if [ "$1" != "no-shut-down" ]; then
        shut_down
    fi
}
trap cleanup EXIT

start_up

cleanup "no-shut-down"

echo "12345678" > $file_input_data

tpm2 clear

tpm2 createprimary -Q -C e -g $alg_hash -G $alg_primary_key \
-c $file_primary_key_ctx

tpm2 create -Q -g $alg_hash -p foo -G $alg_rsaencrypt_key \
-u $file_rsaencrypt_key_pub -r $file_rsaencrypt_key_priv \
-C $file_primary_key_ctx

tpm2 loadexternal -Q -C n -u $file_rsaencrypt_key_pub \
-c $file_rsaencrypt_key_ctx

tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -o $file_rsa_en_output_data < \
$file_input_data

tpm2 load -Q -C $file_primary_key_ctx -u $file_rsaencrypt_key_pub \
-r $file_rsaencrypt_key_priv -n $file_rsaencrypt_key_name \
-c $file_rsadecrypt_key_ctx

tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -p foo -o \
$file_rsa_de_output_data $file_rsa_en_output_data

# Test the diffeent padding schemes ...

tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -o $file_rsa_en_output_data \
-s rsaes < $file_input_data
tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -p foo -o \
$file_rsa_de_output_data -s rsaes $file_rsa_en_output_data

tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -o $file_rsa_en_output_data \
-s null < $file_input_data
tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -p foo -o \
$file_rsa_de_output_data -s null $file_rsa_en_output_data

# Test the label option with a string
tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -l mylabel \
-o $file_rsa_en_output_data < $file_input_data
tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -l mylabel -p foo \
-o $file_rsa_de_output_data $file_rsa_en_output_data

# Test the label option with a file
echo "my file label" > label.dat
tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -l label.dat \
-o $file_rsa_en_output_data < $file_input_data
tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -l label.dat -p foo \
-o $file_rsa_de_output_data $file_rsa_en_output_data

# Test RSA encryption/ decryption with OAEP padding mode
tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -o $file_rsa_en_output_data \
-s oaep < $file_input_data

tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -p foo -o \
$file_rsa_de_output_data -s oaep $file_rsa_en_output_data

# Test RSA enc/ dec with OAEP-SHA1 mode
tpm2 rsaencrypt -Q -c $file_rsaencrypt_key_ctx -o $file_rsa_en_output_data \
-s oaep-sha1 < $file_input_data

tpm2 rsadecrypt -Q -c $file_rsadecrypt_key_ctx -p foo -o \
$file_rsa_de_output_data -s oaep-sha1 $file_rsa_en_output_data


exit 0
