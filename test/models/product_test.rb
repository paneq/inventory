require 'test_helper'

class InventoryTest < ActiveSupport::TestCase

  class Inventory
    def register_product(identifier, initial_quantity)

    end

    def available_quantity(identifier)
      10
    end

  end

  test "can add product with initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
  end

  test "can get initial quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
    qty = inventory.available_quantity("WROCLOVE2014")
    assert_equal 10, qty
  end
end
