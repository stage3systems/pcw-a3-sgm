require 'new_relic/agent/method_tracer'
class ProcessDisbursementRevisionSyncJob < Struct.new(:revisionId)
  include ::NewRelic::Agent::MethodTracer

  def enqueue(job)
    stat = get_stat(job)
    stat.save!
  end

  def before(job)
    started_at = Time.now
    wait_time = started_at - job.run_at if job.run_at
    stat = get_stat(job)
    stat.run_at = job.run_at if job.run_at
    stat.hostname = Socket.gethostname
    stat.wait_time = wait_time
    stat.started_at = started_at
    stat.save!
  end
   
  def perform(*args)
    revision = DisbursementRevision.find revisionId
    revision.sync_with_aos
    ::NewRelic::Agent.add_custom_attributes({ 
        revisionId: revisionId
    })
  end

  def success(job)
    record_job_completion(job, :success)
  end

  def error(job, exception)
    record_job_completion(job, :error)
  end

  private

  def record_job_completion(job, status)
    compled_at = Time.now
    stat = get_stat(job)
    stat.status = status
    stat.execution_time = compled_at - stat.started_at 
    stat.locked_at = job.locked_at
    stat.compled_at = compled_at
    stat.last_error = job.last_error
    stat.save!
  end

  def get_stat(job)
    DelayedJobsStat.find_or_create_by({ 
      entity_name: 'DisbursementRevision', 
      entity_id: revisionId, 
      attempt: job.attempts
    })
  end

  add_method_tracer :enqueue, 'Custom/enqueue'
  add_method_tracer :before, 'Custom/before'
  add_method_tracer :perform, 'Custom/perform'
  add_method_tracer :success, 'Custom/success'
  add_method_tracer :error, 'Custom/error'
end
