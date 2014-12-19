require 'test_helper'

class InventoryTest < ActiveSupport::TestCase

  class Inventory
    def register_product(identifier, initial_quantity)

    end

  end

  test "can add product with initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
  end
end
