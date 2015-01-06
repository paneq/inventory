require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  class Inventory

    Error          = Class.new(StandardError)
    QuantityTooBig = Class.new(Error)
    QuantityTooLow = Class.new(Error)


    def initialize
      @storage = Storage.new
    end

    def register_product(identifier, store_quantity)
      @storage.register_product(identifier, store_quantity)
    end

    def available_quantity(identifier)
      product(identifier).available_quantity
    end

    def change_quantity(identifier, qty)
      product(identifier).change_quantity(qty)
      @storage.change_quantity(identifier, qty)
    end

    def reserved_quantity(identifier)
      product(identifier).reserved_quantity
    end

    def sold_quantity(identifier)
      product(identifier).sold_quantity
    end

    def reserve_product(identifier, qty)
      product(identifier).reserve(qty)
      @storage.reserve_product(identifier, qty)
    end

    def sell_product(identifier, qty)
      product(identifier).sell(qty)
      @storage.sell_product(identifier, qty)
    end

    def expire_product(identifier, qty)
      product(identifier).expire(qty)
      @storage.expire_product(identifier, qty)
    end

    def refund_product(identifier, qty)
      product(identifier).refund(qty)
      @storage.refund_product(identifier, qty)
    end

    private

    def product(identifier)
      @storage.get_product(identifier)
    end

    def store_quantity(identifier)
      @storage.store_quantity(identifier)
    end


    class Product
      attr_reader :available_quantity,
                  :not_available_quantity,
                  :reserved_quantity,
                  :sold_quantity

      def initialize(available_quantity:     available_quantity,
                     not_available_quantity: not_available_quantity,
                     reserved_quantity:      reserved_quantity,
                     sold_quantity:          sold_quantity
      )
        @available_quantity     = available_quantity
        @not_available_quantity = not_available_quantity
        @reserved_quantity      = reserved_quantity
        @sold_quantity          = sold_quantity
      end

      def change_quantity(qty)
        raise QuantityTooLow if qty  < @not_available_quantity
      end

      def reserve(qty)
        raise QuantityTooBig if qty > @available_quantity
      end

      def sell(qty)
        raise QuantityTooBig if qty > @reserved_quantity
      end

      def expire(qty)
        raise QuantityTooBig if qty > @reserved_quantity
      end

      def refund(qty)
        raise QuantityTooBig if qty > @sold_quantity
      end
    end

    class Storage
      def initialize
        @store_quantity     = Hash.new{|hash, key| hash[key] = [] }
        @reserved_quantity  = Hash.new{|hash, key| hash[key] = [] }
        @sold_quantity      = Hash.new{|hash, key| hash[key] = [] }
      end

      def get_product(identifier)
        Product.new(available_quantity:     available_quantity(identifier),
                    not_available_quantity: not_available_quantity(identifier),
                    reserved_quantity:      reserved_quantity(identifier),
                    sold_quantity:          sold_quantity(identifier))
      end

      def register_product(identifier, store_quantity)
        @store_quantity[identifier] << store_quantity
      end

      def available_quantity(identifier)
        store_quantity(identifier) - reserved_quantity(identifier) - sold_quantity(identifier)
      end

      def change_quantity(identifier, qty)
        @store_quantity[identifier] << -store_quantity(identifier)
        @store_quantity[identifier] << qty
      end

      def reserved_quantity(identifier)
        @reserved_quantity[identifier].sum
      end

      def sold_quantity(identifier)
        @sold_quantity[identifier].sum
      end

      def reserve_product(identifier, qty)
        @reserved_quantity[identifier]  << qty
      end

      def sell_product(identifier, qty)
        @reserved_quantity[identifier] << -qty
        @sold_quantity[identifier]     << qty
      end

      def expire_product(identifier, qty)
        @reserved_quantity[identifier] << -qty
      end

      def refund_product(identifier, qty)
        @sold_quantity[identifier] << -qty
      end

      def store_quantity(identifier)
        @store_quantity[identifier].sum
      end

      def not_available_quantity(identifier)
        reserved_quantity(identifier) + sold_quantity(identifier)
      end
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

  test "history of state" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.change_quantity("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    inventory.reserve_product("WROCLOVE2014", 4)
    inventory.expire_product("WROCLOVE2014", 4)
    inventory.sell_product("WROCLOVE2014", 4)
    inventory.refund_product("WROCLOVE2014", 4)

    history = inventory.product_history("WROCLOVE2014")
    assert_equal [9, 10, 6, 2, 6, 6, 10], history.available_quantity
    assert_equal [0, 0, 4, 8, 4, 0, 0],   history.reserved_quantity
    assert_equal [0, 0, 0, 0, 0, 4, 0],   history.sold_quantity
  end

  test "history of changes" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.change_quantity("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    inventory.reserve_product("WROCLOVE2014", 4)
    inventory.expire_product("WROCLOVE2014", 4)
    inventory.sell_product("WROCLOVE2014", 4)
    inventory.refund_product("WROCLOVE2014", 4)

    changes = inventory.product_changes("WROCLOVE2014")
    assert_equal [+9, +1, -4, -4, +4, 0, +4], changes.available_quantity
    assert_equal [0, 0, +4, +4, -4, -4, 0],   changes.reserved_quantity
    assert_equal [0, 0, 0, 0, 0, +4, -4],     changes.sold_quantity
  end

  # Per order rules... - out of scope for now
  # test "can't expire more qty than reserved for that order"
  # test "can't refund more qty than sold for that order"

  private

  def inventory
    @inventory ||= Inventory.new
  end
end
