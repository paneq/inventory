require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  class Inventory

    Error          = Class.new(StandardError)
    QuantityTooBig = Class.new(Error)
    QuantityTooLow = Class.new(Error)

    class Sale
      attr_reader :product_identifier, :sold_quantity

      def initialize(product_identifier, sold_quantity)
        @product_identifier = product_identifier
        @sold_quantity      = sold_quantity
      end

      def reserved_quantity
        -@sold_quantity
      end
    end

    class Refund
      attr_reader :product_identifier, :refunded_quantity

      def initialize(product_identifier, refunded_quantity)
        @product_identifier = product_identifier
        @refunded_quantity  = refunded_quantity
      end

      def sold_quantity
        -@refunded_quantity
      end

      def reserved_quantity
        0
      end
    end

    class Reservation
      attr_reader :product_identifier, :reserved_quantity

      def initialize(product_identifier, reserved_quantity)
        @product_identifier = product_identifier
        @reserved_quantity  = reserved_quantity
      end

      def available_quantity
        -@reserved_quantity
      end

      def sold_quantity
        0
      end
    end

    class Expiration
      attr_reader :product_identifier

      def initialize(product_identifier, expired_quantity)
        @product_identifier = product_identifier
        @expired_quantity   = expired_quantity
      end

      def available_quantity
        @expired_quantity
      end

      def reserved_quantity
        -@expired_quantity
      end

      def sold_quantity
        0
      end
    end

    def initialize
      @store_quantity     = Hash.new{|hash, key| hash[key] = [] }
      @reserved_quantity  = Hash.new{|hash, key| hash[key] = [] }
      @sold_quantity      = Hash.new{|hash, key| hash[key] = [] }
      @history            = Hash.new{|hash, key| hash[key] = [] }
    end

    def register_product(identifier, store_quantity)
      @store_quantity[identifier] << store_quantity
    end

    def available_quantity(identifier)
      store_quantity(identifier) - reserved_quantity(identifier) - sold_quantity(identifier)
    end

    def change_quantity(identifier, qty)
      raise QuantityTooLow if qty  < not_available_quantity(identifier)
      @store_quantity[identifier] << -store_quantity(identifier)
      @store_quantity[identifier] << qty
    end

    def reserved_quantity(identifier)
      @history[identifier].map(&:reserved_quantity).sum
    end

    def sold_quantity(identifier)
      @history[identifier].map(&:sold_quantity).sum
    end

    def reserve_product(identifier, qty)
      raise QuantityTooBig if qty > available_quantity(identifier)
      @history[identifier] << Reservation.new(identifier, qty)
    end

    def sell_product(identifier, qty)
      raise QuantityTooBig if qty > reserved_quantity(identifier)
      @history[identifier] << Sale.new(identifier, qty)
    end

    def expire_product(identifier, qty)
      raise QuantityTooBig if qty > reserved_quantity(identifier)
      @history[identifier] << Expiration.new(identifier, qty)
    end

    def refund_product(identifier, qty)
      raise QuantityTooBig if qty > sold_quantity(identifier)
      @history[identifier] << Refund.new(identifier, qty)
    end

    private

    def store_quantity(identifier)
      @store_quantity[identifier].sum
    end

    def not_available_quantity(identifier)
      reserved_quantity(identifier) + sold_quantity(identifier)
    end
  end

  test "can add product with initial available quantity" do
    inventory.register_product("WROCLOVE2014", 10)
  end

  test "can get initial state" do
    inventory.register_product("WROCLOVE2014", 10)
    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 10, qty

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 0, qty

    qty = inventory.sold_quantity("WROCLOVE2014")
    assert_equal 0, qty
  end

  test "can reserve some quantity" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 5)

    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 5, qty

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 5, qty
  end

  test "can sell some reserved qty" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 5)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 0, qty

    qty = inventory.sold_quantity("WROCLOVE2014")
    assert_equal 5, qty
  end

  test "can change inventory qty" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 4)
    inventory.change_quantity("WROCLOVE2014", 8)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 1, qty

    qty = inventory.sold_quantity("WROCLOVE2014")
    assert_equal 4, qty

    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 3, qty
  end

  test "can't change inventory qty to lower value than sold and reserved" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 4)
    inventory.change_quantity("WROCLOVE2014", 5)
    assert_raise(Inventory::QuantityTooLow) do
      inventory.change_quantity("WROCLOVE2014", 4)
    end
  end

  test "can't reserve if not enough product" do
    inventory.register_product("WROCLOVE2014", 9)

    assert_raise(Inventory::QuantityTooBig) do
      inventory.reserve_product("WROCLOVE2014", 10)
    end

    inventory.reserve_product("WROCLOVE2014", 5)
    assert_raise(Inventory::QuantityTooBig) do
      inventory.reserve_product("WROCLOVE2014", 5)
    end
  end

  test "can't sell if not enough product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    assert_raise(Inventory::QuantityTooBig) do
      inventory.sell_product("WROCLOVE2014", 5)
    end

    inventory.sell_product("WROCLOVE2014", 2)
    assert_raise(Inventory::QuantityTooBig) do
      inventory.sell_product("WROCLOVE2014", 3)
    end
  end

  test "can expire reserved product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    inventory.expire_product("WROCLOVE2014", 4)
    inventory.reserve_product("WROCLOVE2014", 10)
  end

  test "can't expire more qty than reserved" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 3)
    assert_raise(Inventory::QuantityTooBig) do
      inventory.expire_product("WROCLOVE2014", 4)
    end

    inventory.expire_product("WROCLOVE2014", 1)
    assert_raise(Inventory::QuantityTooBig) do
      inventory.expire_product("WROCLOVE2014", 3)
    end
  end

  test "can refund sold product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 7)
    inventory.sell_product("WROCLOVE2014", 6)
    inventory.refund_product("WROCLOVE2014", 5)

    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 8, qty

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 1, qty

    qty = inventory.sold_quantity("WROCLOVE2014")
    assert_equal 1, qty
  end

  test "can't refund more qty than sold" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 7)
    inventory.sell_product("WROCLOVE2014", 6)

    assert_raise(Inventory::QuantityTooBig) do
      inventory.refund_product("WROCLOVE2014", 7)
    end

    inventory.refund_product("WROCLOVE2014", 5)
    assert_raise(Inventory::QuantityTooBig) do
      inventory.refund_product("WROCLOVE2014", 2)
    end
  end

  test "can refund equal qty that sold" do
    inventory.register_product("WROCLOVE2014", 5)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 5)
    inventory.refund_product("WROCLOVE2014", 5)
  end

  test "multi product setup" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.change_quantity("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 8)
    inventory.sell_product("WROCLOVE2014", 6)
    inventory.refund_product("WROCLOVE2014", 4)
    inventory.expire_product("WROCLOVE2014", 1)

    inventory.register_product("DRUGCAMP2015", 90)
    inventory.change_quantity("DRUGCAMP2015", 100)
    inventory.reserve_product("DRUGCAMP2015", 80)
    inventory.sell_product("DRUGCAMP2015", 60)
    inventory.refund_product("DRUGCAMP2015", 40)
    inventory.expire_product("DRUGCAMP2015", 10)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 1, qty
    qty = inventory.sold_quantity("WROCLOVE2014")
    assert_equal 2, qty
    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 7, qty

    qty = inventory.reserved_quantity("DRUGCAMP2015")
    assert_equal 10, qty
    qty = inventory.sold_quantity("DRUGCAMP2015")
    assert_equal 20, qty
    qty = inventory.available_quantity("DRUGCAMP2015")
    assert_equal 70, qty
  end

  # Per order rules... - out of scope for now
  # test "can't expire more qty than reserved for that order"
  # test "can't refund more qty than sold for that order"

  private

  def inventory
    @inventory ||= Inventory.new
  end
end
