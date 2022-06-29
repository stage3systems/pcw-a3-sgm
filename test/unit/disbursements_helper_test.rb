require 'test_helper'

class DisbursementsHelperTest < ActiveSupport::TestCase
  include DisbursementsHelper
  include ActionView::Helpers::TagHelper

  test "simple string returns as is" do
    assert_equal format_list("test"), "test"
  end

  test "simple list" do
    assert_equal format_list(["foo","bar"]), "foo<br />bar<br />"
  end

  test "empty list" do
    assert_equal format_list([]), ""
  end

  test "standard styles" do
    assert_equal format_list([{style: :bold, value: "foo"},
                              {style: :small, value: "bar"},
                              {style: :unknown, value: "baz"}]),
                 "<strong>foo</strong><br /><small>bar</small><br />baz<br />"
  end

  test "custom styles" do
    assert_equal format_list([{style: :bold, value: "foo"},
                              {style: :small, value: "bar"},
                              {style: :unknown, value: "baz"}],
                             method(:custom_bold),
                             method(:custom_small),
                             "\n"),
                 "<b>foo</b>\n<s>bar</s>\nbaz\n"
  end

  def custom_bold(v)
    "<b>#{v}</b>"
  end

  def custom_small(v)
    "<s>#{v}</s>"
  end
end
