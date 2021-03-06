require 'rails_helper'

RSpec.describe "walkathon/payments/new", :type => :view do
  before(:each) do
    assign(:walkathon_payment, Walkathon::Payment.new(
      :description => "MyString",
      :amount => "9.99",
      :walkathon_pledge => nil
    ))
  end

  it "renders new walkathon_payment form" do
    render

    assert_select "form[action=?][method=?]", walkathon_payments_path, "post" do

      assert_select "input#walkathon_payment_description[name=?]", "walkathon_payment[description]"

      assert_select "input#walkathon_payment_amount[name=?]", "walkathon_payment[amount]"

      assert_select "input#walkathon_payment_walkathon_pledge_id[name=?]", "walkathon_payment[walkathon_pledge_id]"
    end
  end
end
