require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  class Inventory

  end

  test "can add product" do
    inventory = Inventory.new
    inventory.register_product("wroc_love.rb 2014 ticket")
  end
end
