require 'spec_helper'
require 'aws_sns_publisher'

describe AwsSNSPublisher do
  before do
  end
  it '#publish' do
    stub_request(
      :any, /sns.us-east-1.amazonaws.com/
    ).to_return(
    status: 200,
    body: '')
    
    publisher = AwsSNSPublisher.new(
      "sns.us-east-1.amazonaws.com",
      access_key: "hogehoge", 
      secret_key: "hogehoge")
    lambda{publisher.publish(
      "Action" => "Publish",
      "Message" => "hogehoge",
      "Subject" => "hoge",
      "TopicArn" => "arn:aws:sns:us-east-1:853821906281:gitrecipes-github-api-remainings-useast")
    }.should_not raise_error
  end
end
