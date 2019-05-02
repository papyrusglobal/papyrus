const biosAddress = '0x0000000000000000000000000000000000000022';
// const gatewayUrl = 'http://148.251.152.112:18545/';  // head.papyrus.network:localtest
// const biosAddress = '0x142ac51e2b05a107c1482f4832b73c5bc55b6fd5'; // @rinkeby
// const gatewayUrl = 'http://148.251.152.112:52545/';  // head.papyrus.network:testnet
const ether = 10 ** 18;
let contract;
let account;
let web3;

async function init() {
  if (typeof window.web3 === 'undefined') {
    show('no-web3-error');
    return;
  }
  // web3 = new Web3(new Web3.providers.HttpProvider(gatewayUrl));
  web3 = new Web3(window.web3.currentProvider);
  const accounts = await web3.eth.getAccounts();
  account = accounts[0];
  text('account', account);
  const netId = await web3.eth.net.getId();
  if (netId != 323138) {
    text('network-id', netId);
    show('no-papyrus-network');
    return;
  }
  const balance = await web3.eth.getBalance(account);
  text('balance', balance);
  text('balance_eth', balance / ether);

  contract = new web3.eth.Contract(abi, biosAddress);
  text('version', await contract.methods.version().call({ from: account }));
  text('address', biosAddress);
  text('all-stakes', await web3.eth.getBalance(biosAddress));
  text('stake', await contract.methods.stakes(account).call({ from: account }));

  const limit = await getLimit();
  text('limit', limit.result);
}

async function onStake() {
  const value = document.getElementById('value').value;
  return process(contract.methods.freeze().send({ from: account, gas: 0, value }));
}

async function onUnstake() {
  const value = document.getElementById('value').value;
  return process(contract.methods.melt(value).send({ from: account, gas: 0 }));
}

async function onWithdraw() {
  return process(contract.methods.withdraw().send({ from: account, gas: 100000 }));
}

async function process(transaction) {
  return transaction
    .on('receipt', receipt => {
      show('tx-info', false);
      console.log('Mined: ', receipt.blockNumber);
      location.reload();
    })
    .on('confirmation', (confirmationNo, receipt) => {
      console.log('Confirmation', confirmationNo);
    })
    .on('transactionHash', hash => {
      console.log('Tx hash:', hash);
      text('tx-id', hash);
      show('tx-info');
    })
    .catch(err => console.log('Error:', err.message));
}

async function getLimit() {
  // TODO: use send() instead, but Metamask 6.4.1 is buggy here.
  // https://github.com/MetaMask/metamask-docs/blob/master/03_API_Reference/01_Ethereum_Provider.md#ethereumsendoptions
  return new Promise((resolve, reject) => {
    window.web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "eth_getLimit",
      params: [account, "latest"],
      from: account,
      id: 1
    }, (err, res) => {
      if (err) reject(err);
      resolve(res);
    });
  });
}

// Obsolete - now use Metamask send(). But want to keep this code for a while.
//
// async function request(url, req) {
//   return new Promise((resolve, revert) => {
//     const xmlhttp = new XMLHttpRequest();
//     xmlhttp.open('POST', url);
//     xmlhttp.setRequestHeader("Content-Type", "application/json");
//     xmlhttp.send(JSON.stringify(req));
//     xmlhttp.onload = () => {
//       if (xmlhttp.status !== 200) {
//         revert(new Error(xmlhttp.statusText));
//       } else {
//         resolve(JSON.parse(xmlhttp.responseText));
//       }
//     };
//     xmlhttp.onerror = function() {
//       revert(new Error('Request failed'));
//     };
//   });
// }

function show(id, flag) {
  document.getElementById(id).style.display =
    (flag === undefined || flag) ? 'inherit' : 'none';
}

function text(id, text) {
  document.getElementById(id).innerText = text;
}
