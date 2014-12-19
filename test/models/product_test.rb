require 'test_helper'

class InventoryTest < ActiveSupport::TestCase

  class Inventory
    def register_product(identifier, initial_quantity)
      @available_quantity = initial_quantity
      @reserved_quantity  = 0
    end

    def available_quantity(identifier)
      @available_quantity
    end

    def reserved_quantity(identifier)
      @reserved_quantity
    end

    def reserve_product(identifier, qty)
      @reserved_quantity  += qty
      @available_quantity -= qty
    end
  end

  test "can add product with initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
  end

  test "can get initial state" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)

    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 10, qty

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 0, qty
  end

  test "can reserver some quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 5)

    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 5, qty

    qty = inventory.reserved_quantity("WROCLOVE2014")
    assert_equal 5, qty
  end
end
