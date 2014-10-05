require 'rails_helper'

RSpec.describe "parents/edit", :type => :view do
  before(:each) do
    @parent = assign(:parent, Parent.create!(
      :first_name => "MyString",
      :last_name => "MyString",
      :email => "MyString",
      :family => nil
    ))
  end

  it "renders the edit parent form" do
    render

    assert_select "form[action=?][method=?]", parent_path(@parent), "post" do

      assert_select "input#parent_first_name[name=?]", "parent[first_name]"

      assert_select "input#parent_last_name[name=?]", "parent[last_name]"

      assert_select "input#parent_email[name=?]", "parent[email]"

      assert_select "input#parent_family_id[name=?]", "parent[family_id]"
    end
  end
end
