require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  class Inventory
    def register_product(identifier, available_quantity)
      #Product.create!(name: identifier)
      @available_quantity = available_quantity
      @reserved_quantity  = 0
      @sold_quantity = 0
    end

    def available_quantity(identifier)
      @available_quantity - @reserved_quantity - @sold_quantity
    end

    def change_quantity(identifier, qty)
      raise StandardError, "quantity too low" if qty - @reserved_quantity - @sold_quantity < 0
      @available_quantity = qty
    end

    def reserved_quantity(identifier)
      @reserved_quantity
    end

    def sold_quantity(identifier)
      @sold_quantity
    end

    def reserve_product(identifier, qty)
      raise StandardError, "quantity too big" if available_quantity(identifier) - qty < 0
      @reserved_quantity  += qty
    end

    def sell_product(identifier, qty)
      raise StandardError, "quantity too big" if reserved_quantity(identifier) - qty < 0
      @reserved_quantity -= qty
      @sold_quantity     += qty
    end

    def expire_product(identifier, qty)
      raise StandardError, "quantity too big" if qty > reserved_quantity(identifier)
      @reserved_quantity -= qty
    end

    def refund_product(identifier, qty)
      @sold_quantity -= qty
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
    assert_raise(StandardError) do
      inventory.change_quantity("WROCLOVE2014", 4)
    end
  end

  test "can't reserve if not enough product" do
    inventory.register_product("WROCLOVE2014", 9)

    assert_raise(StandardError) do
      inventory.reserve_product("WROCLOVE2014", 10)
    end

    inventory.reserve_product("WROCLOVE2014", 5)
    assert_raise(StandardError) do
      inventory.reserve_product("WROCLOVE2014", 5)
    end
  end

  test "can't sell if not enough product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    assert_raise(StandardError) do
      inventory.sell_product("WROCLOVE2014", 5)
    end

    inventory.sell_product("WROCLOVE2014", 2)
    assert_raise(StandardError) do
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
    assert_raise(StandardError) do
      inventory.expire_product("WROCLOVE2014", 4)
    end

    inventory.expire_product("WROCLOVE2014", 1)
    assert_raise(StandardError) do
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

  test "can't refund more qty than sold"

  test "multi product setup"
  test "can't expire more qty than reserved for that order"
  test "can't refund more qty than sold for that order"

  private

  def inventory
    @inventory ||= Inventory.new
  end
end
