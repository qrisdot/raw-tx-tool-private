# sign P2PKH tx
utxo_list=(
    #  $1:txid $2:vout $3:pub_key $4:redeem_script $5:amount $6:priv_key
    #in=b90d51d9e2acd91b0a0ad61f0729694699bff73239452392a70efc4d5b9958f8:1:76a914ecebae831bbfbd7827542a82da4dc136e1288f7188ac::1.3:cQuzMWdzbJezujAaAiMNq4Gr6zcFZt7BeD2VGUEN3LYBzZYgipRF
    in=b90d51d9e2acd91b0a0ad61f0729694699bff73239452392a70efc4d5b9958f8:0:76a914ecebae831bbfbd7827542a82da4dc136e1288f7188ac:::cQuzMWdzbJezujAaAiMNq4Gr6zcFZt7BeD2VGUEN3LYBzZYgipRF
)
out_list=(
     outaddr=1.2999:n37g6n1JEsCGb9ctfoHT6epv8znnhtP522
)

C_TX="./bitcoin-tx"
NET="-testnet"
C_SIGN="bash cli.bash signrawtransaction "
create_tx_cmd=" $C_TX $NET -create "
for i in "${utxo_list[@]}"
do
    data=$(echo $i | awk -F: {'print $1":"$2'})
    create_tx_cmd="${create_tx_cmd} $data"
done

for i in "${out_list[@]}"
do
    create_tx_cmd="${create_tx_cmd} $i"
done

#echo ${create_tx_cmd}
raw_tx=`eval ${create_tx_cmd}`
if [ -z "$raw_tx" ] ; then
    echo " Could not create tx with ${create_tx_cmd}!"
    exit 1
fi

sign_param_in="["
sep=','
for((i=0;i<${#utxo_list[@]};i++))
do
    if [ "$i" -gt 0 ]; then
        sign_param_in=${sign_param_in}","
    fi
    sign_param_in=${sign_param_in}"{"
    data="${utxo_list[$i]}"
    data=$(echo $data| sed -e s/^.*=//g)
    tx_id=$(echo $data| cut -d ":" -f 1)
    v_out=$(echo $data| cut -d ":" -f 2)
    script_pubkey="$(echo $data| cut -d ":" -f 3)"
    redeem_script="$(echo $data| cut -d ":" -f 4)"
    amount="$(echo $data| cut -d ":" -f 5)"

    txid='\"txid\":''\"'${tx_id}'\"'
    vout=${sep}'\"vout\":'${v_out}
    scriptPubKey=${sep}'\"scriptPubKey\":''\"'${script_pubkey}'\"'
    if [ ! -z "${redeem_Script}"  ]; then
        redeemScript=${sep}'\"redeemScript\":''\"'${redeem_script}'\"'
    fi
    if [ ! -z "${amount}" ]; then
        amount=${sep}'\"amount\":'${amount}
    fi
    sign_param_in=${sign_param_in}${txid}${vout}${scriptPubKey}${redeemScript}${amount}
    sign_param_in=${sign_param_in}"}"
done
sign_param_in=${sign_param_in}"]"
#echo ${sign_param_in}

sign_param_key="["

for((i=0;i<${#utxo_list[@]};i++))
do
    if [ "$i" -gt 0 ]; then
        sign_param_key=${sign_param_key}","
    fi
    data="${utxo_list[$i]}"
    data=$(echo $data| sed -e s/^.*=//g)
    key=$(echo $data| cut -d ":" -f 6)
    key='\"'${key}'\"'
    sign_param_key=${sign_param_key}${key}
done
sign_param_key=${sign_param_key}"]"

#echo ${sign_param_key}
if [[ ${sign_param_key} = '[\"\"]' ]]; then
    sign_param_key=
fi

#fee=0.0001
#send_amount=`echo "${redeem_amount}-${fee}" | bc`
#echo ${send_amount}

sign_cmd="${C_SIGN} "${raw_tx}" \"${sign_param_in}\" \"${sign_param_key}\" | jq  -r '.hex'"
#echo $sign_cmd
raw_hex_tx=`eval ${sign_cmd}`
if [ -z "$raw_hex_tx" ] ; then
    echo " Could not sign tx with ${sign_cmd}!"
    exit 1
fi
echo $raw_hex_tx
bash cli.bash decoderawtransaction "${raw_hex_tx}" 
#bash cli.bash sendrawtransaction "${raw_hex_tx}" 


#OK
#https://chain.so/api/v2/tx/BTCTEST/545dd560ce4cbea0ffac9a30c26a7f4beef90a8f438377434651bfc4ddb5d210
#0200000001f858995b4dfc0ea79223453932f7bf99466929071fd60a0a1bd9ace2d9510db9000000006b483045022100d63f1876269af1331987536413267dd33678dd4a8a17fd30014d89c2d3fe5f3f02201c43c2463fb8528415646c7f09c248c15ba6c1fc0582adac454d9edb3b4e26e8012102d7c9e36a4d31039d4b94a43246a4a5f0767f2f55ef9a359901c82c41fb1e4bffffffffff01707dbf07000000001976a914ecebae831bbfbd7827542a82da4dc136e1288f7188ac00000000

