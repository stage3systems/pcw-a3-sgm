require 'aws-sdk-sns'

class AosSyncQueue
  
  def initialize(tenant, topicArn = nil, region = 'us-west-2')
    @tenant = tenant
    @region = region
    @topicArn = topicArn
  end

  def publish(entity, data)
    paylaod = self.prepare_data(entity, data);

    sns = Aws::SNS::Resource.new(region: @region)
    topic = sns.topic(@topicArn)
    topic.publish({
      message: paylaod.to_json,
      message_attributes: {
        "tenant" => {
          data_type: "String",
          string_value: @tenant.name
        },
      },
    })
  end

  def prepare_data(entity, body)
    {
      url: "#{@tenant.aos_api_url}/v1/save/#{entity}",
      tenant: @tenant.name,
      data: body
    }
  end
end
