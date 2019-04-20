const ether = 10 ** 18;

async function init() {
  if (typeof web3 === 'undefined') {
    show('no-web3-error');
    return;
  }
  const w3 = new Web3(web3.currentProvider);
  const accounts = await w3.eth.getAccounts();
  const account = accounts[0];
  text('account', account);
  const netId = await w3.eth.net.getId();
  if (netId != 323138) {
    text('network-id', netId);
    show('no-papyrus-network');
    return;
  }
  const balance = await w3.eth.getBalance(account);
  text('balance', balance);
  text('balance_eth', balance / ether);

  const contract = new w3.eth.Contract(abi, '0x0000000000000000000000000000000000000022');
  text('version', await contract.methods.version().call({ from: account }));
  text('stake', await contract.methods.stakes(account).call({ from: account }));

  const limit = await request('http://148.251.152.112:52545/', {
    jsonrpc: "2.0",
    method: "eth_getLimit",
    params: [account, "latest"],
    id: 1
  });
  text('limit', limit.result);
}

async function request(url, req) {
  return new Promise((resolve, revert) => {
    const xmlhttp = new XMLHttpRequest();
    xmlhttp.open('POST', url);
    xmlhttp.setRequestHeader("Content-Type", "application/json");
    xmlhttp.send(JSON.stringify(req));
    xmlhttp.onload = () => {
      if (xmlhttp.status !== 200) {
        revert(new Error(xmlhttp.statusText));
      } else {
        console.log(xmlhttp.responseText.trim());
        resolve(JSON.parse(xmlhttp.responseText));
      }
    };
    xmlhttp.onerror = function() {
      revert(new Error('Request failed'));
    };
  });
}

function show(id, flag) {
  document.getElementById(id).style.display =
    (flag === undefined || flag) ? 'inherit' : 'none';
}

function text(id, text) {
  document.getElementById(id).innerText = text;
}
