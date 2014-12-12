require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  class Inventory
    def register_product(name, available_quantity)
      Product.create!(name: name)
    end
  end

  test "can add product with initial available quantity" do
    inventory = Inventory.new
    inventory.register_product("wroc_love.rb 2014 ticket", 10)
    #inventory.available_quantity_for(
  end
end
