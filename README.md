# 0x order watcher wrapper

This docker image wraps 0x order watcher in a RESTful node-express application.

## Available methods

### POST /v2/order

Watch a 0x V2 signed order for changes. When a change happens, the application will POST to a relayer.

#### POST /v2/order Request

```json
{
  "exchangeAddress": "0x4f833a24e1f95d70f028921e27040ca56e09ab0b",
  "senderAddress": "0x0000000000000000000000000000000000000000",
  "makerAddress": "0xe29d87c2d22017f61bfae5277cdac660a02e5341",
  "takerAddress": "0x0000000000000000000000000000000000000000",
  "makerAssetData": "0xf47261b000000000000000000000000089d24a6b4ccb1b6faa2625fe562bdd9a23260359",
  "takerAssetData": "0xf47261b0000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
  "feeRecipientAddress": "0xa258b39954cef5cb142fd567a46cddb31a670124",
  "makerAssetAmount": "400919999999999999852",
  "takerAssetAmount": "1893107157741269877",
  "makerFee": "0",
  "takerFee": "0",
  "expirationTimeSeconds": "1541699985",
  "signature": "0x1c0887b364395ca2e8e54f9b96188dbd7b79739ca8ca767b91303826d72d3d5b205187b7ac50117eb9bf9ad7e1ab2be3fa59bab3daa9b79ec9ca26e2508e78ffeb03",
  "salt": "1541699685553"
}
```

#### POST /v2/order Response

HTTP 201

```json
{
  "orderHash": "0x90192732bcf8b5b7e280d0c369cf0d034c7b9e3d31668e631e3ca344070680ef"
}
```

### DELETE /v2/order

Stop watching a 0x V2 order.

#### DELETE /v2/order Request

```json
{
  "orderHash": "0x90192732bcf8b5b7e280d0c369cf0d034c7b9e3d31668e631e3ca344070680ef"
}
```

#### DELETE /v2/order Response

HTTP 200

```json
{}
```

### POST RELAYER/{orderHash}

If an order changes, the application notifies the RELAYER of the update.

If order becomes invalid, the application stops watching the order.

#### request on valid order

```json
{
  "isValid": true,
  "orderHash": "0xf741dab0012f17117453bc8f240233a653f82277bb80f1002c81f430ec7e8fa2",
  "orderRelevantState": {
    "makerBalance": "1100300000000000000",
    "makerProxyAllowance": "115792089237316195423570985008687907853269984665640564039457584007913129639935",
    "makerFeeBalance": "29970000000000000000",
    "makerFeeProxyAllowance": "115792089237316195423570985008687907853269984665640564039457584007913129639935",
    "filledTakerTokenAmount": "1000000000000000000",
    "cancelledTakerTokenAmount": "0",
    "remainingFillableMakerTokenAmount": "9000000000000000",
    "remainingFillableTakerTokenAmount": "9000000000000000000"
  }
}
```

#### request on invalid order

```json
{
  "isValid": false,
  "orderHash": "0xf741dab0012f17117453bc8f240233a653f82277bb80f1002c81f430ec7e8fa2",
  "error": "ORDER_REMAINING_FILL_AMOUNT_ZERO"
}
```

#### docker-compose quick start

```yaml
  0x-order-watcher:
    image: bwstitt/0x-order-watcher
    environment:
      - WATCHER_PORT=3001
      - ETHEREUM_HTTP_PROVIDER=http://some-parity-node:8545
      - ETHEREUM_WS_PROVIDER=ws://some-parity-node:8546
      - ETHEREUM_NETWORK_ID=42
      - RELAYER_HTTP=http://webserver/api/0x/v0/order/
    ports:
      - "3001:3001"
```

#### TODO

* Make sure the fields that we POST to the relayer match what is documented in this README
* Make POST /v2/order return the orderHash in the response
* [Endpoint for stats](https://github.com/0xProject/0x-monorepo/pull/1118)
* Websockets instead of HTTP for Ethereum provider
* Websockets instead of HTTP for Relayer POSTs
