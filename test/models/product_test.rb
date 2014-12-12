require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  class Inventory
    def register_product(identifier, available_quantity)
      Product.create!(name: identifier)
    end
  end

  test "can add product with initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("WROCLOVE2014", 10)
    #inventory.available_quantity_for(
  end
end
