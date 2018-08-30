const OrderWatcher = require('@0xproject/order-watcher').OrderWatcher;
const Web3 = require('web3');
const bodyParser = require('body-parser');
const express = require('express');
const BigNumber = require('@0xproject/utils').BigNumber;
const request = require('request');
require('dotenv').config();

const provider = new Web3.providers.HttpProvider(process.env.PROVIDER);
const orderWatcher = new OrderWatcher(provider, +process.env.NETWORK_ID);

orderWatcher.subscribe((error, orderState) => {
    console.log(orderState);
    if (orderState.isValid) {
        for (let k in orderState.orderRelevantState)
            orderState.orderRelevantState[k] = orderState.orderRelevantState[k].toString();
    } else {
        orderWatcher.removeOrder(orderState.orderHash);
    }
    request.post(
        process.env.RELAYER + orderState.orderHash,
        {json: true, body: orderState},
        (err, res, body) => {
            if (err) { return console.log(err); }
            console.log(body);
        });
});

const app = express();
app.use(bodyParser.json());

app.post('/v0/order', (req, res) => {
    console.log('HTTP: POST order');
    const order = req.body;


    try {
        orderWatcher.addOrder(convertToBigNumber(order));
        res.status(201).send({});
    } catch (e) {
        res.status(400).send(e.message)
    }

});

app.listen(process.env.PORT, () => console.log('Order watcher listening on port 3000!'));

const keys = [
    'salt',
    'makerFee',
    'takerFee',
    'makerTokenAmount',
    'takerTokenAmount',
    'expirationUnixTimestampSec',
];

function convertToBigNumber(order) {

    keys.forEach(function (k) {
        if (typeof order[k] != 'undefined')
            order[k] = new BigNumber(order[k]);
    });

    return order;
}
