class SendProductQuestionAnswerJob < ApplicationJob
  queue_as :default

  def perform(user, question, answer)
    ApplicationMailer.with(user: user, question: question, answer: answer)
      .product_question_answer.deliver_now
  end
end
