
class AosSyncQueueNull < AosSyncQueue
  def initialize(tenant, topicArn = 'topic', region = 'us-west-2')
    super(tenant, topicArn, region)
  end

  def publish(entity, data)
    true
  end
end
