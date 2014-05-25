require 'spec_helper'
require 'flapjack/gateways/jsonapi'

describe 'Flapjack::Gateways::JSONAPI::MediumMethods', :sinatra => true, :logger => true do

  include_context "jsonapi"

  let(:medium) { double(Flapjack::Data::Medium, :id => "ab12") }

  let(:medium_data) {
    {:type => 'email',
     :address => 'abc@example.com',
     :interval => 120,
     :rollup_threshold => 3
    }
  }

  it "returns a single medium" do
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).
      with([medium.id]).and_return([medium])

    expect(medium).to receive(:as_json).and_return(medium_data)
    expect(Flapjack::Data::Medium).to receive(:associated_ids_for_contact).
      with([medium.id]).and_return({medium.id => contact.id})

    get "/media/#{medium.id}"
    expect(last_response).to be_ok
    expect(last_response.body).to eq({:media => [medium_data]}.to_json)
  end

  it "returns all media" do
    expect(Flapjack::Data::Medium).to receive(:all).and_return([medium])

    expect(medium).to receive(:as_json).and_return(medium_data)
    expect(Flapjack::Data::Medium).to receive(:associated_ids_for_contact).
      with([medium.id]).and_return({medium.id => contact.id})

    get "/media"
    expect(last_response).to be_ok
    expect(last_response.body).to eq({:media => [medium_data]}.to_json)
  end

  it "does not return a medium if the medium is not present" do
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).with([medium.id]).
      and_raise(Sandstorm::Errors::RecordsNotFound.new(Flapjack::Data::Medium, [medium.id]))

    get "/media/#{medium.id}"
    expect(last_response).to be_not_found
  end

  it "creates a medium for a contact" # do
  #   expect(Flapjack::Data::Semaphore).to receive(:new).
  #     with("contact_mass_update", :redis => redis, :expiry => 30).and_return(semaphore)

  #   expect(Flapjack::Data::Contact).to receive(:find_by_id).
  #     with(contact.id, :redis => redis).and_return(contact)

  #   expect(contact).to receive(:set_address_for_media).
  #     with(medium_data[:type], medium_data[:address])
  #   expect(contact).to receive(:set_interval_for_media).
  #     with(medium_data[:type], medium_data[:interval])
  #   expect(contact).to receive(:set_rollup_threshold_for_media).
  #     with(medium_data[:type], medium_data[:rollup_threshold])

  #   expect(semaphore).to receive(:release).and_return(true)

  #   post "/contacts/#{contact.id}/media", {:media => [medium_data]}.to_json, jsonapi_post_env
  #   expect(last_response.status).to eq(201)
  #   expect(last_response.body).to eq('{"media":[' +
  #     medium_data.merge(:id => "#{contact.id}_email",
  #                       :links => {:contacts => [contact.id]}).to_json + ']}')
  # end

  it "does not create a medium for a contact that's not present" # do
  #   expect(Flapjack::Data::Semaphore).to receive(:new).
  #     with("contact_mass_update", :redis => redis, :expiry => 30).and_return(semaphore)

  #   expect(Flapjack::Data::Contact).to receive(:find_by_id).
  #     with(contact.id, :redis => redis).and_return(nil)

  #   medium_data = {:type => 'email',
  #     :address => 'abc@example.com', :interval => 120, :rollup_threshold => 3}

  #   expect(semaphore).to receive(:release).and_return(true)

  #   post "/contacts/#{contact.id}/media", {:media => [medium_data]}.to_json, jsonapi_post_env
  #   expect(last_response.status).to eq(422)
  # end

  it "updates a medium" do
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).
      with([medium.id]).and_return([medium])

    expect(medium).to receive(:address=).with('12345')
    expect(medium).to receive(:save).and_return(true)

    patch "/media/#{medium.id}",
      [{:op => 'replace', :path => '/media/0/address', :value => '12345'}].to_json,
      jsonapi_patch_env
    expect(last_response.status).to eq(204)
  end

  it "updates multiple media" do
    medium_2 = double(Flapjack::Data::Medium, :id => 'uiop')
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).
      with([medium.id, medium_2.id]).and_return([medium, medium_2])

    expect(medium).to receive(:interval=).with(80)
    expect(medium).to receive(:save).and_return(true)

    expect(medium_2).to receive(:interval=).with(80)
    expect(medium_2).to receive(:save).and_return(true)

    patch "/media/#{medium.id},#{medium_2.id}",
      [{:op => 'replace', :path => '/media/0/interval', :value => 80}].to_json,
      jsonapi_patch_env
    expect(last_response.status).to eq(204)
  end

  it "does not update a medium that's not present" do
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).with([medium.id]).
      and_raise(Sandstorm::Errors::RecordsNotFound.new(Flapjack::Data::Medium, [medium.id]))

    patch "/media/#{medium.id}",
      [{:op => 'replace', :path => '/media/0/address', :value => 'xyz@example.com'}].to_json,
      jsonapi_patch_env
    expect(last_response).to be_not_found
  end

  it "deletes a medium" do
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).
      with([medium.id]).and_return([medium])

    expect(medium).to receive(:destroy)

    delete "/media/#{medium.id}"
    expect(last_response.status).to eq(204)
  end

  it "deletes multiple media" do
    medium_2 = double(Flapjack::Data::Medium, :id => 'uiop')
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).
      with([medium.id, medium_2.id]).and_return([medium, medium_2])

    expect(medium).to receive(:destroy)
    expect(medium_2).to receive(:destroy)

    delete "/media/#{medium.id},#{medium_2.id}"
    expect(last_response.status).to eq(204)
  end

  it "does not delete a medium that's not found" do
    expect(Flapjack::Data::Medium).to receive(:find_by_ids!).with([medium.id]).
      and_raise(Sandstorm::Errors::RecordsNotFound.new(Flapjack::Data::Medium, [medium.id]))

    delete "/media/#{medium.id}"
    expect(last_response).to be_not_found
  end

end