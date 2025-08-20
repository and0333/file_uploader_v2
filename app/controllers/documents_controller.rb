class DocumentsController < ApplicationController
  def index
    @documents = Document.order(created_at: :desc)
    @document = Document.new
  end
  #def new
  # @document = Document.new
  #end
  def create
    @document = Document.new(document_params)
    if @document.name.blank? && @document.file.attached?
      @document.name = @document.file.filename.to_s
    end
    if @document.save
      redirect_to documents_path, notice: 'Документ успешно загружен!'
    else
      redirect_to documents_path, alert: 'Ошибка загрузки файла'
    end
  end
  private
  def document_params
    params.require(:document).permit(:name, :file)
  end
end
