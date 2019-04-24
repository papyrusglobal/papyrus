Controller UI
=============

This is the front end of the tool that helps working with Bios contract in
Papyrus network.

Deploy it by putting these files to the public directory of a web server. For
example, you can simply start the web server:

    docker run -v $PWD:/usr/share/nginx/html:ro --rm -d -p 4000:80 nginx

Currently, this is deployed at http://head.papyrus.network:8000/controller/.


PPR tokens
----------

Test PPR tokens exist in 2 flavors:

1.  As Rinkeby network ERC20 contract. See it on etherscan:
    https://rinkeby.etherscan.io/token/0x706397BFBcb8acfc52aCb5de67a10291FcdBdbf1#balances.

2.  As testnet currency. See the testnet statistics page here:
    http://head.papyrus.network:3500/.


How to convert
--------------

1.  Open your Metamask and select an account that has some test PPR tokens of
    either first or second flavor.

2.  Switch your Metamask to use either Rinkeby network or Papyrus testnet
    (custom RPC http://148.251.152.112:52545) where you want to transfer your
    PPR tokens from.

3.  If you selected Papyrus network, you need to stake some funds first, if
    you didn't do it before, for the account you use. To stake, use this
    controller UI:

    1. Open or refresh the controller UI page
       (http://head.papyrus.network:8000/controller/). Make sure it shows your
       account.
    2. Use value (e.g. 1) and press 'stake' button. Confirm your action with
       Metamask pop-up.
    3. After several seconds, the Metamask will notify you that the
       transaction is complete. After that, refresh the controller page.
    4. Repeat steps 2-3 one more time (two times in total). This is a
       workaround and will be fixed soon.

3.  Browse to the bridge at http://head.papyrus.network:3000/. Confirm
    Metamask authentication pop-up.

4.  Specify the number of PPR tokens you want to transfer and press
    'transfer'. Confirm your choice in Metamask pop-up.
