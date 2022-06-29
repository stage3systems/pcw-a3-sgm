require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @office = offices(:one)
    @user = users(:operator)
    @office_user = users(:office_operator)
  end

  test "users are constrained to their offices ports" do
    assert @user.authorized_ports.count == Port.count
    assert @office_user.authorized_ports.count < Port.count
    assert @office_user.authorized_ports == @office.ports
  end

  test "full name" do
    assert @user.full_name == "#{@user.first_name} #{@user.last_name}"
  end

  test "admin types" do
    ['MANAGER/USER',
     'SYSTEM ADMINISTRATOR',
     'NAVARIK HIDDEN SUPERUSER'].each do |t|
       assert @user.is_admin_type(t)
    end
    assert !@user.is_admin_type('USER')
  end
end
