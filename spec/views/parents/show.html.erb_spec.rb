require 'rails_helper'

RSpec.describe "parents/show", :type => :view do
  before(:each) do
    @parent = assign(:parent, Parent.create!(
      :first_name => "First Name",
      :last_name => "Last Name",
      :email => "Email",
      :family => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(//)
  end
end
