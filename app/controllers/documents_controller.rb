class DocumentsController < ApplicationController
  def index
    @documents = Document.order(created_at: :desc)
  end
end
