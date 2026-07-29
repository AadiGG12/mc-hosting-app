"""Razorpay payment service for creating orders and verifying payments."""

import hmac
import hashlib
import razorpay

from app.config import get_settings


class RazorpayService:
    """Handles Razorpay order creation, payment verification, and webhooks.

    Flow:
    1. User selects a plan in the app
    2. Backend creates a Razorpay order (create_order)
    3. Mobile app opens Razorpay checkout with order details
    4. User completes payment on Razorpay
    5. App sends payment details to backend for verification (verify_payment)
    6. On success, backend auto-creates Pterodactyl server
    """

    def __init__(self):
        settings = get_settings()
        self.key_id = settings.RAZORPAY_KEY_ID
        self.key_secret = settings.RAZORPAY_KEY_SECRET
        self.webhook_secret = settings.RAZORPAY_WEBHOOK_SECRET

        if self.key_id and self.key_secret:
            self.client = razorpay.Client(
                auth=(self.key_id, self.key_secret)
            )
        else:
            self.client = None

    def create_order(
        self,
        amount_paise: int,
        currency: str = "INR",
        receipt: str = "",
        notes: dict = None,
    ) -> dict:
        """Create a Razorpay order.

        Args:
            amount_paise: Amount in paise (₹1 = 100 paise). For example,
                         ₹149 = 14900 paise.
            currency: Currency code (INR, USD, etc.)
            receipt: Unique receipt ID (e.g., order ID from our DB)
            notes: Additional metadata

        Returns:
            Razorpay order object with 'id', 'amount', 'currency', etc.
        """
        if not self.client:
            raise ValueError("Razorpay client not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.")

        order_data = {
            "amount": amount_paise,
            "currency": currency,
            "receipt": receipt,
            "notes": notes or {},
        }
        return self.client.order.create(data=order_data)

    def verify_payment(
        self,
        razorpay_order_id: str,
        razorpay_payment_id: str,
        razorpay_signature: str,
    ) -> bool:
        """Verify a Razorpay payment signature.

        After the user completes payment, Razorpay returns:
        - razorpay_order_id
        - razorpay_payment_id
        - razorpay_signature

        We verify the signature using HMAC-SHA256 to ensure the payment
        was not tampered with.
        """
        if not self.key_secret:
            raise ValueError("Razorpay key secret not configured.")

        message = f"{razorpay_order_id}|{razorpay_payment_id}"
        expected_signature = hmac.new(
            self.key_secret.encode("utf-8"),
            message.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(expected_signature, razorpay_signature)

    def verify_webhook_signature(
        self, body: bytes, signature: str
    ) -> bool:
        """Verify a Razorpay webhook signature.

        Webhooks provide a backup verification mechanism. Razorpay
        signs the webhook body with the webhook secret.
        """
        if not self.webhook_secret:
            raise ValueError("Razorpay webhook secret not configured.")

        expected = hmac.new(
            self.webhook_secret.encode("utf-8"),
            body,
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(expected, signature)

    def fetch_payment(self, payment_id: str) -> dict:
        """Fetch payment details from Razorpay."""
        if not self.client:
            raise ValueError("Razorpay client not configured.")
        return self.client.payment.fetch(payment_id)

    def fetch_order(self, order_id: str) -> dict:
        """Fetch order details from Razorpay."""
        if not self.client:
            raise ValueError("Razorpay client not configured.")
        return self.client.order.fetch(order_id)


# Singleton instance
razorpay_service = RazorpayService()
