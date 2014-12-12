require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  class Inventory
    def register_product(identifier, available_quantity)
      Product.create!(name: identifier)
      @available_quantity = available_quantity
    end

    def available_quantity(identifier)
      @available_quantity
    end

    def reserve_product(identifier, qty)
      @available_quantity -= qty
    end
  end

  test "can add product with initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
  end

  test "can get initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 10, qty
  end

  test "can reserve some quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 5)
    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 5, qty
  end
end
