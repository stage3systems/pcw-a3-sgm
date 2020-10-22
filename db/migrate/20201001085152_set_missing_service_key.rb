class SetMissingServiceKey < ActiveRecord::Migration
  def change
    Service.where(key:  [nil, '']).each do |s|
      s.key = s.item.gsub('-','').split(' ').map { |x| x[0]  }.join.upcase if s.item
      s.save!
    end
  end
end
