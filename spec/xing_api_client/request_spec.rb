require 'spec_helper'

describe XingApiClient::Request do
  subject { XingApiClient::Request }
  let(:instance){ subject.new(consumer_token_object) }
  let(:consumer_token_object) { double('consumer_token_object') }

  describe '.new' do
    it 'sets the intsance variable access_token to the argument when it gets initialized' do
      instance.instance_variable_get('@consumer_token').should == consumer_token_object
    end
  end

  describe '#generate_url_params!' do
    it 'returns a string with url-encoded values' do
      instance.send(:generate_url_params, user_id: '1_abcdef', message: 'abcABC#./_').should == "?user_id=1_abcdef&message=abcABC%23.%2F_"
    end
  end

  describe '#add_default_values' do
    it 'returns a hash' do
      instance.send(:add_default_values, nil).should == {}
      instance.send(:add_default_values, {}).should == {}
    end

    it 'returns a hash with all keys' do
      instance.send(:add_default_values, {a: '', b: '', c: ''}).keys.should == [:a, :b, :c]
    end

    context 'offset' do
      it 'returns an integer' do
        instance.send(:add_default_values, offset: nil).should == { offset: 0 }
        instance.send(:add_default_values, offset: '5').should == { offset: 5 }
        instance.send(:add_default_values, offset: 5).should   == { offset: 5 }
      end
    end

    context 'user_fields' do
      it 'returns a string' do
        instance.send(:add_default_values, user_fields: nil).should == { user_fields: XingApiClient::Object::User::AVAILABLE_FIELDS.join(',') }
        instance.send(:add_default_values, user_fields: 'id,name').should == { user_fields: 'id,name' }
      end
    end

    context 'other values' do
      it 'returns the values untouched' do
        test_thing = stub('something')
        instance.send(:add_default_values, other: test_thing ).should == { other: test_thing }
      end
    end
  end

  describe '#make_request!' do
    let(:url){ 'www.test.com' }
    let(:params) { {param1: '1', param2: '2'} }

    context 'get requests' do
      let(:verb){ :get }

      it 'adds the params to the url' do
        consumer_token_object.should_receive(:request).with(:get, "www.test.com?param1=1&param2=2")
      end
    end

    context 'post request' do
      let(:verb){ :post }

      it 'adds the params to the body' do
        consumer_token_object.should_receive(:request).with(:post, "www.test.com", {:param1=>"1", :param2=>"2"})
      end
    end

    after{ instance.send(:handle_request, verb, url, params) }
  end

  describe '#handle_result' do

    context 'the result body is nil' do
      let(:result){ stub('result') }
      let(:content_type){}

      before{ result.should_receive(:body).and_return(nil) }

      it 'returns nil' do
        instance.send(:handle_result, result, content_type).should be_nil
      end
    end

    context 'the result body is not nil' do
      let(:result){ stub('result') }
      before{ result.stub(:body).and_return('{ "male": true }') }

      context 'the content_type is == "text"' do
        let(:content_type){ 'text' }

        it 'returns a String' do
          instance.send(:handle_result, result, content_type).should == '{ "male": true }'
        end
      end

      context 'the content_type is nil' do
        let(:content_type){ nil }

        it 'returns a Hash' do
          instance.send(:handle_result, result, content_type).should == { "male" => true }
        end
      end
    end
  end

  describe '#handle_error!' do
    context 'If there is no error, it...' do
      it 'does not raise' do
        instance.send(:handle_error!, 200, {}, 200)
      end
    end

    context 'If the error is defined, it...' do
      XingApiClient::Request::ERROR_CLASSES.each_pair do |api_error_code, error_class|
        it "raises an #{error_class}" do
          expect { instance.send(:handle_error!,'1234', {'error_name' => api_error_code}, 200) }.
            to raise_error( error_class )
        end
      end
    end

    context 'If the error is undefined, it...' do
      it "raises an XingApiClient::Request::Error" do
        expect { instance.send(:handle_error!, '1234', {'error_name' => 'RSPEC_TEST_EXCEPTION'}, 200) }.
          to raise_error( XingApiClient::Request::Error )
      end
    end
  end
end
