class SendAnswerToCandidateJob < ApplicationJob
  queue_as :default

  def perform(candidate, answer)
    ApplicationMailer.with(candidate: candidate, answer: answer).answer_to_candidate.deliver_now
  end
end
