const BigNumber = require("@0x/utils").BigNumber;
const bodyParser = require("body-parser");
const express = require("express");
const orderHashUtils = require("@0x/order-utils").orderHashUtils;
const OrderWatcher = require("@0x/order-watcher").OrderWatcher;
const request = require("request");
const Web3 = require("web3");

// ganache doesn't have a websocket provider
// TODO: make this easier to toggle
const provider = new Web3.providers.HttpProvider(process.env.ETHEREUM_HTTP_PROVIDER);
//const provider = new Web3.providers.WebsocketProvider(process.env.ETHEREUM_WS_PROVIDER);

const orderWatcher = new OrderWatcher(provider, +process.env.ETHEREUM_NETWORK_ID);

// TODO: expirationWatcher.subscribe(...); should be very similar
orderWatcher.subscribe((error, orderState) => {
  console.log(orderState);
  if (orderState.isValid) {
    // TODO: why is this toString necessary?
    for (let k in orderState.orderRelevantState) {
      orderState.orderRelevantState[k] = orderState.orderRelevantState[k].toString();
    }
  } else {
    orderWatcher.removeOrder(orderState.orderHash);
  }

  // TODO: use websocket instead of http
  request.post(
    process.env.RELAYER_HTTP + orderState.orderHash,
    { json: true, body: orderState },
    (err, res, body) => {
      if (err) {
        return console.log(err);
      }
      console.log(body);
    }
  );
});

const app = express();
app.use(bodyParser.json());

app.post("/v2/order", (req, res) => {
  // TODO: receive websocket request instead of POST

  try {
    order = convertToBigNumber(req.body);

    // TODO: do something with this promise?
    orderWatcher.addOrderAsync(order);

    // TODO: addOrderAsync calls this, but doesn't return it or store it on the order object
    const orderHash = orderHashUtils.getOrderHashHex(order);

    // TODO: what should we return? just the order hash?
    res.status(201).send({"orderHash": orderHash});
    console.log("Watching order " + orderHash);
  } catch (e) {
    console.log("ERROR: " + e);
    // TODO: what status code? 400 or 500?
    res.status(400).send({"error": e.message});
  }
});

app.delete("/v2/order", (req, res) => {
  // TODO: receive websocket request instead of POST
  console.log("HTTP: DELETE order");
  const orderHash = req.body;

  try {
    orderWatcher.removeOrder(orderHash);
    expirationWatcher.removeOrder(orderHash);

    // TODO: what should we return?
    res.status(200).send({"orderHash": orderHash});
    console.log("Stopped watching order " + orderHash);
  } catch (e) {
    // TODO: what status code? 400 or 500?
    res.status(400).send({"error": e.message});
  }
});

app.listen(process.env.WATCHER_PORT, () => {
  console.log("Order watcher listening on port " + process.env.WATCHER_PORT);
  console.log("Ethereum HTTP Provider: " + process.env.ETHEREUM_HTTP_PROVIDER);
  console.log("Ethereum WS Provider: " + process.env.ETHEREUM_WS_PROVIDER);
  console.log("Relayer HTTP: " + process.env.RELAYER_HTTP);
  console.log("ETH Network Id: " + process.env.ETHEREUM_NETWORK_ID);
});

// https://github.com/0xProject/0x-monorepo/issues/92
const big_number_keys = [
  "salt",
  "makerFee",
  "takerFee",
  "makerTokenAmount",
  "takerTokenAmount",
  "expirationTimeSeconds"
];
function convertToBigNumber(order) {
  big_number_keys.forEach(function(k) {
    if (typeof order[k] != "undefined") order[k] = new BigNumber(order[k]);
  });

  return order;
}
