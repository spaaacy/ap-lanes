const functions = require("firebase-functions");
// const stripe = require("stripe")(functions.config().stripe.secrettestkey);
const stripe = require("stripe")('sk_test_51N9zUaJAKQdVND9kuvxIN41YLvEZGLqOno6AkPrbTsPXbqOqsQaHRMsZnBqMg5Tdoc23bufvvPFjgEA0MtRxuS87009DuaqGgi');

const calculatePrice = (distance) => {
	const baseCharge = 0.00;
	const kmCharge = 0.85;
	const finalCharge = baseCharge + (parseFloat(distance) * kmCharge);
	return parseInt(finalCharge * 100);
};

exports.StripeCreateCustomer = functions.region("asia-east2").https.onRequest(async (req, res) => {
	const { email, name, phone } = req.body;

	try {
		const params = {
			email: email,
			name: name,
			phone: phone,
		};
		const customer = await stripe.customers.create(params);
		return res.send({ id: customer.id });
	} catch (e) {
		return res.send({ error: e.message });
	}
});

exports.StripeGetEphemeralKey = functions.region("asia-east2").https.onRequest(async (req, res) => {
	const { customerId } = req.body;

	try {
		const ephemeralKey = await stripe.ephemeralKeys.create(
			{ customer: customerId },
			{ apiVersion: '2022-11-15' },
		)
		return res.send({ secret: ephemeralKey.secret });
	} catch (e) {
		res.send({ error: e.message });
	}

});



exports.StripeGetPaymentMethod = async () => {
	const paymentMethods = await stripe.customers.listPaymentMethods(
		'cus_NwnuOelpzQooZo',
		{type: 'card'},
	);
	console.log(paymentMethods);
};

exports.StripeGetPaymentMethod();

exports.StripeGetPaymentIntent = functions.region("asia-east2").https.onRequest(async (req, res) => {
	const { distance, currency, customerId } = req.body;

	const amount = calculatePrice(distance);

	try {
		const params = {	
			amount: amount,
			currency: currency,
			customer: customerId,
			automatic_payment_methods: {
				enabled: true,
			},
			setup_future_usage: 'off_session',
		};
		const intent = await stripe.paymentIntents.create(params);
		console.log("Intent ${intent}");
		return res.send({ client_secret: intent.client_secret });
	} catch (e) {
		return res.send({ error: e.message });
	}
});
