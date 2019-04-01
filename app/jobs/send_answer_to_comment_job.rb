class SendAnswerToCommentJob < ApplicationJob
  queue_as :default

  def perform(comment, answer)
    ApplicationMailer.with(comment: comment, answer: answer).send_answer_to_comment.deliver_now
  end
end
