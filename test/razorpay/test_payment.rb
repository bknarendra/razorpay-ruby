require 'test_helper'
require 'razorpay/payment'
require 'razorpay/collection'

module Razorpay
  # Tests for Razorpay::Payment
  class RazorpayPaymentTest < Minitest::Test
    def setup
      @payment_id = 'fake_payment_id'
      @card_id = 'card_6krZ6bcjoeqyV9'

      # Any request that ends with payments/payment_id
      stub_get(%r{payments\/#{Regexp.quote(@payment_id)}$}, 'fake_payment')
      stub_get(/payments$/, 'payment_collection')
    end

    def test_payment_should_be_defined
      refute_nil Razorpay::Payment
    end

    def test_payments_should_be_available
      payment = Razorpay::Payment.fetch(@payment_id)
      assert_instance_of Razorpay::Payment, payment, 'Payment not an instance of Payment class'
      assert_equal @payment_id, payment.id, 'Payment IDs do not match'
      assert_equal 500, payment.amount, 'Payment amount is accessible'
      assert_equal 'card', payment.method, 'Payment method is accessible'
    end

    def test_all_payments
      payments = Razorpay::Payment.all
      assert_instance_of Razorpay::Collection, payments, 'Payments should be an array'
      assert !payments.items.empty?, 'Payments should be more than one'
    end

    def test_all_payments_with_options
      query = { 'count' => 1 }
      stub_get(/payments\?count=1$/, 'payment_collection_with_one_payment')
      payments = Razorpay::Payment.all(query)
      assert_equal query['count'], payments.items.size, 'Payments array size should match'
    end

    def test_payment_refund
      stub_post(%r{payments/#{@payment_id}/refund$}, 'fake_refund', {})
      refund = Razorpay::Payment.fetch(@payment_id).refund
      assert_instance_of Razorpay::Refund, refund
      assert_equal refund.payment_id, @payment_id
    end

    def test_payment_card
      stub_post(%r{cards/#{@card_id}$}, 'fake_card', {})
      card = Razorpay::Payment.fetch(@payment_id).card
      assert_instance_of Razorpay::Card, card
      assert_equal card.id, @card_id
    end

    def test_partial_refund
      # For some reason, stub doesn't work if I pass it a hash of post body
      stub_post(%r{payments/#{@payment_id}/refund$}, 'fake_refund', 'amount=2000')
      refund = Razorpay::Payment.fetch(@payment_id).refund(amount: 2000)
      assert_instance_of Razorpay::Refund, refund
      assert_equal refund.payment_id, @payment_id
      assert_equal refund.amount, 2000
    end

    def test_payment_capture
      stub_post(%r{payments/#{@payment_id}/capture$}, 'fake_captured_payment', 'amount=5100')
      payment = Razorpay::Payment.fetch(@payment_id)
      payment = payment.capture(amount: 5100)
      assert_equal 'captured', payment.status
    end
  end
end
