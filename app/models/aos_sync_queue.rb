require 'aws-sdk-sns'

class AosSyncQueue
  
  def initialize(tenant, topicArn = nil, region = 'us-west-2')
    @tenant = tenant
    @region = region
    @topicArn = topicArn
  end

  def publish(entity, data)
    credentials = Aws::InstanceProfileCredentials.new(retries: 3)
    client = Aws::SNS::Client.new(
      region: @region,
      credentials: credentials
    )
    sns = Aws::SNS::Resource.new(client: client)
    topic = sns.topic(@topicArn)

    paylaod = self.prepare_data(entity, data);
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
