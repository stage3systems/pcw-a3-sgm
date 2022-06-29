class AddSbtToVessels < ActiveRecord::Migration
    def change
      add_column :vessels, :sbt_certified, :boolean
    end
  end
  