const Web3 = require("web3");
const short_abi = [
  {
    inputs: [
      {
        internalType: 'address',
        name: '_to',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: '_count',
        type: 'uint256',
      },
    ],
    name: 'mint',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
]
const fs = require('fs');

const infura_project_id = '';
const contract_address = '0x31F3bba9b71cB1D5e96cD62F0bA3958C034b55E9';
const owner_address = '0x006AF13373D86F0025Fa081283335b81cC394f9f';
const private_key_path = '';

let web3 = new Web3(new Web3.providers.HttpProvider(`https://mainnet.infura.io/v3/${infura_project_id}`))
const private_key = fs.readFileSync(private_key_path, 'utf8')
const contract_instance = new web3.eth.Contract(short_abi, contract_address);

const sleep = (ms) => { return new Promise((resolve) => { setTimeout(resolve, ms); }) }

async function airdrop (to_address, count, gas_price) {
    let estimate = await contract_instance.methods.mint(to_address, count).estimateGas({
        value: 0,
        from: owner_address
    });
    console.log(`Total Gas would be ${estimate} units`);

    const tx = {
      from: owner_address,
      to: contract_address,
      gas: parseInt(estimate),
      value: 0,
      gasPrice: gas_price,
      data: contract_instance.methods.mint(to_address, count).encodeABI()
    };

    const signedTx = await web3.eth.accounts.signTransaction(tx, private_key)

    const txn_receipt = await web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction).on("transactionHash", (function(txn_hash) {
     console.log(`Transaction hash for ${to_address} is ${txn_hash}`)
    })).on("error", err => {
      console.log("Airdrop failed with error: ", JSON.stringify(err))
    });
    return txn_receipt
}

async function airdrop_all(max_gas_gwei, multiplier, sleep_seconds) {
  // list of airdrops, can be read from a file
  let airdrops = [ { to_address: '', count: '10'} ];
  let index = 0;

  while (index < airdrops.length) {
    let gas = await web3.eth.getGasPrice();
    let gas_gwei = web3.utils.fromWei(gas, 'Gwei')
    console.log(`Gas price is ${gas_gwei} Gwei`);

    if (parseFloat(gas_gwei) * multiplier > max_gas_gwei){
      console.log(`Gas is too high, sleeping for ${sleep_seconds} seconds`);
      await sleep(sleep_seconds * 1000)
      continue;
    }

    let airdrop = airdrops[index]
    try {
      console.log(`Airdropping ${count} penguins to ${to_address} at gas price ${gas_gwei} Gwei`)
      let res = await airdrop(airdrop.to_address, airdrop.count, parseInt(multiplier * gas))
      console.log("receipt", res)
      if (res.status == true){
        fs.appendFileSync('airdrop_results.txt', `${airdrop.to_address}:${res.transactionHash}\n`)
        index+=1
      }
      else{
        console.log("Something went wrong, aborting")
        process.exit(1)
      }
    } catch (error) {
      fs.appendFileSync('airdrop_results.txt', `${airdrop.to_address}:${error}\n`)
      index+=1
    }
  }
}

airdrop_all(32.0, 1.10, 10)
