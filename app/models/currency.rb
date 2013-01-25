class Currency < ActiveRecord::Base
  attr_accessible :code, :name, :symbol
end
