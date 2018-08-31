### 0x order watcher wrapper

This docker image wraps 0x order watcher in to restfull node-express application.

#### available methods:

##### POST /v0/order
accepts 0x SignedOrder and starts watching on it changes
###### request
```json
  {
        "orderHash": "0x6305677c90f2eaf60b59a4972ed7832140febd931ca9553d740f90daa86f7c2d",
        "exchangeContractAddress": "0x90fe2af704b34e0224bf2299c838e04d4dcf1364",
        "maker": "0xf6bfb48e186e76ec990a768f4a12d7a94b1cd5b5",
        "taker": "0x0000000000000000000000000000000000000000",
        "makerTokenAddress": "0xd0a1e359811322d97991e03f863a0c30c2cf029c",
        "takerTokenAddress": "0xef7fff64389b814a946f3e92105513705ca6b990",
        "feeRecipient": "0x0000000000000000000000000000000000000000",
        "makerTokenAmount": "10000000000000000",
        "takerTokenAmount": "10000000000000000000",
        "makerFee": "0",
        "takerFee": "0",
        "expirationUnixTimestampSec": "1535625538623",
        "salt": "16482987813238601051734308720818620435802096968858370904360954730803248359111",
        "ecSignature": {
            "v": 27,
            "r": "0xf89c5af7c559bbf0bee5b3ba242124602d5972433f8affe4508b51a676910a38",
            "s": "0x76652e611caf2e97182e0664297a76828d12a750911f676f745202c7d3322d48"
        }
    }
```
###### response
```json{}```

if something in order changed application informs about changes with post request to RELAYER url (this can be set through env config)
##### POST RELAYER/{orderHash}
###### request on valid order
```json
{
  "isValid":true,
  "orderHash":"0xf741dab0012f17117453bc8f240233a653f82277bb80f1002c81f430ec7e8fa2",
  "orderRelevantState":{
    "makerBalance":"1100300000000000000",
    "makerProxyAllowance":"115792089237316195423570985008687907853269984665640564039457584007913129639935",
    "makerFeeBalance":"29970000000000000000",
    "makerFeeProxyAllowance":"115792089237316195423570985008687907853269984665640564039457584007913129639935",
    "filledTakerTokenAmount":"1000000000000000000",
    "cancelledTakerTokenAmount":"0",
    "remainingFillableMakerTokenAmount":"9000000000000000",
    "remainingFillableTakerTokenAmount":"9000000000000000000"
    }
}
```

###### request on invalid order
```json
{
  "isValid":false,
  "orderHash":"0xf741dab0012f17117453bc8f240233a653f82277bb80f1002c81f430ec7e8fa2",
  "error":"ORDER_REMAINING_FILL_AMOUNT_ZERO"(or some other errors, see 0xproject.com for details)
}
```

if order becomes invalid application stop watching on it. To start watching again post SignedOrder to /v0/order

docker-compose quick start: 

    0x-order-watcher:
      image: alekserok/0x-order-watcher
      container_name: yourservice-0x-order-watcher
      environment:
        - PORT=3001
        - PROVIDER=http://some-parity-node:8545
        - NETWORK_ID=42
        - RELAYER=http://webserver/api/0x/v0/order/
      ports:
        - "3001:3001"
