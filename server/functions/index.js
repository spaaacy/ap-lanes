const functions = require("firebase-functions");
const stripe = require("stripe")(functions.config().stripe.secrettestkey);

const calculatePrice = (distance) => {
	const baseCharge = 0.00;
	const kmCharge = 0.85;
	const finalCharge = baseCharge + (parseFloat(distance) * kmCharge);
	return parseInt(finalCharge * 100);
};

exports.StripeCreateCustomer = functions.region("asia-east2").https.onRequest(async (req, res) => {
    console.log(res.body);
    const email = res.body;
//
//    try {
//        stripe.customers.create({email: email});
//    } catch (e) {
//    return res.send({error: e.message});
//    }
});

exports.StripeGetPaymentIntent =
	functions.region("asia-east2").https.onRequest(async (req, res) => {
		const {distance, currency} = req.body;

		const amount = calculatePrice(distance);

		try {
			const params = {
				amount: amount,
				currency: currency,
			};
			const intent = await stripe.paymentIntents.create(params);
			console.log("Intent ${intent}");
			return res.send({client_secret: intent.client_secret});
		} catch (e) {
			return res.send({error: e.message});
		}
	});
