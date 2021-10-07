require 'aws-sdk-sns'

class AosSyncQueue
  
  def initialize(tenant, topicArn = nil, region = 'us-west-2')
    @tenant = tenant
    @region = region
    @topicArn = topicArn
  end

  def publish(entity, data, action = 'save')
    sns = Aws::SNS::Resource.new
    topic = sns.topic(@topicArn)

    paylaod = self.prepare_data(entity, data, action);
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

  def prepare_data(entity, body, action )
    url = "#{@tenant.aos_api_url}/v1/#{action}/#{entity}"
    url+= "/#{body[:appointment_id]}/#{body[:nomination_id]}" if action == "delete" and body[:appointment_id].present?
    {
      url: url,
      tenant: @tenant.name,
      data: body
    }
  end
end
