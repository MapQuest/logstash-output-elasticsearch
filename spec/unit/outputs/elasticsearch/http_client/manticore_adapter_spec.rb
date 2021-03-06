require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/elasticsearch/http_client"

describe LogStash::Outputs::ElasticSearch::HttpClient::ManticoreAdapter do
  let(:logger) { Cabin::Channel.get }
  let(:options) { {} }

  subject { described_class.new(logger, options) }

  it "should raise an exception if requests are issued after close" do
    subject.close
    expect { subject.perform_request(::LogStash::Util::SafeURI.new("http://localhost:9200"), :get, '/') }.to raise_error(::Manticore::ClientStoppedException)
  end

  it "should implement host unreachable exceptions" do
    expect(subject.host_unreachable_exceptions).to be_a(Array)
  end
  
  describe "auth" do
    let(:user) { "myuser" }
    let(:password) { "mypassword" }
    let(:noauth_uri) { clone = uri.uri.clone;clone.user=nil; clone.password=nil; clone.to_s }
    let(:uri) { ::LogStash::Util::SafeURI.new("http://#{user}:#{password}@localhost:9200") }
    
    it "should convert the auth to params" do
      resp = double("response")
      allow(resp).to receive(:call)
      allow(resp).to receive(:code).and_return(200)
      expect(subject.manticore).to receive(:get).
        with(noauth_uri, {
          :auth => {
            :user => user,
            :password => password,
            :eager => true
          }
        }).and_return resp
      
      subject.perform_request(uri, :get, "/")
    end
  end

  describe "integration specs", :integration => true do
    it "should perform correct tests without error" do
      resp = subject.perform_request(::LogStash::Util::SafeURI.new("http://localhost:9200"), :get, "/")
      expect(resp.code).to eql(200)
    end
  end
end
